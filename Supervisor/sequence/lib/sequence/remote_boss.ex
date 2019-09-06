defmodule Mix.Tasks.RemoteBoss do
  def start_link(start_n, end_n) do
    arg_n..arg_k
    |> Enum.map(fn each_n ->
      _pid = spawn(__MODULE__, :vamp_check, [each_n])
      # Process.monitor(pid)
      # receive do
      #   msg -> msg
      # end
    end)

    # start_n..end_n 
    # |> Task.async_stream(&Mix.Tasks.RemoteBoss.vamp_check/1, max_concurrency: System.schedulers_online, timeout: 10000, on_timeout: :kill_task) 
    # |> Enum.map(fn {:ok, _result} -> nil end)
  end

  def vamp_check(n) do
    # IO.puts "Working on #{n} in vamp_check"
    case vampire_factors(n) do
      [] ->
        nil

      vf ->
        list = Enum.map(vf, fn x -> Tuple.to_list(x) end)
        list = List.flatten(list)
        list = Enum.map(list, fn x -> Integer.to_string(x) end)
        list = Enum.join(list, " ")
        IO.puts("#{n} #{list}")
        # {:os.system_time(:millisecond)}
    end
  end

  # def work(pid, each_n, arg_k) do
  #   GenServer.call(pid, {:ash, each_n, arg_k})                              #call core logic to compute solution
  # end

  def factor_pairs(n) do
    first = trunc(n / :math.pow(10, div(char_len(n), 2)))
    last = :math.sqrt(n) |> round
    for i <- first..last, rem(n, i) == 0, do: {i, div(n, i)}
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
