defmodule Mix.Tasks.Distributed.Boss do
  def start_link(arg_n, arg_k) do
    {:ok, pid} = Mix.Tasks.PerfectSquareComputer.start_link()

    #Format of the remote machine to be connected :"alias-remote-machine@ip-address"
    #example: remote_machines = [:"spideman@10.136.49.119", :"superman@10.136.29.44"]
    remote_machines = [:"wonder@10.136.49.119"]
	  
    Node.start :"batman@10.136.19.18"
	  Node.set_cookie :niche
    
    no_machines = length(remote_machines) + 1
    
    interval = Kernel.trunc(arg_n/no_machines)
    
    
   remote_machines
   |>Enum.with_index
   |>Enum.each(fn({machine, index}) ->
      Node.connect machine
      start_n = (index * interval) + 1
      end_n = (index + 1) * interval
      distriuted_work(machine, start_n, end_n, arg_k)
      
   end)
	  
	  start_of_local = ((no_machines - 1) * interval) + 1
	  (start_of_local..arg_n)
     |> Enum.map(fn(each_n) -> spawn(__MODULE__, :work, [pid, each_n, arg_k]) end)
  end

  def work(pid, each_n, arg_k) do
    GenServer.call(pid, {:async_number, each_n, arg_k})
  end

  def distriuted_work(remote_machine, remote_start_n, remote_end_n, arg_k) do
    #IO.puts "#{remote_machine} #{remote_start_n} #{remote_end_n}"
    Node.spawn_link(remote_machine, Mix.Tasks.RemoteBoss, :start_link, [remote_start_n, remote_end_n, arg_k])
  end

end
