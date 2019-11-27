defmodule Runner do
    def main(params) do
        #{:ok, _} = Registry.start_link(keys: :unique, name: Registry.ViaTest)
        #{:ok, server} = Task.start(fn -> TwitterEngine.start_link() end)
        TwitterEngine.start_link()
		#:sys.trace server, true 
        num_users = Enum.at(params,0)
        num_msgs = Enum.at(params, 1)
        # n_users = String.to_integer(num_users)
        # n_msgs = String.to_integer(num_msgs)
        # :global.sync()
        TwitterSimulator.start_link(num_users)
		#:sys.trace simulator_pid, true
    end
end