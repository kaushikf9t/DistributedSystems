defmodule Mix.Tasks.Boss1 do                                                #BOSS module, creating and managing parallel processes
require Logger

  def start_link(arg_n, arg_k) do
    # {:ok, pid} = Mix.Tasks.PerfectSquareComputer.start_link()
    IO.puts "N=#{arg_n} K=#{arg_k}"                       #Start core logic module
    Logger.info "Just before spawning"

    # (arg_n..arg_k)
    # |> Enum.map(fn(each_n)
    # 	->
    # 		GenServer.cast(pid, {:check_vamp, each_n})
    # 	end
    # 	)
    #   res  = GenServer.call(pid, {:ash},5000)
    #   IO.inspect res
    # al = Process.alive?(pid)
    # IO.puts "alive: #{al}"



    # res  = GenServer.call(pid, {:ash},50000)
    # IO.inspect res
    # res = vampire_factors(125460)
    # IO.inspect res
    (arg_n..arg_k)
    |> Enum.map(fn(each_n) ->
      pid = spawn(__MODULE__, :vamp_check, [each_n])
      Process.monitor(pid)
      receive do
        msg -> msg
      end
    end)


    # (1..arg_n)
    # |> Enum.map(fn(each_n) -> spawn(__MODULE__, :work, [pid, each_n, arg_k]) end)    #spawn multiple process running in parallel
  end

  def vamp_check(n) do
    # IO.puts "Working on #{n} in vamp_check"
    case vampire_factors(n) do
        [] -> nil
        vf ->
        list = Enum.map(vf, fn x-> Tuple.to_list(x)end)
        list = List.flatten(list)
        list = Enum.map(list, fn x-> Integer.to_string(x)end)
        list = Enum.join(list, " ")
        IO.puts "#{n} #{list} <"
      end
  end

  def work(pid, each_n, arg_k) do
    GenServer.call(pid, {:ash, each_n, arg_k})                              #call core logic to compute solution
  end

  def factor_pairs(n) do
    first = Kernel.trunc(n / :math.pow(10, Kernel.trunc(char_len(n)/2)))
    last  = :math.sqrt(n) |> round
    for i <- first .. last, Integer.mod(n, i) == 0, do: {i, div(n, i)}
  end

  def vampire_factors(n) do
    if !isNumberDigitsEven(n) do
      []
    else
      mid =  Kernel.trunc(String.length(Integer.to_string(n))/2)
      #div(length(to_charlist(n)), 2)
      sorted = Enum.sort(String.codepoints("#{n}"))
      Enum.filter(factor_pairs(n), fn {a, b} ->
        char_len(a) == mid && char_len(b) == mid &&
        Enum.count([a, b], fn x -> Integer.mod(x, 10) == 0 end) != 2 &&
        Enum.sort(String.codepoints("#{a}#{b}")) == sorted
      end)
    end
  end

  defp char_len(n), do: length(to_charlist(n))


  #OLD METHOD USING PERMUTATIONS
  def isNumberDigitsEven(n) do
    Integer.mod(String.length(Integer.to_string(n)), 2) == 0
  end

  def permutations([]), do: [[]]
  def permutations(list), do: for elem <- list, rest <- permutations(list--[elem]), do: [elem|rest]

  def getPerms(n_str) do
    Enum.map(permutations(String.to_charlist(n_str)),  fn(x) -> to_string(x) end)

  end

  def getSplitStrings(n_str) do
    # IO.puts "in split strings"
    Enum.map(getPerms(n_str), fn(x) -> String.split_at(x, Kernel.trunc(String.length(x)/2)) end)
  end

  def getFangs(n_str) do
    IO.puts "Working on #{n_str}"

    isEven = Integer.mod(String.length(Integer.to_string(n_str)), 2) == 0
    IO.puts isEven
    if isEven do
      # IO.puts "Number is even length"
      res = Enum.filter(getSplitStrings(Integer.to_string(n_str)),
                  fn(x) -> (String.to_integer(elem(x, 0)) * String.to_integer(elem(x,1)) == n_str) end)
      IO.inspect res
    end
  end

end
