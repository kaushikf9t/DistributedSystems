defmodule Mix.Tasks.RemoteBoss do

  def start_link(start_n, end_n, arg_k) do
    {:ok, pid} = Mix.Tasks.PerfectSquareComputer.start_link()
    (start_n..end_n)
    |>Enum.map(fn(each_n) -> spawn(__MODULE__, :work, [pid, each_n, arg_k]) end)
  end

  def work(pid, each_n, arg_k) do
    GenServer.call(pid, {:async_number, each_n, arg_k})
  end

end

