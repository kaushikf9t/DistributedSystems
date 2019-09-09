defmodule Local.Server do
  use GenServer

  def init(init_arg) do
    {:ok, init_arg}
  end

  def start_link() do
    # get_vamp(start_n, end_n)
    # prn_vamps(start_n, end_n)
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def set_vamp(s, e) do
    # IO.inspect(:os.timestamp())
    # IO.puts("s: #{s} e:#{e}")
    GenServer.cast(__MODULE__, {:vampercast, s, e - 1})
  end

  def get_vamp do
    GenServer.call(__MODULE__, {:vampercall}, :infinity)
  end

  def handle_call({:vampercall}, _from, state) do
    # empT = []
    {:reply, state, state}
  end

  def handle_cast({:vampercast, s, e}, state) do
    toadd =
      s..e
      |> Enum.map(fn each_n ->
        case getFangs(each_n) do
          [] ->
            # {:noreply, state}
            nil

          vf ->
            list = Enum.map(vf, fn x -> Tuple.to_list(x) end)
            list = List.flatten(list)
            list = Enum.map(list, fn x -> Integer.to_string(x) end)
            list = Enum.join(list, " ")
            # IO.puts("#{n} #{list}")
            # {:noreply, state ++ ["#{n} #{list}"]}
            "#{each_n} #{list}"

            # {:os.system_time(:millisecond)}
        end
      end)
      |> Enum.filter(fn arg -> !is_nil(arg) end)

    {:noreply, state ++ toadd}
  end

  def handle_cast({:vampercast, n}, state) do
    # IO.puts("Inside handle_cast")

    t =
      case getFangs(n) do
        [] ->
          # {:noreply, state}
          nil

        vf ->
          list = Enum.map(vf, fn x -> Tuple.to_list(x) end)
          list = List.flatten(list)
          list = Enum.map(list, fn x -> Integer.to_string(x) end)
          list = Enum.join(list, " ")
          # IO.puts("#{n} #{list}")
          # {:noreply, state ++ ["#{n} #{list}"]}
          "#{n} #{list}"

          # {:os.system_time(:millisecond)}
      end

    lis =
      if !is_nil(t) do
        [t]
      else
        []
      end

    # IO.puts("$$$$$ #{inspect(tosend)}")

    # {:noreply, state}
    {:noreply, state ++ lis}
  end

  def prn_vamps(arg_n, arg_k) do
    arg_n..arg_k
    |> Enum.map(fn each_n ->
      _pid = spawn(__MODULE__, :isVampire, [each_n])
    end)
  end

  # def handle_cast({:vamp_set_state, t}, state) do
  #   {:noreply, state ++ t}
  # end

  def isVampire(n) do
    t =
      case getFangs(n) do
        [] ->
          nil

        vf ->
          list = Enum.map(vf, fn x -> Tuple.to_list(x) end)
          list = List.flatten(list)
          list = Enum.map(list, fn x -> Integer.to_string(x) end)
          list = Enum.join(list, " ")
          # IO.puts("#{n} #{list}")
          "#{n} #{list}"
          # {:os.system_time(:millisecond)}
      end

    if !is_nil(t) do
      GenServer.cast(__MODULE__, {:vamp_set_state, [t]})
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
