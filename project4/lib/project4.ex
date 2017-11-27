defmodule Project4 do
  def main(args) do
        if Enum.count(args) == 2 do
            {numNodes,_} = Integer.parse(Enum.at(args,0))
            {numRequests,_} = Integer.parse(Enum.at(args,1))
            IO.inspect numRequests
            IO.inspect numNodes
        else
            IO.puts "Invalid number of arguments."
            System.halt(0)
        end



        
  end
end
