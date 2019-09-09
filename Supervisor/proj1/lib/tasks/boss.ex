defmodule Boss do
  def start_link(s, e) do
    pid = spawn(__MODULE__, :init, [s, e])
    Process.monitor(pid)

    receive do
      msg -> IO.puts("#{inspect(msg)}")
    end

    {:ok, pid}
  end

  def init(arg_n, arg_k) do
    chunk_size = 1
    no_of_divisions = Kernel.floor((arg_k - arg_n) / chunk_size)

    1..(no_of_divisions + 1)
    |> Enum.map(fn i ->
      start_n = arg_n + (i - 1) * chunk_size + 1
      end_n = start_n + chunk_size

      end_n =
        if end_n > arg_k do
          arg_k
        else
          end_n
        end

      spawn(Local.Server, :set_vamp, [start_n, end_n])
    end)

    res = Local.Server.get_vamp()
    Enum.each(res, fn args -> IO.puts(args) end)
  end

  def ranger(s, e) do
    s..e
    |> Enum.map(fn each_n ->
      spawn(__MODULE__, :isVampire, [each_n])
    end)
  end

  def looper(start_n, end_n, chunk_size) when start_n + chunk_size < end_n do
    # IO.puts("Start: #{start_n} End: #{start_n + chunk_size}")

    start_n..(start_n + chunk_size)
    |> Enum.map(fn each_n ->
      # Local.Server.set_vamp(each_n)
      # IO.puts("Working on #{each_n}")
      spawn(__MODULE__, :isVampire, [each_n])
    end)

    # # Local.Server.set_vamp(100_000, 200_000)
    # res = Local.Server.get_vamp()
    # # res = Enum.filter(res, &(!is_nil(&1)))
    # Enum.each(res, fn args -> IO.puts(args) end)

    looper(start_n + chunk_size + 1, end_n, chunk_size)
  end

  def looper(start_n, end_n, chunk_size) do
    # IO.puts("Start: #{start_n} End: #{end_n}")

    start_n..end_n
    |> Enum.map(fn each_n ->
      # Local.Server.set_vamp(each_n)
      # IO.puts("Working on #{each_n}")
      spawn(__MODULE__, :isVampire, [each_n])
    end)

    # # Local.Server.set_vamp(100_000, 200_000)
    # res = Local.Server.get_vamp()
    # # res = Enum.filter(res, &(!is_nil(&1)))
    # Enum.each(res, fn args -> IO.puts(args) end)
  end

  def isVampire(n) do
    Local.Server.set_vamp(n)
  end
end
