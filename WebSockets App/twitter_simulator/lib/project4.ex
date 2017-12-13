defmodule Project4 do
  def main(args) do
        if Enum.count(args) == 2 do
            {numNodes,_} = Integer.parse(Enum.at(args,0))
            {numLive,_} = Integer.parse(Enum.at(args,1))

            if numLive > numNodes do
              IO.puts "Number of online users cannot be greater than total users in the system."
              IO.puts "Please provide input as ./project4 <Total no. of users> <# oflive users>"
              System.halt(0)
            end
            
            # create the required tables
            :ets.new(:user_table, [:set, :protected, :named_table])   
            :ets.new(:tweets_table, [:set, :protected, :named_table])
            :ets.new(:hashtags, [:set, :protected, :named_table])
            #:ets.new(:user_mentions, [:set, :protected, :named_table])
            userList = Enum.to_list(1..numNodes)
            newuserList = Enum.map(userList, fn(x)->Enum.join(["user",x]) end)
            IO.puts "Creating "<>"#{numNodes}"<>" Users and their followers according to Zipf distribution"
            Server.getZipfDist(length(newuserList), newuserList)
            #Start creating users for simulation
            Server.createUsers(numNodes)

            liveNodeMap = %{}
            # start the live nodes
            :global.register_name(:server, self())
            :global.sync()

            numbers = 1..numNodes
            wholeList = Enum.to_list(numbers)
            IO.puts "Finished creating "<>"#{numNodes}"<>" users in DB"
            IO.puts "Starting "<>"#{numLive}"<>" live users"
            {passiveList,liveNodeMap} = Server.goLive(numNodes,numLive,wholeList,liveNodeMap)

            # time_1 = System.system_time(:millisecond)
            Server.serve(0,numNodes,liveNodeMap,passiveList)

            Process.sleep(:infinity)


        else
            IO.puts "Invalid number of arguments."
            System.halt(0)
        end
 
  end
end