defmodule Server do

  def signup(userName, password) do
    insert_bool = :ets.insert_new(:user_table, {userName, password, [], [], []})
    IO.inspect insert_bool
    insert_bool
  end

  def login(userName, password) do
    user_list = :ets.lookup(:user_table, userName)
    IO.inspect user_list
    if empty? user_list do
      false
    else
      user = elem(Enum.at(:ets.lookup(:user_table, userName),0),0)
      pass = elem(Enum.at(:ets.lookup(:user_table, userName),0),1)
      if userName == user && password == pass do
        true
      else
        false
      end
    end
  end

  def tweetAPI(tweetid,userName, tweetContent,retweetID) do
    #save the tweet in the DB
    timestamp = DateTime.to_string(DateTime.utc_now)
    :ets.insert_new(:tweets_table, {tweetid, userName, tweetContent,retweetID, timestamp})
    {hashtag_list, mention_list} = parse(tweetContent)
    #putting hashtag in hashtag ETS
    IO.puts "Tweet: " 
    IO.puts tweetContent
    IO.inspect tweetid
    if length(hashtag_list) > 0 do
      Enum.each hashtag_list, fn hashtag ->
        #Insert with the hashtag
        # IO.puts "hashtag" <> hashtag
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

    if length(mention_list) > 0 do
      Enum.each mention_list, fn mention ->
      
        
        # IO.puts "mention" <> mention
        #mention_row = get("user_table", mention, 0)
        IO.puts mention
        #mention_row = Enum.at(:ets.lookup(:user_table, mention),0)
        password = get("user_table", mention, 1)
        following = get("user_table", mention, 2)
        followers = get("user_table", mention, 3)
        user_mention_list = get("user_table", mention, 4)
        # if mention_row != nil do
        #   mention_list = elem(mention_row,4)  
        # else
        #   mention_list = []
        # end
        user_mention_list = user_mention_list ++ [tweetid]
        :ets.insert(:user_table, {mention, password, following, followers, user_mention_list})
        IO.puts "Mention list: "
        IO.inspect :ets.lookup(:user_table, mention )
      end  
      IO.inspect :ets.match(:user_table, {:"$1", :"_", :"_", :"_", :"_"})
      IO.inspect :ets.match(:tweets_table, {:"$1", :"$2", :"$3", :"$4", :"$5"})

    end      
    
    #message all followers about the tweet

    # get all followrs of userName
    followersList = get("user_table", userName, 3)
    #followersList = :ets.match(:user_table, { "user"<>"#{userName}", :"_", :"_", :"$1", :"_"})
    IO.puts "Followers List and mention list: "
    IO.inspect followersList
    IO.inspect mention_list
    follow_plus_mentions =  MapSet.union(MapSet.new(followersList), MapSet.new(mention_list))
    follow_plus_mentions = MapSet.to_list(follow_plus_mentions)
    # IO.puts "The followers of "<>userName<>" are:"
    # IO.inspect followersList

    # if not empty? followersList do
    #   Enum.each Enum.at(Enum.at(followersList,0),0), fn follower -> 
    #     #IO.puts "live tweet"
    #     follower_atom = String.to_atom(follower)
    #     # if Map.has_key?(liveNodeMap, follower_atom) do
    #     #   # IO.puts "Sending to user"
    #     #   # IO.inspect follower
    #     #   fol = :global.whereis_name(String.to_atom(follower))
    #     #   if fol != :undefined do
    #     #     send(fol, {:liveTweet,"user"<>"#{userName}", tweetContent})
    #     #   end 
    #     # end
    #   end
    # end
    follow_plus_mentions
  end

  def get(tablename, key, index) do
    table = String.to_atom(tablename)
    res = :ets.lookup(table, key)
    emptylist = []
    # IO.inspect res
    if length(res) > 0 do
      elem(Enum.at(res, 0), index)
    else
      #handle empty username/password/name
      emptylist
    end
  end


  def retweet(userName, retweetID) do
    #IO.inspect retweetID
    newTweetID = :ets.info(:tweets_table)[:size] + 1
    retweetedIDRow = Enum.at(:ets.lookup(:tweets_table, retweetID),0) #nil
    #IO.inspect retweetedIDRow
    tweetContent = "RT "<>elem(retweetedIDRow,2)
    tweetAPI(newTweetID, userName, tweetContent, [])
    oldTweetContent = elem(retweetedIDRow,2)
    retweetIDUser = elem(retweetedIDRow,1)
    timestamp = elem(retweetedIDRow,4)
    retweetIDlist = elem(retweetedIDRow,3)
    retweetIDlist = retweetIDlist ++ [newTweetID]
    :ets.insert(:tweets_table, {retweetID, retweetIDUser, oldTweetContent, retweetIDlist, timestamp})
    newTweetID
  end

  def mention_tweets(mention) do
        mention_row = Enum.at(:ets.lookup(:user_table, mention),0)
        IO.puts "Mention row"
        IO.inspect mention_row
        if mention_row != nil do
          tweet_ids = elem(mention_row,4)
          queryList = []
          queryList = buildList(tweet_ids,queryList,length(tweet_ids)-1)
          IO.inspect queryList
        end
        queryList
  end

  def query(userName, hashOrMention) do
  
    first_letter = String.first(hashOrMention)
    queryList = []
    cond do
      first_letter == "@" ->
        mention = Enum.at(String.split(hashOrMention, "@"),1)
        IO.puts "Querying Mention: "<> "#{hashOrMention}"
        queryList  = mention_tweets(mention)

        # IO.puts "Query List before"
        
        
      first_letter == "#" ->
        #hashtag = String.split(hashOrMention, "#")
        IO.puts "Querying Hashtag: "<> "#{hashOrMention}"
        hashtag_row = Enum.at(:ets.lookup(:hashtags, hashOrMention),0)
        if hashtag_row != nil do
          tweet_ids = elem(hashtag_row,1)
          queryList = buildList(tweet_ids,queryList,length(tweet_ids)-1)
          IO.inspect queryList
          # Enum.each tweet_ids, fn tweet_id ->
          #   tweetContent = elem(Enum.at(:ets.lookup(:tweets_table, tweet_id),0),2)
          #   IO.puts "Tweet Content after Hashtag: "
          #   IO.inspect tweetContent
          #   queryList = queryList ++ [tweetContent]
          #   IO.inspect queryList
          # end  
        end
        # IO.puts "Query List before"
        # IO.inspect queryList
      true ->
        # IO.puts "Do nothing"
      end
      queryList
      # user_atom = String.to_atom("user"<>"#{userName}")
      # usertosend = :global.whereis_name(user_atom)
      # IO.puts "Query List After Returned: "
      # IO.inspect queryList
      # if usertosend != :undefined do
      #   send(usertosend, {:queryResult, queryList})
      # end
            
  end

  
  
  def buildList(tweet_ids, list, index) do
    if index < 0 do
      list
    else
      #tweetContent = elem(Enum.at(:ets.lookup(:tweets_table, Enum.at(tweet_ids,index)),0),2)
      tweetContent = get("tweets_table", Enum.at(tweet_ids,index), 2)
      userName = get("tweets_table", Enum.at(tweet_ids,index), 1)
      #list = list ++ [tweetContent]
      list = list ++ [%{desc: tweetContent, userName: userName}]
      buildList(tweet_ids,list,index-1)
    end

    # Enum.each tweet_ids, fn tweet_id ->
    #   tweetContent = elem(Enum.at(:ets.lookup(:tweets_table, tweet_id),0),2)
    #   IO.puts "Tweet Content after Mention: "
    #   IO.inspect tweetContent
    #   queryList = queryList ++ [tweetContent]
    # end  
  end

  def feedData(userName) do
    #followingList = :ets.match(:user_table, {"#{userName}", :"_", :"$1", :"_", :"_"})
    followingList = get("user_table", userName, 2)
    IO.inspect followingList

    #Enum.at(followingList,0)
    feedList = []
    feedList = followersFeed(followingList, [])
    IO.inspect feedList
    mention_row = Enum.at(:ets.lookup(:user_table, userName),0)
    IO.puts "Mention row"
    IO.inspect mention_row
    tweet_ids = []
    if mention_row != nil do
    
      tweet_ids = elem(mention_row,4)
    end
    follow_plus_mentions =  MapSet.union(MapSet.new(feedList), MapSet.new(tweet_ids))
    follow_plus_mentions = MapSet.to_list(follow_plus_mentions)
    resList = buildList(follow_plus_mentions, [], length(follow_plus_mentions)-1)
    resList
  end

  def followersFeed(followingList, feedList) do
    if length(followingList) > 0 do
      user = Enum.at(followingList,0)
      followingList = followingList -- [user]
      user_tweets = :ets.match(:tweets_table, {:"$1", "#{user}",:"_", :"_", :"_"}) 
      IO.puts "Get Tweets in Followers Feed method" <> " #{user}"
      IO.inspect getTweets(user_tweets, []) 
      IO.puts "User Tweets in Followers Feed method"
      IO.inspect user_tweets
      feedList = feedList ++ getTweets(user_tweets, []) 
      followersFeed(followingList, feedList)
    else
      feedList
    end
    #feedList
  end

  def getTweets(user_tweets, resList) do
    if length(user_tweets) > 0 do
      tweet = Enum.at(user_tweets,0)
      user_tweets = user_tweets -- [tweet]
      resList = resList ++ [Enum.at(tweet, 0)]
      IO.puts "ResList in GetTweets method called from followersFeed"
      IO.inspect resList
      getTweets(user_tweets, resList)
    else
      resList
    end
    #resList
  end

  def parse(tweet) do
    hashtag_list = []
    mention_list = []
    if String.contains?(tweet, "#") or String.contains?(tweet, "@") do
          words_in_tweet = String.split(tweet, " ")

          {hashtag_list, mention_list} = populatelists(length(words_in_tweet), words_in_tweet, hashtag_list, mention_list)
    end
    {hashtag_list, mention_list}
end

def populatelists(iter, list, hashtag_list, mention_list) do
    if iter < 1 do
      {hashtag_list, mention_list}
      
    else
      word = Enum.at(list, iter-1)
      
      first_letter = String.first(word)
      
      cond do
          first_letter == "#" ->
              hashtag_list = hashtag_list ++ [word]
          first_letter == "@" ->
              word = Enum.at(String.split(word, "@"),1)
              mention_list = mention_list ++ [word]
          true ->
              # IO.puts "Do nothing"
      end
    list = List.delete(list, word)
    populatelists(iter-1, list, hashtag_list, mention_list)
    end
  end

  def follow(user_to_follow, user_who_wants_to_follow) do
    # IO.puts "Follow  request received from" <> "#{user_who_wants_to_follow}" <> "to follow" <> "#{user_to_follow}"
    # IO.puts "User to follow: "<>user_to_follow
    # IO.puts "User who wants to follow: "<>user_who_wants_to_follow
    followersList_toFollow = :ets.match(:user_table, { "#{user_to_follow}", :"_", :"_", :"$1", :"_"})
    followersList_user_who_wants_to_follow = :ets.match(:user_table, { "#{user_who_wants_to_follow}", :"_", :"_", :"$1", :"_"})

    followingList_toFollow = :ets.match(:user_table, { "#{user_to_follow}", :"_", :"$1", :"_", :"_"})
    followingList_user_who_wants_to_follow = :ets.match(:user_table, { "#{user_who_wants_to_follow}", :"_", :"$1", :"_", :"_"})
 
    mentionList_toFollow = get("user_table", user_to_follow, 4)
    mentionList_user_who_wants_to_follow = get("user_table", user_who_wants_to_follow, 4)
    # mentionList_toFollow = elem(Enum.at(:ets.lookup(:user_table, "#{user_to_follow}"),0),4)
    # mentionList_user_who_wants_to_follow = elem(Enum.at(:ets.lookup(:user_table, "#{user_who_wants_to_follow}"),0),4)

    password_toFollow = get("user_table", user_to_follow, 1)
    password_user_who_wants_to_follow = get("user_table", user_who_wants_to_follow, 1)

    # password_toFollow = elem(Enum.at(:ets.lookup(:user_table, "#{user_to_follow}"),0),1)
    # password_user_who_wants_to_follow = elem(Enum.at(:ets.lookup(:user_table, "#{user_who_wants_to_follow}"),0),1)

    # IO.puts user_to_follow <> " Following list before"
    # IO.inspect followingList_toFollow
    # IO.puts user_to_follow <> " Following list after"
    if not empty? followingList_toFollow do
      final_followingList_to_follow = Enum.at(Enum.at(followingList_toFollow,0),0)
    end
    # IO.inspect final_followingList_to_follow


    #newFollowerList = Enum.at(Enum.at(followersList_toFollow,0),0)
    # IO.puts user_to_follow <> " Follower list before"
    # IO.inspect followersList_toFollow
    # IO.puts user_to_follow <> " Follower list after"
    if not empty? followersList_toFollow do
      final_followersList_to_follow =  Enum.at(Enum.at(followersList_toFollow,0),0)
      if not Enum.member?(final_followersList_to_follow, user_who_wants_to_follow) do
        final_followersList_to_follow = final_followersList_to_follow ++ [user_who_wants_to_follow]
        :ets.insert(:user_table, {"#{user_to_follow}", password_toFollow, final_followingList_to_follow, final_followersList_to_follow, mentionList_toFollow})
      end
    end
    # IO.inspect final_followersList_to_follow


    # IO.puts user_who_wants_to_follow<>" Follower list before"
    # IO.inspect followersList_user_who_wants_to_follow
    # IO.puts user_who_wants_to_follow<>" Follower list after"
    if not empty? followersList_user_who_wants_to_follow do
      final_followersList_user_who_wants_to_follow = Enum.at(Enum.at(followersList_user_who_wants_to_follow,0),0)
    end
    # IO.inspect final_followersList_user_who_wants_to_follow

    # IO.puts user_who_wants_to_follow<>" Following list before"
    # IO.inspect followingList_user_who_wants_to_follow
    # IO.puts user_who_wants_to_follow<>" Following list after"
    if not empty? followingList_user_who_wants_to_follow do
      final_followingList_user_who_wants_to_follow = Enum.at(Enum.at(followingList_user_who_wants_to_follow,0),0)
      if not Enum.member?(final_followingList_user_who_wants_to_follow, user_to_follow) do
        final_followingList_user_who_wants_to_follow = final_followingList_user_who_wants_to_follow ++ [user_to_follow]
        :ets.insert(:user_table, {"#{user_who_wants_to_follow}", password_user_who_wants_to_follow, final_followingList_user_who_wants_to_follow, final_followersList_user_who_wants_to_follow, mentionList_user_who_wants_to_follow})
      end
    end
    IO.inspect :ets.lookup(:user_table, "#{user_who_wants_to_follow}")
    IO.inspect :ets.lookup(:user_table, "#{user_to_follow}")
    # IO.inspect final_followingList_user_who_wants_to_follow
  end

  
  def empty?([]), do: true
    def empty?(list) when is_list(list) do
      false
  end

end
  #====================================================USEFUL METHODS FOR WEB APP END HERE====================================

  # def createUsers(num_user) do
  #   if num_user <= 0 do
  #     #do nothing and return
  #   else
  #     user = "user"<>"#{num_user}"
  #     pass = "password"
  #     followers = elem(Enum.at(:ets.lookup(:user_table, user),0),3)
  #     mentions = []
  #     Enum.each followers, fn follower ->
  #       follow(user, follower)
  #     end
  #     #follow(user_to_follow, user_who_wants_to_follow)
  #     #:ets.insert_new(:user_table, {user, pass, following, followers, mentions})
  #     createUsers(num_user-1)
  #   end
  # end   

#   def goLive(numNodes,numLive,passiveList,liveNodeMap) do

#     if numLive <= 0 do
#       #do nothing
#       {passiveList,liveNodeMap}
#     else
#       selectedRandomUser = Enum.random(passiveList)

#       user = "user"<>"#{selectedRandomUser}"
#       user_atom = String.to_atom(user)
#       if Map.has_key?(liveNodeMap, user_atom) do
        
#         selectedRandomUser = Enum.random(passiveList)
#         goLive(numNodes,numLive,passiveList,liveNodeMap)
#       else
#         user_atom = String.to_atom(user)
#         liveNodeMap = Map.put_new(liveNodeMap, user_atom, 1)
        
#         node_pid = spawn(Client, :communicate, [10, numNodes, selectedRandomUser])
#         user_atom = String.to_atom(user)
#         # IO.puts user_atom
#         :global.register_name(user_atom, node_pid)
#         :global.sync()
#         passiveList = passiveList -- [selectedRandomUser]
#         goLive(numNodes,numLive-1,passiveList,liveNodeMap)
#       end
#     end
#   end   



#   def serve(tweetid,numNodes,liveNodeMap,passiveList) do
#     # IO.puts "Tweet Count"
#     # IO.inspect tweetid
#     receive do
#       {:tweet, userName, tweetContent,retweetID} ->
#         IO.puts "Tweet from user: "<>"user"<>"#{userName}"
#         IO.puts tweetContent
#         tweetid = tweetid + 1
#         IO.puts "Total Tweet Count"
#         IO.inspect tweetid
#         tweetAPI(tweetid,userName, tweetContent,retweetID)
#         #message all followers about the tweet
        
#       {:logoff, user} ->
#         user_atom = String.to_atom("user"<>"#{user}")
#         IO.puts Enum.join(["Logging off: ", "user"<>"#{user}"])
#         liveNodeMap = Map.delete(liveNodeMap, user_atom)
#         passiveList = passiveList ++ [user]
#         goLive(numNodes,1,passiveList,liveNodeMap)
      

#       {:follow, user_to_follow, user_who_wants_to_follow} ->
#         follow(user_to_follow, user_who_wants_to_follow)

#       {:retweet, username} ->
#           IO.puts "Retweet by username: "<>"user"<>"#{username}"
#           numbers = 1..tweetid
#           wholeList = Enum.to_list(numbers)
#           selectedRandomTweetID = Enum.random(wholeList)
#           x = :ets.match(:tweets_table, {selectedRandomTweetID, :"_",:"$1",:"_",:"_"})
     
#           if not empty? x do
#             # IO.inspect Enum.at(Enum.at(x,0),0)
#             tweetid = tweetid + 1
#             tweetContent = Enum.at(Enum.at(x,0),0)
#             tweetAPI(tweetid,"user"<>"#{username}", tweetContent,selectedRandomTweetID)
#           end
          

#       {:query, userName, hashOrMention} ->
#           first_letter = String.first(hashOrMention)
#           queryList = []
#           cond do
#             first_letter == "@" ->
#               #mention = String.split(hashOrMention, "@")
#               IO.puts "Querying Mention: "<> "#{hashOrMention}"
#               mention_row = Enum.at(:ets.lookup(:user_table, hashOrMention),0)
#               if mention_row != nil do
#                 tweet_ids = elem(mention_row,4)
#                 queryList = buildList(tweet_ids,queryList,length(tweet_ids)-1)
                
#               end
#               # IO.puts "Query List before"
#               # IO.inspect queryList
              
#             first_letter == "#" ->
#               #hashtag = String.split(hashOrMention, "#")
#               IO.puts "Querying Hashtag: "<> "#{hashOrMention}"
#               hashtag_row = Enum.at(:ets.lookup(:hashtags, hashOrMention),0)
#               if hashtag_row != nil do
#                 tweet_ids = elem(hashtag_row,1)
#                 queryList = buildList(tweet_ids,queryList,length(tweet_ids)-1)
#                 # Enum.each tweet_ids, fn tweet_id ->
#                 #   tweetContent = elem(Enum.at(:ets.lookup(:tweets_table, tweet_id),0),2)
#                 #   IO.puts "Tweet Content after Hashtag: "
#                 #   IO.inspect tweetContent
#                 #   queryList = queryList ++ [tweetContent]
#                 #   IO.inspect queryList
#                 # end  
#               end
#               # IO.puts "Query List before"
#               # IO.inspect queryList
#             true ->
#               # IO.puts "Do nothing"
#             end
#             user_atom = String.to_atom("user"<>"#{userName}")
#             usertosend = :global.whereis_name(user_atom)
#             IO.puts "Query List After Returned: "
#             IO.inspect queryList
#             if usertosend != :undefined do
#               send(usertosend, {:queryResult, queryList})
#             end
            
#           #end
      
#       {:imlive, userName} ->
#           # IO.puts "Imlive received from" <> "#{userName}"
#           #follow_list = :ets.match(:user_lookup, {userName, userName, :"$1",:"$2"})
#           user_atom = String.to_atom("user"<>"#{userName}")
#           usertosend = :global.whereis_name(user_atom)
#           feedList = feedData(userName)
#           IO.inspect feedList
#           # IO.inspect liveNodeMap
#           # IO.inspect passiveList
#           send(usertosend, {:feed, feedList} )
#     end
#     serve(tweetid,numNodes,liveNodeMap,passiveList)
#   end




#   def getZipfDist(numClients, clientList) do
#     distList=[]
#     c=Enum.reduce(1..numClients,0,fn(x,acc)->(1/x)+acc end )
#     c=1/c
#     distList=Enum.map(1..numClients,fn(x)->:math.ceil((c*numClients)/x) end)
#     #IO.inspect distList
#     zipfMap = %{}
#     distList |> Enum.zip(clientList) 
#         |> Enum.map(fn {dist, client} -> 
#             rounded_dist =  round(dist)

#             randomUserList = Enum.take_random(List.delete(clientList,client), rounded_dist)

#             #Map.put(zipfMap, client, randomUserList)
#             :ets.insert_new(:user_table, {client, "password", [], randomUserList, []})
#         end)
#   end
# end
