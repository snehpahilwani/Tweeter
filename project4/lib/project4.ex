defmodule Project4 do
  def main(args) do
        if Enum.count(args) == 2 do
            {numNodes,_} = Integer.parse(Enum.at(args,0))
            {numLive,_} = Integer.parse(Enum.at(args,1))
            
            :ets.new(:user_table, [:set, :protected, :named_table])
            createUsers(numNodes)
            # IO.inspect :ets.match(:user_table, {:"user2", :"$1", :"_",:"_"})
            IO.inspect :ets.lookup(:user_table, "user2")
            # IO.puts user

            liveNodeMap = %{}
            # start the live nodes
            :global.register_name(:server, self())
            :global.sync()

            numbers = 1..numNodes
            wholeList = Enum.to_list(numbers)
            liveNodeMap = goLive(numNodes,numLive,wholeList,liveNodeMap)

            serve()




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

    if num_user <= 0 do
      #do nothing
    else
      user = "user"<>"#{num_user}"
      pass = "password"
      following = ["user1","user2","user3","user4"]
      followers = ["user1","user2","user3","user4"]
      :ets.insert_new(:user_table, {user, pass, following, followers})
      createUsers(num_user-1)
    end
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
        node_pid = spawn(Client, :communicate, [10, selectedRandomUser])
        user_atom = String.to_atom(user)
        IO.puts user_atom
        :global.register_name(user_atom, node_pid)
        :global.sync()

        goLive(numNodes,numLive-1,wholeList -- [selectedRandomUser],liveNodeMap)
      end
    end
  end   


  def serve() do
    receive do
      {:tweet, tweet} ->
        IO.puts tweet
        tweetid = tweetid + 1
        tweetAPI(tweetid, tweetContent,retweetID)
        #message all followers about the tweet


      {:follow, username} ->
          IO.puts "User to follow: "<>username

      {:retweet, username} ->
          IO.puts "Retweet query of username: "<>username

      {:query, hashOrMention} ->
          IO.puts "Query hashOrMention: "<>hashOrMention

      {:imlive, userName} ->
          IO.puts "Imlive received from" <> userName
          follow_list = :ets.match(:user_lookup, {userName, userName, :"$1",:"$2"})
          user_atom = String.to_atom(userName)
          send(user_atom, follow_list)
    end
    serve()
    
  end

  def tweetAPI(tweetid, tweetContent,retweetID) do
    #save the tweet in the DB
    :ets.insert_new(:user_table, {tweetid, tweetContent,retweetID})
    
            #message all followers about the tweet
  end


  def parse(tweet) do
      if String.contains?(tweet, "#") or String.contains?(tweet, "@") do
            words_in_tweet = String.split(tweet, " ")
            hashtag_list = []
            mention_list = []
            {hashtag_list, mention_list} = populatelists(length(words_in_tweet), words_in_tweet, hashtag_list, mention_list)
      end
      IO.inspect hashtag_list
      IO.inspect mention_list 
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


end

