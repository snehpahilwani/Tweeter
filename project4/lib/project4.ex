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
      following = []
      followers = []
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
        
        #message all followers about the tweet


      {:follow, username} ->
          IO.puts "User to follow: "<>username

      {:retweet, username} ->
          IO.puts "Retweet query of username: "<>username

      {:query, hashOrMention} ->
          IO.puts "Query hashOrMention: "<>hashOrMention

      
    end
    serve()
  end


end
