defmodule Mix.Tasks.Boss do                                                #BOSS module, creating and managing parallel processes
require Logger

  def start_link(arg_n, arg_k) do
    {:ok, pid} = Mix.Tasks.PerfectSquareComputer.start_link() 
    IO.puts "N=#{arg_n} K=#{arg_k}"                       #Start core logic module
    Logger.info "Just before spawning"
    (arg_n..arg_k)
    |> Enum.map(fn(each_n) 
    	-> 
    		GenServer.cast(pid, {:ass, each_n}) 
    	end
    	)
    res  = GenServer.call(pid, {:ash})
    IO.inspect res
    # (1..arg_n)
    # |> Enum.map(fn(each_n) -> spawn(__MODULE__, :work, [pid, each_n, arg_k]) end)    #spawn multiple process running in parallel
  end

  def work(pid, each_n, arg_k) do
    GenServer.call(pid, {:ash, each_n, arg_k})                              #call core logic to compute solution
  end

end
