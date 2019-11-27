defmodule Twitter.CLI do
  def start(_type, _args) do
    args = System.argv()
    param1 = Enum.at(args,0)
    param2 = Enum.at(args,1)
    mainargs = [param1, param2]
    Runner.main(mainargs)
    {:ok, self()}
  end
end
