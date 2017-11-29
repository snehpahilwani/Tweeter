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

  def randomstr(length \\ 15) do
      Enum.join(["user",:crypto.strong_rand_bytes(length) |> Base.encode32 |> binary_part(0, length) |> :string.lowercase])
  end

  def genusers(num_user) do
    for _y <- 1..num_user,
    do: IO.puts randomstr(5)
  end
        

end


Project4.genusers(1000) 