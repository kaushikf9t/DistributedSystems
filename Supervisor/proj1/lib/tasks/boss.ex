defmodule Boss do
  def start_link(s, e) do
    pid = spawn(__MODULE__, :init, [s, e])
    Process.monitor(pid)

    receive do
      msg -> msg
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

end
