defmodule Client do

    def communicate(iter, userName) do

        server = :global.whereis_name(:server)
        send(server, {:imlive, userName})
        receive do
            {:feed, feeddata} ->
                IO.inspect feeddata
                doActivities(iter, userName)
        end

        Process.sleep(:infinity)
    end

    def doActivities(iter, userName) do
        server = :global.whereis_name(:server)
        send(server, {:imlive, userName})
        receive do
            {:feed, feeddata} ->
            
        end
        
        action_list = ["tweet", "follow", "query", "retweet"]
        user_list = ["user1", "user2", "user3", "user4", "user5"]
        hashtag_list = ["mofo", "yolo", "lol", "lmao", "rofl"]
        query_list = ["hashtag", "mention"]
        tweet_type_list = [1,2,3,4]

        receive do
            {:liveTweet, userWhoTweeted,  tweetdata} ->
                IO.inspect tweetdata
                doActivities(iter, userName)
        after 0_200 ->
            # do random activities
            if iter < 1 do
                IO.puts "Iterations done!"
                iter
            else
                action_atom = Enum.random(action_list)
                cond do
                    action_atom == "tweet" ->
                        tweet_type = Enum.random(tweet_type_list)
                        tweet = randomstr(20)
                        retweetID = "NA"
                        cond do
                            tweet_type == 1 ->
                                send(server, {:tweet,userName, tweet})
                            tweet_type == 2 ->
                                send(server,{:tweet,userName, Enum.join([tweet,' #', Enum.random(hashtag_list)]), retweetID})
                            tweet_type == 3 ->
                                send(server, {:tweet,userName, Enum.join([tweet, ' @', randomstr(10)]),retweetID})
                            tweet_type == 4 ->
                                send(server, {:tweet,userName, Enum.join([tweet,' #', Enum.random(hashtag_list), ' @',randomstr(10)]),retweetID})
                        end 
                    action_atom == "follow" ->
                        user_to_follow = Enum.random(user_list)
                        user_following = userName
                        send(server, {:follow, user_to_follow, user_following})
                    action_atom == "query" ->
                        query = Enum.random(query_list)
                        cond do
                            query == "hashtag" ->
                                hashtag = Enum.random(hashtag_list)
                                send(server, {:query, Enum.join(["query #",hashtag])})
                            query == "mention" ->
                                mention = Enum.random(user_list)
                                send(server, {:query, Enum.join(["mention @",mention])})
                        end
                    action_atom == "retweet" ->
                        username = Enum.random(user_list)
                        send(server, {:retweet, Enum.join(["RT @",username," ",randomstr(20)])})
                    
                end
                doActivities(iter - 1, userName)
            end
        end
    
        


        
    end

    def randomstr(length \\ 15) do
      Enum.join(["tweet",:crypto.strong_rand_bytes(length) |> Base.encode32 |> binary_part(0, length) |> :string.lowercase])
    end

end

