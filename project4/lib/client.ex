defmodule Client do

    def communicate(iter, numNodes, userName) do

        server = :global.whereis_name(:server)
        send(server, {:imlive, userName})
        receive do
            {:feed, feeddata} ->
                # IO.puts "The feed data is:"
                # IO.inspect feeddata
                doActivities(iter, numNodes, userName)
        end

        # Process.sleep(:infinity)
    end

    def doActivities(iter, numNodes, userName) do
        server = :global.whereis_name(:server)

        action_list = ["tweet",  "query","follow",  "retweet"] #
        # user_list = ["user1", "user2", "user3", "user4", "user5"]
        hashtag_list = ["love", "yolo", "lol", "lmao", "rofl"]
        query_list = ["hashtag", "mention"]
        tweet_type_list = [1,2,3,4]

        numbers = 1..numNodes
        wholeList = Enum.to_list(numbers)
        selectedRandomUser = Enum.random(wholeList)
        randUser = "user"<>"#{selectedRandomUser}"

        receive do
            {:liveTweet, userWhoTweeted,  tweetdata} ->
                IO.puts "New live feed from "<>"#{userWhoTweeted}"<>": "
                IO.inspect tweetdata
                doActivities(iter, numNodes, userName)
            {:queryResult, list} ->
                IO.puts "The query result is:"
                IO.inspect list
                doActivities(iter, numNodes, userName)
        after 0_200 ->
            # do random activities
            if iter < 1 do
                IO.puts "Logging off!"
                send(server, {:logoff, userName})
            else
                action_atom = Enum.random(action_list)
                cond do
                    action_atom == "tweet" ->
                        tweet_type = Enum.random(tweet_type_list)
                        tweet = randomstr(20)
                        retweetID = "NA"
                        cond do
                            tweet_type == 1 ->
                                send(server, {:tweet,userName, tweet, retweetID})
                            tweet_type == 2 ->
                                send(server,{:tweet,userName, Enum.join([tweet,' #', Enum.random(hashtag_list)]), retweetID})
                            tweet_type == 3 ->
                                send(server, {:tweet,userName, Enum.join([tweet, ' @', randUser]),retweetID})
                            tweet_type == 4 ->
                                send(server, {:tweet,userName, Enum.join([tweet,' #', Enum.random(hashtag_list), ' @',randUser]),retweetID})
                        end 
                    action_atom == "follow" ->
                        # IO.puts "follow"
                        user_to_follow = randUser
                        send(server, {:follow, user_to_follow, "user"<>"#{userName}"})
                    action_atom == "query" ->
                        query = Enum.random(query_list)
                        cond do
                            query == "hashtag" ->
                                hashtag = Enum.random(hashtag_list)
                                
                                send(server, {:query, userName, Enum.join(["#",hashtag])})
                            query == "mention" ->
                                mention = randUser
                                
                                send(server, {:query, userName, Enum.join(["@",mention])})
                        end
                        action_atom == "retweet" ->
                        send(server, {:retweet, userName})
                    
                end
                doActivities(iter - 1, numNodes, userName)
            end
        end
    
        


        
    end

    def randomstr(length \\ 15) do
      Enum.join(["tweet",:crypto.strong_rand_bytes(length) |> Base.encode32 |> binary_part(0, length) |> :string.lowercase])
    end

end

