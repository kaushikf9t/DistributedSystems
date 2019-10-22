defmodule Mix.Tasks.PerfectSquareComputer do                                  #Core logic computer module
  require Logger
  use GenServer

 def start_link() do
  GenServer.start_link(__MODULE__, [])
  # GenServer.start_link(__MODULE__, [], [debug: [:trace]])
  # GenServer.start_link(__MODULE__, [], name: __MODULE__)
 end

 def init(each_num) do
    {:ok, each_num}
  end

  def handle_call({:ash}, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:simple, each_n}, state) do
    # IO.inspect (each_n*each_n)
    {:noreply, [each_n*each_n | state]}
    # {:noreply, state}
  end

 def handle_cast({:ass, each_n}, state) do              #Using mathematical equation
    # Logger.info "Working on #{each_n}"

    res = getFangs(each_n)
    if not is_nil(res) do
      IO.puts "#{each_n}"
      {:noreply, [res | state]}
   else 
    {:noreply, state}
  end
 end

  def isNumberDigitsEven(n) do
    Integer.mod(String.length(Integer.to_string(n)), 2) == 0
  end

  def permutations([]), do: [[]]
  def permutations(list), do: for elem <- list, rest <- permutations(list--[elem]), do: [elem|rest]

  def getPerms(n_str) do
    Enum.map(permutations(String.to_charlist(n_str)),  fn(x) -> to_string(x) end)

  end

  def getSplitStrings(n_str) do
    Enum.map(getPerms(n_str), fn(x) -> String.split_at(x, Kernel.trunc(String.length(x)/2)) end)
  end

  def getFangs(n_str) do
    if isNumberDigitsEven(n_str) do
      Enum.filter(getSplitStrings(Integer.to_string(n_str)),
                  fn(x) -> (String.to_integer(elem(x, 0)) * String.to_integer(elem(x,1)) == n_str) end)
    end
  end

end
