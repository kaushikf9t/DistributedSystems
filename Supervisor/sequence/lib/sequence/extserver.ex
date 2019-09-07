# ---
# Excerpted from "Programming Elixir",
# published by The Pragmatic Bookshelf.
# Copyrights apply to this code. It may not be used to create training material, 
# courses, books, articles, and the like. Contact us if you are in doubt.
# We make no guarantees that this code is fit for any purpose. 
# Visit http://www.pragmaticprogrammer.com/titles/elixir for more book information.
# ---
defmodule CallExt.Server do
  use GenServer

  def init(init_arg) do
    {:ok, init_arg}
  end

  #####
  # External API  

  def start_link(extlist) do
    # get_vamp(start_n, end_n)
    call_remote(extlist)
    GenServer.start_link(__MODULE__, extlist, name: __MODULE__)
  end

  def get_vamp(start_n, end_n) do
    GenServer.call(__MODULE__, {:vamper, start_n, end_n})
  end

  # def increment_number(delta) do
  #   GenServer.cast(__MODULE__, {:increment_number, delta})
  # end

  #####
  # GenServer implementation

  def handle_call({:vamper, start_n, end_n}, _from, state) do
    # [head | tail] = state
    prn_vamps(start_n, end_n)
    {:reply, state, state}
  end

  def call_remote(list) do
    #IO.puts("#########################################")
    IO.inspect(list)
    {:ok, pid} = Node.start(:"sukhmeet@192.168.0.208")
    #IO.puts("Node started: #{inspect(pid)}")
    setkya = Node.set_cookie(:choco_chip)
    #IO.puts("Set kya: #{inspect(setkya)}")

    Enum.each(list, fn mtuple ->
      #IO.puts("machine: #{inspect(elem(mtuple, 0))}")
      conkya = Node.connect(elem(mtuple, 0))
      #IO.puts("Connected to #{inspect(conkya)}")

      # spawn_task(Mix.Tasks.RemoteBoss, :start_link, elem(mtuple, 0), [
      #   elem(mtuple, 1),
      #   elem(mtuple, 2),
      #   self()
      # ])

      Node.spawn_link(elem(mtuple, 0), Mix.Tasks.RemoteBoss, :start_link, [
        elem(mtuple, 1),
        elem(mtuple, 2)
      ])
    end)
  end

  def spawn_task(module, fun, recipient, args) do
    recipient
    |> remote_supervisor()
    |> Task.Supervisor.async(module, fun, args)
    |> Task.await()
  end

  defp remote_supervisor(recipient) do
    {Vamp.TaskSupervisor, recipient}
  end

  def receive_message(message) do
    IO.puts(message)
  end

  def prn_vamps(arg_n, arg_k) do
    arg_n..arg_k
    |> Enum.map(fn each_n ->
      _pid = spawn(__MODULE__, :isVampire, [each_n])
      # Process.monitor(pid)
      # receive do
      #   msg -> msg
      # end
    end)

    # arg_n..arg_k 
    # |> Task.async_stream(&Mix.Tasks.Boss.vamp_check/1, max_concurrency: System.schedulers_online) 
    # |> Enum.map(fn {:ok, _result} -> nil end)

    # IO.puts ""
    # (1..arg_n)
    # |> Enum.map(fn(each_n) -> spawn(__MODULE__, :work, [pid, each_n, arg_k]) end)    #spawn multiple process running in parallel
  end
end
