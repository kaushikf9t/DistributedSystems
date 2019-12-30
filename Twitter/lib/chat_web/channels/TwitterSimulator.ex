defmodule TwitterSimulator do
  use GenServer

  def start_link(num_clients, num_msgs, num_followers, socket) do
    IO.puts("Starting the simulator")
    send_payload(num_clients)

    state = %{
      :num_clients => num_clients,
      :num_msgs => num_msgs,
      :num_followers => num_followers,
      :socket => socket
    }

    GenServer.start_link(__MODULE__, state, name: {:global, :TwitterSimulator})
  end

  def init(state) do
    IO.puts("Start the client processes")
    :global.sync()

    main_server = :global.whereis_name(:server)
    ets_server = :global.whereis_name(:ets_server)

    IO.puts("Main Server #{inspect(main_server)}")
    IO.puts("ETS Server #{inspect(ets_server)}")

    send(main_server, {:init_clients, state[:num_clients]})

    client_pids =
      Enum.map(1..state[:num_clients], fn client_id ->
        n_msgs =
          if state[:num_followers] > 0 or state[:num_followers] != nil,
            do: state[:num_msgs] / client_id,
            else: state[:num_msgs]

        n_followers =
          if state[:num_followers] > 0 or state[:num_followers] != nil,
            do: state[:num_msgs] / client_id,
            else: state[:num_msgs]

        {:ok, client_pid} =
          TwitterClient.start_link(%{
            "client_id" => client_id,
            "server" => main_server,
            "num_clients" => state[:num_clients],
            "num_msgs" => Kernel.round(n_msgs),
            "num_followers" => Kernel.round(n_followers)
          })

        client_pid
      end)

    state = Map.put(state, :clients, client_pids)
    {:ok, state}
  end

  def handle_info({:simulate}, state) do
    IO.puts("Start simulating the Twitter Engine")
    clients = state[:clients]
    IO.puts("Does this have anything #{inspect(clients)}")
    IO.puts("Clients #{inspect(clients)}")

    num_clnt =
      if !is_integer(state[:num_clients]) do
        String.to_integer(state[:num_clients])
      else
        state[:num_clients]
      end

    Enum.each(1..num_clnt, fn client_id ->
      send(Enum.at(clients, client_id - 1), {:tweet, state[:num_msgs], state[:socket]})
    end)

    # Code to keep killing processes and restarting them    
    state = infinite(state, 0)

    {:noreply, state}
  end

  def infinite(state, count) do
    if count < 10 do
      client_to_kill = Enum.random(1..state[:num_clients])
      client_pids = Map.get(state, :clients)
      IO.puts("Killing the client #{inspect(Enum.at(client_pids, client_to_kill))}")

      if Enum.at(client_pids, client_to_kill) != nil do
        send(Enum.at(client_pids, client_to_kill), :kill_me_pls)

        # Process.exit(Enum.at(client_pids, client_to_kill), :kill)
        # IO.puts "Killed completely?"
        client_pids = List.replace_at(client_pids, client_to_kill, nil)
        # state = Map.put(state, :clients, client_pids)

        :timer.sleep(3000)
        # TwitterClient.start_link(state[:num_clients], state[:num_msgs])
        {:ok, client_pid} =
          TwitterClient.start_link(%{
            "client_id" => client_to_kill,
            "server" => :global.whereis_name(:server),
            "num_clients" => state[:num_clients],
            "num_msgs" => state[:num_msgs],
            "num_followers" => 5
          })

        IO.puts("Restarting the client with the new PID #{inspect(client_pid)}")
        client_pids = List.replace_at(client_pids, client_to_kill, client_pid)
        state = Map.put(state, :clients, client_pids)

        infinite(state, count + 1)
      else
        infinite(state, count)
      end
    else
      state
    end
  end

  def send_payload(num_clients) do
    payload = %{
      num_clients: num_clients
    }

    ChatWeb.Endpoint.broadcast("room:lobby", "popusers", payload)
  end
end
