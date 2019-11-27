defmodule ETSServer do
    use GenServer

    def start_link() do
        GenServer.start_link(__MODULE__, :ok, name: {:global, :ets_server})
    end

    def init(_) do
        ets_server_state = %{:clients_registry => :ets.new(:registry, [:set, :public, :named_table]), 
                             :followers => :ets.new(:followers, [:set, :public, :named_table]),
                             :tweets => :ets.new(:tweets, [:set, :public, :named_table]), 
                             :mentions => :ets.new(:mentions, [:set, :public, :named_table])
                            }
        
        {:ok, ets_server_state}
    end

    def handle_cast({:register, client_id, pid}, ets_server_state) do
        new_row = :ets.insert(:registry, {client_id, pid})
        ets_server_state = Map.put(ets_server_state, :clients_registry, new_row)
        {:noreply, ets_server_state}
    end

    def handle_cast({:init_followers, client_id, pid, followers}, ets_server_state) do
        new_row = :ets.insert(:followers, {client_id, followers})
        ets_server_state = Map.put(ets_server_state, :followers, new_row)
        {:noreply, ets_server_state}
    end

    def handle_cast({:store_tweet, client_id, tweet_id, tweet}, ets_server_state) do
        new_row = :ets.insert(:tweets, {client_id, {tweet_id, tweet}})
        ets_server_state = Map.put(ets_server_state, :tweets, new_row)
        {:noreply, ets_server_state}
    end

    def handle_call({:my_followers, client_id}, _from, ets_server_state) do
        [row] = if :ets.lookup(:followers, client_id) != [] do
            :ets.lookup(:followers, client_id)
        else
            [{client_id,[]}]
        end

        followers = elem(row, 1)
        {:reply, followers, ets_server_state}
    end

    def handle_call({:my_tweets, client_id}, _from, ets_server_state) do
        [row] = if :ets.lookup(:tweets, client_id) != [] do
            :ets.lookup(:tweets, client_id)
        else
            [{client_id,{[],[]}}]
        end

        tweets = elem(elem(row,1),1)
        {:reply, tweets, ets_server_state} 
    end
    
    def handle_call({:get_pid, client_id}, _from, ets_server_state) do
        [row] = :ets.lookup(:registry, client_id)
        pid = elem(row,1)
        
        {:reply, pid, ets_server_state}
    end

    def handle_cast({:add_mentions, mentioned, tweeter, tweet}, ets_server_state) do
        if :ets.lookup(:mentions, mentioned) == [] do
            mentioned_list = []
            mentioned_list = [{tweeter, tweet} | mentioned_list]
            #Mentioned List per client => [{tweeter, tweet}]
           :ets.insert(:mentions, {mentioned, mentioned_list})
           ets_server_state = Map.put(ets_server_state, :mentions, mentioned_list)
        
        else
            my_mentions = :ets.lookup(:mentions, mentioned)
            my_mentions = [{tweeter, tweet}| my_mentions]
            :ets.insert(:mentions, {mentioned, my_mentions})
            ets_server_state = Map.put(ets_server_state, :mentions, my_mentions)
        end
        
        {:noreply, ets_server_state} 

    end    

end