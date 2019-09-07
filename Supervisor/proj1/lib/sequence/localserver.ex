defmodule Local.Server do
  use GenServer

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link(start_n, end_n) do
    # get_vamp(start_n, end_n)
    prn_vamps(start_n, end_n)
    GenServer.start_link(__MODULE__, [start_n | end_n], name: __MODULE__)
  end

  def get_vamp(start_n, end_n) do
    GenServer.call(__MODULE__, {:vamper, start_n, end_n})
  end

  def handle_call({:vamper, start_n, end_n}, _from, state) do
    # [head | tail] = state
    prn_vamps(start_n, end_n)
    {:reply, state, state}
  end

  def prn_vamps(arg_n, arg_k) do
    arg_n..arg_k
    |> Enum.map(fn each_n ->
      _pid = spawn(__MODULE__, :isVampire, [each_n])
    end)
  end

  def isVampire(n) do
    case getFangs(n) do
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

  def getFangs(n) do
    if Integer.mod(char_len(n), 2) == 1 do
      []
    else
      fangLength = Kernel.trunc(length(to_charlist(n)) / 2)
      sorted = Enum.sort(String.codepoints("#{n}"))

      Enum.filter(vampireFangs(n), fn {fang1, fang2} ->
        char_len(fang1) == fangLength && char_len(fang2) == fangLength &&
          Enum.count([fang1, fang2], fn x -> Integer.mod(x, 10) == 0 end) != 2 &&
          Enum.sort(String.codepoints("#{fang1}#{fang2}")) == sorted
      end)
    end
  end

  def vampireFangs(n) do
    first = Kernel.trunc(n / :math.pow(10, Kernel.trunc(char_len(n) / 2)))
    last = :math.sqrt(n) |> round
    for i <- first..last, Integer.mod(n, i) == 0, do: {i, Kernel.trunc(n / i)}
  end

  defp char_len(n), do: length(to_charlist(n))

  def isNumberDigitsEven(n) do
    Integer.mod(String.length(Integer.to_string(n)), 2) == 0
  end
end
