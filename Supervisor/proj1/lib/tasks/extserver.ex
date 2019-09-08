defmodule CallExt.Server do
  use GenServer

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link(extlist) do
    call_remote(extlist)
    GenServer.start_link(__MODULE__, extlist, name: __MODULE__)
  end

  def get_vamp(start_n, end_n) do
    GenServer.call(__MODULE__, {:vamper, start_n, end_n})
  end

  def handle_call({:vamper, _start_n, _end_n}, _from, state) do
    {:reply, state, state}
  end

  def call_remote(list) do
    # {:ok, pid} = Node.start(:"sukhmeet@192.168.0.208")
    Node.start(:"sukhmeet@192.168.0.208")
    # IO.puts("Node started: #{inspect(pid)}")
    Node.set_cookie(:choco_chip)
    # IO.puts("Set kya: #{inspect(setkya)}")

    Enum.each(list, fn mtuple ->
      Node.connect(elem(mtuple, 0))

      Node.spawn_link(elem(mtuple, 0), Mix.Tasks.RemoteBoss, :start_link, [
        elem(mtuple, 1),
        elem(mtuple, 2)
      ])
    end)
  end
end
