defmodule Mix.Tasks.Distributed.Boss do
  def start_link(arg_n, arg_k) do
    # {:ok, pid} = Mix.Tasks.PerfectSquareComputer.start_link()

    #Format of the remote machine to be connected :"alias-remote-machine@ip-address"
    #example: remote_machines = [:"spideman@10.136.49.119", :"superman@10.136.29.44"]
    
    remote_machines = [:"one@192.168.0.76"]
	  
    Node.start :"sukhmeet@192.168.0.208"
	  Node.set_cookie :choco_chip
    
    no_machines = length(remote_machines) + 1
    
    interval = Kernel.trunc((arg_k-arg_n)/no_machines)
    
    pid = 0
   remote_machines
   |>Enum.with_index
   |>Enum.each(fn({machine, index}) ->
      Node.connect machine
      start_n = arg_n + (index * interval) 
      end_n = start_n + (index + 1) * interval
      distriuted_work(machine, start_n, end_n, arg_k)
   end)
	  
	  start_of_local = arg_k - ((no_machines - 1) * interval) + 1
    

	  # (start_of_local..arg_n)
   #   |> Enum.map(fn(each_n) -> spawn(__MODULE__, :work, [pid, each_n, arg_k]) end)

     start_of_local..arg_k 
    |> Task.async_stream(&Mix.Tasks.Distributed.Boss.vamp_check/1, max_concurrency: System.schedulers_online) 
    |> Enum.map(fn {:ok, _result} -> nil end)
    
  end

  # def work(pid, each_n, arg_k) do
  #   GenServer.call(pid, {:async_number, each_n, arg_k})
  # end

  def distriuted_work(remote_machine, remote_start_n, remote_end_n, arg_k) do
    #IO.puts "#{remote_machine} #{remote_start_n} #{remote_end_n}"
    IO.puts "Sending range to #{remote_machine} from #{remote_start_n} to #{remote_end_n}"
    Node.spawn_link(remote_machine, Mix.Tasks.RemoteBoss, :start_link, [remote_start_n, remote_end_n, arg_k])
  end

  def vamp_check(n) do
    # IO.puts "Working on #{n} in vamp_check"
    case vampire_factors(n) do
        [] -> nil
        vf -> 
          list = Enum.map(vf, fn x-> Tuple.to_list(x)end)
          list = List.flatten(list)
          list = Enum.map(list, fn x-> Integer.to_string(x)end)
          list = Enum.join(list, " ")
          IO.puts "#{n} #{list} loc"
          #{:os.system_time(:millisecond)}
      end
  end

  # def work(pid, each_n, arg_k) do
  #   GenServer.call(pid, {:ash, each_n, arg_k})                              #call core logic to compute solution
  # end

  def factor_pairs(n) do
    first = trunc(n / :math.pow(10, div(char_len(n), 2)))
    last  = :math.sqrt(n) |> round
    for i <- first .. last, rem(n, i) == 0, do: {i, div(n, i)}
  end
 
  def vampire_factors(n) do
    if rem(char_len(n), 2) == 1 do
      []
    else
      half = div(length(to_charlist(n)), 2)
      sorted = Enum.sort(String.codepoints("#{n}"))
      Enum.filter(factor_pairs(n), fn {a, b} ->
        char_len(a) == half && char_len(b) == half &&
        Enum.count([a, b], fn x -> rem(x, 10) == 0 end) != 2 &&
        Enum.sort(String.codepoints("#{a}#{b}")) == sorted
      end)
    end
  end
 
  defp char_len(n), do: length(to_charlist(n))

  def isNumberDigitsEven(n) do
    Integer.mod(String.length(Integer.to_string(n)), 2) == 0
  end

end
