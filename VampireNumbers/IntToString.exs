defmodule IsVampire do

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
    Enum.filter(getSplitStrings(n_str),
    fn(x) -> (String.to_integer(elem(x, 0)) * String.to_integer(elem(x,1)) == String.to_integer(n_str))
     end)
  end
end
