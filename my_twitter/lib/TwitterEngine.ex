defmodule TwitterEngine do
    use GenServer
    #Make the server accessible globally
    def start_link() do
        GenServer.start_link(__MODULE__, nil, name: {:global, :server})
    end 

    def init(_) do
        IO.puts "Server up!"
        #{:ok, ets_server_id} = ETSServer.start_link()
        server_state = %{
            :num_clients => 0,
            :num_followers => 0,
            #:ets_server => ets_server_id
        }
        IO.inspect server_state
        {:ok, server_state}
    end

    def handle_info({:init_clients, num_clients}, server_state) do
        # IO.puts "Create a link to the ETS Server process and hold it in the state"
        # #{:ok, ets_server_id} = ETSServer.start_link()
         {:ok, ets_server_id} = GenServer.start_link(ETSServer, :ok, name: {:global, :ets_server})
        server_state = Map.put(server_state, :num_clients, num_clients)
        server_state = Map.put(server_state, :ets_server, ets_server_id)

        IO.puts "Followers updated, ask the simulator to generate Tweets"
        :global.sync()
        simulator = :global.whereis_name(:TwitterSimulator)
    
        #GenServer.call(simulator, {:simulate})
        Process.send_after(simulator, {:simulate}, 2)
        {:noreply, server_state}

    end

    def handle_info({:register_client, client_id, pid}, server_state) do
        IO.puts "Registering in server"
        GenServer.cast(server_state[:ets_server], {:register, client_id, pid})
        {:noreply, server_state}
    end

    def handle_info({:init_followers, client_id, pid, my_followers}, server_state) do
         GenServer.cast(server_state[:ets_server], {:init_followers, client_id, pid, my_followers})
        {_, server_state} = Map.get_and_update(server_state, :num_followers, fn foll -> {foll, foll + 1} end)
        {:noreply, server_state}  
    end

    def handle_cast({:tweet, client_id, tweet}, server_state) do
        IO.puts "Client #{client_id} tweeted : #{tweet}"
        GenServer.cast(server_state[:ets_server], {:store_tweet, client_id, client_id, tweet})

        IO.puts "Now start sending the tweet to the mentioned users"
        split_tweet = String.split(tweet)

        mentions = Enum.filter(split_tweet, fn string -> String.at(string,0) == "@" end)
        
        if mentions != [] do
            Enum.each(mentions, fn mention -> 
                mentioned_user = String.to_integer(String.trim_leading(mention, "@"))
                GenServer.cast(server_state[:ets_server], {:add_mentions, mentioned_user, client_id, tweet})
            end)
        
        else IO.puts "No mentions in the tweet"
        end    

        IO.puts "Now send my tweet to all the followers"

        #send_tweet(client_id, tweet, server_state[:ets_server])
        my_followers = GenServer.call(server_state[:ets_server], {:my_followers, client_id})
        #my_pid = GenServer.call(ets_pid, {:get_pid, client_id})
        #Enum.each(my_followers, fn foll -> GenServer.cast(self(), {:post_tweet, foll, tweet, client_id}) end)

        IO.inspect my_followers
        Enum.each(my_followers, fn follower -> 
            follower_pid = GenServer.call(server_state[:ets_server], {:get_pid, follower})
            GenServer.cast(follower_pid, {:tweet_feed, client_id, tweet})
        end)

        {:noreply, server_state}

    end

    # def send_tweet(client_id, tweet, ets_pid) do
    #    my_followers = GenServer.call(ets_pid, {:my_followers, client_id})
    #    #my_pid = GenServer.call(ets_pid, {:get_pid, client_id})

    #     #    Enum.each(followers, fn follower -> 
    #     #     worker_index =  Util.log2(follower)
    #     #     GenServer.cast(state[:workers][worker_index][:processor], {:deliver_tweet, follower, user, tweet, timestamp, retweet, origin})
    #     #     end)
    #     #Enum.each(my_followers, fn foll -> GenServer.cast(self(), {:post_tweet, foll, tweet, client_id}) end)

        
    # end

    # def hande_cast({:post_tweet, follower, tweet, client_id}, server_state) do
    #     #Handle isAlive if needed  - Getting the User ID who has a state as live
    #     follower_pid = GenServer.call(server_state[:ets_server], {:get_pid, follower})
    #     #client_id - person who I follow
    #     GenServer.cast(follower_pid, {:tweet_feed, client_id, tweet})
        
    #     {:noreply, server_state}

    # end
end