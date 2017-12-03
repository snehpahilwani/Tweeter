defmodule Project4 do
  def main(args) do
        if Enum.count(args) == 2 do
            {numNodes,_} = Integer.parse(Enum.at(args,0))
            {numLive,_} = Integer.parse(Enum.at(args,1))
            
            # create the required tables
            :ets.new(:user_table, [:set, :protected, :named_table])   
            :ets.new(:tweets_table, [:set, :protected, :named_table])
            :ets.new(:hashtags, [:set, :protected, :named_table])
            #:ets.new(:user_mentions, [:set, :protected, :named_table])
            userList = Enum.to_list(1..numNodes)
            newuserList = Enum.map(userList, fn(x)->Enum.join(["user",x]) end)
            getZipfDist(length(newuserList), newuserList)
            IO.puts "User table values check"
            IO.inspect :ets.lookup(:user_table, "user1")
            IO.inspect :ets.lookup(:user_table, "user2")
            IO.inspect :ets.lookup(:user_table, "user3")
            IO.inspect :ets.lookup(:user_table, "user4")
            IO.inspect :ets.lookup(:user_table, "user5")
            #Start creating users for simulation
            createUsers(numNodes)
            # IO.inspect :ets.match(:user_table, {:"user2", :"$1", :"_",:"_"})
            #IO.inspect :ets.lookup(:user_table, "user2")
            # IO.puts user

            liveNodeMap = %{}
            # start the live nodes
            :global.register_name(:server, self())
            :global.sync()

            numbers = 1..numNodes
            wholeList = Enum.to_list(numbers)
            liveNodeMap = goLive(numNodes,numLive,wholeList,liveNodeMap)

            serve(0,liveNodeMap)
        else
            IO.puts "Invalid number of arguments."
            System.halt(0)
        end
 
  end

  # def randomstr(length \\ 15) do
  #     Enum.join(["user",:crypto.strong_rand_bytes(length) |> Base.encode64 |> binary_part(0, length)])
  # user = Enum.join(["user",:crypto.strong_rand_bytes(5) |> Base.encode64 |> binary_part(0, 5)])
  #     Enum.join(["user",:crypto.strong_rand_bytes(length) |> Base.encode32 |> binary_part(0, length) |> :string.lowercase])
  # end

  def createUsers(num_user) do
    IO.puts "Getting into createUsers method"
    if num_user <= 0 do
      #do nothing
    else
      user = "user"<>"#{num_user}"
      pass = "password"
      # following = ["user1","user2","user3","user4"]
      # followers = ["user1","user2","user3","user4"] 
      followers = elem(Enum.at(:ets.lookup(:user_table, user),0),3)
      mentions = []
      Enum.each followers, fn follower ->
        follow(user, follower)
      end
      IO.puts "Came out of loop"
      IO.inspect :ets.lookup(:user_table, user)
      #follow(user_to_follow, user_who_wants_to_follow)
      #:ets.insert_new(:user_table, {user, pass, following, followers, mentions})
      createUsers(num_user-1)
    end
    IO.puts "User table for" <> "#{user}"
    IO.inspect :ets.lookup(:user_table, user)
  end   

  def goLive(numNodes,numLive,wholeList,liveNodeMap) do

    if numLive <= 0 do
      #do nothing
      liveNodeMap
    else
      selectedRandomUser = Enum.random(wholeList)

      user = "user"<>"#{selectedRandomUser}"
      if Map.has_key?(liveNodeMap, user) do
        selectedRandomUser = Enum.random(wholeList)
        goLive(numNodes,numLive,wholeList,liveNodeMap)
      else
        Map.put_new(liveNodeMap, user, 1)
        node_pid = spawn(Client, :communicate, [10, numNodes, selectedRandomUser])
        user_atom = String.to_atom(user)
        IO.puts user_atom
        :global.register_name(user_atom, node_pid)
        :global.sync()

        goLive(numNodes,numLive-1,wholeList -- [selectedRandomUser],liveNodeMap)
      end
    end
  end   


  def empty?([]), do: true
    def empty?(list) when is_list(list) do
      false
  end

  def serve(tweetid,liveNodeMap) do
    receive do
      {:tweet, userName, tweetContent,retweetID} ->
        IO.puts tweetContent
        tweetid = tweetid + 1
        tweetAPI(tweetid,userName, tweetContent,retweetID,liveNodeMap)
        #message all followers about the tweet
        
      {:logoff, numNodes, userName} ->
        userName = Enum.join(["user", userName])
        IO.puts Enum.join(["Logging off: ", userName])
        liveNodeMap = Map.delete(liveNodeMap, userName)
        numbers = 1..numNodes
        wholeList = Enum.to_list(numbers)
        goLive(numNodes,1,wholeList,liveNodeMap)
      

      {:follow, user_to_follow, user_who_wants_to_follow} ->
        follow(user_to_follow, user_who_wants_to_follow)

      {:retweet, username} ->
          IO.puts "Retweet query of username: "<>"#{username}"
          numbers = 1..tweetid
          wholeList = Enum.to_list(numbers)
          selectedRandomTweetID = Enum.random(wholeList)
          x = :ets.match(:tweets_table, {selectedRandomTweetID, :"_",:"$1",:"_",:"_"})
          
          # IO.puts "Random tweet row: "
          # IO.inspect x
          if not empty? x do
            IO.inspect Enum.at(Enum.at(x,0),0)
            tweetid = tweetid + 1
            tweetContent = Enum.at(Enum.at(x,0),0)
            tweetAPI(tweetid,"user"<>"#{username}", tweetContent,selectedRandomTweetID,liveNodeMap)
          end
          

      {:query, userName, hashOrMention} ->
          first_letter = String.first(hashOrMention)
          queryList = []
          cond do
            first_letter == "@" ->
              #mention = String.split(hashOrMention, "@")
              IO.puts "Querying Mention: "<> "#{hashOrMention}"
              mention_row = Enum.at(:ets.lookup(:user_table, hashOrMention),0)
              if mention_row != nil do
                tweet_ids = elem(mention_row,4)
                Enum.each tweet_ids, fn tweet_id ->
                  tweetContent = elem(Enum.at(:ets.lookup(:tweets_table, tweet_id),0),2)
                  IO.puts "Tweet Content after Mention: "
                  IO.inspect tweetContent
                  queryList = queryList ++ [tweetContent]
                  IO.puts "Query List after Mention: "
                  IO.inspect queryList
                end  
              end
              # IO.puts "Query List before"
              # IO.inspect queryList
              
            first_letter == "#" ->
              #hashtag = String.split(hashOrMention, "#")
              IO.puts "Querying Hashtag: "<> "#{hashOrMention}"
              hashtag_row = Enum.at(:ets.lookup(:hashtags, hashOrMention),0)
              if hashtag_row != nil do
                tweet_ids = elem(hashtag_row,1)
                Enum.each tweet_ids, fn tweet_id ->
                  tweetContent = elem(Enum.at(:ets.lookup(:tweets_table, tweet_id),0),2)
                  IO.puts "Tweet Content after Hashtag: "
                  IO.inspect tweetContent
                  queryList = queryList ++ [tweetContent]
                  IO.puts "Query List after Hashtag: "
                  IO.inspect queryList
                end  
              end
              # IO.puts "Query List before"
              # IO.inspect queryList
            true ->
              IO.puts "Do nothing"
            end
            user_atom = String.to_atom("user"<>"#{userName}")
            usertosend = :global.whereis_name(user_atom)
            IO.puts "Query List After Returned: "
            IO.inspect queryList
            send(usertosend, {:feed, queryList})
          #end
      
      {:imlive, userName} ->
          IO.puts "Imlive received from" <> "#{userName}"
          #follow_list = :ets.match(:user_lookup, {userName, userName, :"$1",:"$2"})
          user_atom = String.to_atom("user"<>"#{userName}")
          usertosend = :global.whereis_name(user_atom)
          feedList = feedData(userName)
          IO.inspect feedList
          send(usertosend, {:feed, feedList} )
    end
    serve(tweetid,liveNodeMap)
  end

  def empty?([]), do: true
  def empty?(list) when is_list(list) do
    false
  end

  def tweetAPI(tweetid,userName, tweetContent,retweetID,liveNodeMap) do
    #save the tweet in the DB
    timestamp = :os.system_time
    :ets.insert_new(:tweets_table, {tweetid, userName, tweetContent,retweetID, timestamp})
    {hashtag_list, mention_list} = parse(tweetContent)
    #putting hashtag in hashtag ETS
    IO.puts "Tweet ID: "
    IO.puts tweetContent
    IO.inspect tweetid
    if hashtag_list != nil do
      Enum.each hashtag_list, fn hashtag ->
        #Insert with the hashtag
        IO.puts "hashtag" <> hashtag
        tweet_list = :ets.match(:hashtags, {hashtag, :"$1"})
        if not empty? tweet_list do
            final_tweet_list = Enum.at(Enum.at(tweet_list,0),0)
        else
            final_tweet_list = []
        end
        final_tweet_list = final_tweet_list ++ [tweetid]
        :ets.insert(:hashtags, {hashtag, final_tweet_list})
        IO.puts "hashtag list: "
        IO.inspect :ets.lookup(:hashtags, hashtag )
      end
      
    end

    if mention_list != nil do
      Enum.each mention_list, fn mention ->
      
        mention = Enum.at(String.split(mention, "@"),1)
        IO.puts "mention" <> mention
        mention_row = Enum.at(:ets.lookup(:user_table, mention),0)
        following = elem(mention_row,2)
        followers = elem(mention_row,3)
        if mention_row != nil do
          mention_list = elem(mention_row,4)  
        else
          mention_list = []
        end
        mention_list = mention_list ++ [tweetid]
        :ets.insert(:user_table, {mention, "password", following, followers, mention_list})
        IO.inspect :ets.lookup(:user_table, mention )
      end  
    end      
    
    #message all followers about the tweet

    # get all followrs of userName
    followersList = :ets.match(:user_table, { "user"<>"#{userName}", :"_", :"_", :"$1", :"_"})
    # IO.puts "The followers of "<>userName<>" are:"
    # IO.inspect followersList

    if not empty? followersList do
      Enum.each Enum.at(Enum.at(followersList,0),0), fn follower -> 
        # IO.inspect follower
        #check if follower is live. If live send live tweet.
        if Map.has_key?(liveNodeMap, follower) do
          fol = :global.whereis_name(String.to_atom(follower))
          send(fol, {:liveTweet,fol, tweetContent})
        end
      end
    end
  end

    def feedData(userName) do
      followingList = :ets.match(:user_table, { "user"<>"#{userName}", :"_", :"$1", :"_", :"_"})
      IO.inspect followingList

      #Enum.at(followingList,0)
      feedList = []
      Enum.each Enum.at(Enum.at(followingList,0),0), fn following -> 
          feedList = feedList ++ :ets.match(:tweets_table, {:"$1", "user"<>"#{following}",:"$2", :"_", :"$3"})  
      end
      feedList
  end


  def parse(tweet) do
    if String.contains?(tweet, "#") or String.contains?(tweet, "@") do
          words_in_tweet = String.split(tweet, " ")
          hashtag_list = []
          mention_list = []
          {hashtag_list, mention_list} = populatelists(length(words_in_tweet), words_in_tweet, hashtag_list, mention_list)
    end
    {hashtag_list, mention_list}
end

def populatelists(iter, list, hashtag_list, mention_list) do
    if iter < 1 do
      IO.puts "Work done"
      {hashtag_list, mention_list}
      
    else
      word = Enum.at(list, iter-1)
      
      first_letter = String.first(word)
      
      cond do
          first_letter == "#" ->
              hashtag_list = hashtag_list ++ [word]
          first_letter == "@" ->
              mention_list = mention_list ++ [word]
          true ->
              IO.puts "Do nothing"
      end
    list = List.delete(list, word)
    populatelists(iter-1, list, hashtag_list, mention_list)
    end
  end

  def getZipfDist(numClients, clientList) do
    distList=[]
    c=Enum.reduce(1..numClients,0,fn(x,acc)->(1/x)+acc end )
    c=1/c
    distList=Enum.map(1..numClients,fn(x)->:math.ceil((c*numClients)/x) end)
    #IO.inspect distList
    zipfMap = %{}
    distList |> Enum.zip(clientList) 
        |> Enum.map(fn {dist, client} -> 
            rounded_dist =  round(dist)

            randomUserList = Enum.take_random(List.delete(clientList,client), rounded_dist)

            #Map.put(zipfMap, client, randomUserList)
            :ets.insert_new(:user_table, {client, "password", [], randomUserList, []})
        end)
  end


  def follow(user_to_follow, user_who_wants_to_follow) do
          IO.puts "Follow  request received from" <> "#{user_who_wants_to_follow}" <> "to follow" <> "#{user_to_follow}"
          IO.puts "User to follow: "<>user_to_follow
          IO.puts "User who wants to follow: "<>user_who_wants_to_follow
          followersList_toFollow = :ets.match(:user_table, { "#{user_to_follow}", :"_", :"_", :"$1", :"_"})
          followersList_user_who_wants_to_follow = :ets.match(:user_table, { "#{user_who_wants_to_follow}", :"_", :"_", :"$1", :"_"})

          followingList_toFollow = :ets.match(:user_table, { "#{user_to_follow}", :"_", :"$1", :"_", :"_"})
          followingList_user_who_wants_to_follow = :ets.match(:user_table, { "#{user_who_wants_to_follow}", :"_", :"$1", :"_", :"_"})

          # mentionList_toFollow = :ets.match(:user_table, { "#{user_to_follow}", :"_", :"_", :"_", :"$1"})
          # mentionList_user_who_wants_to_follow = :ets.match(:user_table, { "#{user_who_wants_to_follow}", :"_", :"_", :"_", :"$1"})   
          mentionList_toFollow = elem(Enum.at(:ets.lookup(:user_table, "#{user_to_follow}"),0),4)
          mentionList_user_who_wants_to_follow = elem(Enum.at(:ets.lookup(:user_table, "#{user_who_wants_to_follow}"),0),4)

          IO.puts user_to_follow <> " Following list before"
          IO.inspect followingList_toFollow
          IO.puts user_to_follow <> " Following list after"
          if not empty? followingList_toFollow do
            final_followingList_to_follow = Enum.at(Enum.at(followingList_toFollow,0),0)
          end
          IO.inspect final_followingList_to_follow


          # newFollowerList = Enum.at(Enum.at(followersList_toFollow,0),0)
          IO.puts user_to_follow <> " Follower list before"
          IO.inspect followersList_toFollow
          IO.puts user_to_follow <> " Follower list after"
          if not empty? followersList_toFollow do
            final_followersList_to_follow =  Enum.at(Enum.at(followersList_toFollow,0),0)
            if not Enum.member?(final_followersList_to_follow, user_who_wants_to_follow) do
              final_followersList_to_follow = final_followersList_to_follow ++ [user_who_wants_to_follow]
              :ets.insert(:user_table, {"#{user_to_follow}", "password", final_followingList_to_follow, final_followersList_to_follow, mentionList_toFollow})
            end
          end
          IO.inspect final_followersList_to_follow


          IO.puts user_who_wants_to_follow<>" Follower list before"
          IO.inspect followersList_user_who_wants_to_follow
          IO.puts user_who_wants_to_follow<>" Follower list after"
          if not empty? followersList_user_who_wants_to_follow do
            final_followersList_user_who_wants_to_follow = Enum.at(Enum.at(followersList_user_who_wants_to_follow,0),0)
          end
          IO.inspect final_followersList_user_who_wants_to_follow

          IO.puts user_who_wants_to_follow<>" Following list before"
          IO.inspect followingList_user_who_wants_to_follow
          IO.puts user_who_wants_to_follow<>" Following list after"
          if not empty? followingList_user_who_wants_to_follow do
            final_followingList_user_who_wants_to_follow = Enum.at(Enum.at(followingList_user_who_wants_to_follow,0),0)
            if not Enum.member?(final_followingList_user_who_wants_to_follow, user_to_follow) do
              final_followingList_user_who_wants_to_follow = final_followingList_user_who_wants_to_follow ++ [user_to_follow]
              :ets.insert(:user_table, {"#{user_who_wants_to_follow}", "password", final_followingList_user_who_wants_to_follow, final_followersList_user_who_wants_to_follow, mentionList_user_who_wants_to_follow})
            end
          end
          IO.inspect final_followingList_user_who_wants_to_follow

          # if not empty? mentionList_user_who_wants_to_follow do
          #   final_mentionList_user_who_wants_to_follow = Enum.at(Enum.at(mentionList_user_who_wants_to_follow,0),0)
          
          # end

          # if not empty? mentionList_toFollow do
          #   final_mentionList_toFollow = Enum.at(Enum.at(mentionList_toFollow,0),0)
          # end

          
          

  end
end
