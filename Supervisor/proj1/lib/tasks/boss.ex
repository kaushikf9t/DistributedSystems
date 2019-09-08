defmodule Boss do
  def start_link do
    pid = spawn(__MODULE__, :init, [])
    Process.monitor(pid)

    receive do
      msg -> IO.puts("#{inspect(msg)}")
    end

    {:ok, pid}
  end

  def init do
    IO.puts("Init")

    100_00000..200_00000
    |> Enum.map(fn each_n ->
      # Local.Server.set_vamp(each_n)
      # IO.puts("Working on #{each_n}")
      spawn(__MODULE__, :isVampire, [each_n])
    end)

    # Local.Server.set_vamp(100_000, 200_000)
    res = Local.Server.get_vamp()
    # res = Enum.filter(res, &(!is_nil(&1)))
    Enum.each(res, fn args -> IO.puts(args) end)
    # IO.puts(">>>> #{inspect(res)}")
  end

  def isVampire(n) do
    # IO.puts("Working on #{n}")
    Local.Server.set_vamp(n)
  end
end
