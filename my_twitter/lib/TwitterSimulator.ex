defmodule TwitterSimulator do
    use GenServer
    def start_link(num_clients) do
        IO.puts "Starting the simulator"
        #num_clnt = String.to_integer(num_clients)
        state = %{:num_clients => num_clients}
        GenServer.start_link(__MODULE__, state, name: {:global, :TwitterSimulator})
    end

    def init(state) do
        IO.puts "Start the client processes"
        :global.sync()

        main_server = :global.whereis_name(:server)
        ets_server = :global.whereis_name(:ets_server)

        IO.puts "Main Server #{inspect main_server}"
        #IO.puts "ETS Server #{inspect ets_server}"
        

        send(main_server, {:init_clients,state[:num_clients]})
        client_pids = Enum.map(1..state[:num_clients], fn client_id -> 
                                    {:ok, client_pid} = TwitterClient.start_link(
                                                        %{"client_id" => client_id, 
                                                          "server" => main_server,
                                                          "num_clients" => state[:num_clients], 
                                                          "num_followers" => 2
                                                        })
                                                    client_pid
                                                    end)
                                               
        state = Map.put(state, :clients, client_pids)                                      
        {:ok, state}
    end

    def handle_info({:simulate}, state) do
        IO.puts "Start simulating the Twitter Engine"
        clients = state[:clients]

        num_clnt = if !is_integer(state[:num_clients]) do
            String.to_integer(state[:num_clients])
        else   
            state[:num_clients]
        end
        
        Enum.each(1..num_clnt, fn client_id ->  
                                            Process.send_after(Enum.at(clients, client_id-1), {:tweet}, 1)
                                             
                                end)
        ets_server = :global.whereis_name(:ets_server)             
        {:noreply, state}
    end
end