defmodule IsVampire do

  def parallelExec(collection) do
    collection
    |> Enum.map(&(Task.async(fn -> getFangs(&1) end)))
    |> Enum.map(&Task.await/1)
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
    if :isNumberDigitsEven do
      Enum.filter(getSplitStrings(Integer.to_string(n_str)),
                  fn(x) -> (String.to_integer(elem(x, 0)) * String.to_integer(elem(x,1)) == n_str) end)
    else
    end
  end
end
