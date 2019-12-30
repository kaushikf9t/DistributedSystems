defmodule TwitterEngine do
    use GenServer
    #Make the server accessible globally
    def start_link() do
        GenServer.start_link(__MODULE__, nil, name: {:global, :server})
    end 

    def init(_) do
        IO.puts "Server up!"
        {:ok, ets_server_id} = GenServer.start_link(ETSServer, :ok, name: {:global, :ets_server})
        server_state = %{:num_clients => 0, :num_followers => 0, :ets_server => ets_server_id}
        {:ok, server_state}
    end

    def handle_info({:init_clients, num_clients}, server_state) do
        server_state = Map.put(server_state, :num_clients, num_clients)

        IO.puts "Followers updated, ask the simulator to generate Tweets"
        :global.sync()
        simulator = :global.whereis_name(:TwitterSimulator)
        IO.puts "Simulator is at #{inspect simulator}"
        Task.start(fn -> send(simulator, {:simulate})end)
        {:noreply, server_state}

    end

    def handle_info({:register_client, client_id, pid}, server_state) do
        GenServer.cast(server_state[:ets_server], {:register, client_id, pid})
        {:noreply, server_state}
    end

    def handle_info({:init_followers, client_id, pid, my_followers}, server_state) do
         GenServer.cast(server_state[:ets_server], {:init_followers, client_id, pid, my_followers})
        {_, server_state} = Map.get_and_update(server_state, :num_followers, fn foll -> {foll, foll + 1} end)
        {:noreply, server_state}  
    end

    def handle_cast({:tweet, client_id, tweet}, server_state) do
        #IO.puts "Client #{client_id} tweeted : #{tweet}"
        GenServer.cast(server_state[:ets_server], {:store_tweet, client_id, client_id, tweet})

        IO.puts "Now start sending the tweet to the mentioned users"
        split_tweet = String.split(tweet)

        #IO.puts "Process hashtags too"
        mentions = Enum.filter(split_tweet, fn string -> String.at(string,0) == "@" end)
        
        if mentions != [] do
            Enum.each(mentions, fn mention -> 
                mentioned_user = String.to_integer(String.trim_leading(mention, "@"))
                GenServer.cast(server_state[:ets_server], {:add_mentions, mentioned_user, client_id, tweet})
            end)
        else IO.puts "No mentions in the tweet"
        end

        hashtags = Enum.filter(split_tweet, fn string -> String.at(string, 0) == "#" end)
        if hashtags != [] do
            Enum.each(hashtags, fn hashtag -> 
                GenServer.cast(server_state[:ets_server], {:add_hashtags, hashtag, tweet})
            end)
            
        else IO.puts "No hashtags in the tweet" 
        end
            
        #IO.puts "Now send my tweet to all the followers"

        my_followers = GenServer.call(server_state[:ets_server], {:my_followers, client_id})
        IO.inspect my_followers
        if my_followers != [] do
            Task.start(fn ->
                Enum.each(my_followers, fn follower -> 
                follower_pid = GenServer.call(server_state[:ets_server], {:get_pid, follower})
                if follower_pid != [] do
                    GenServer.cast(follower_pid, {:tweet_feed, client_id, tweet, " "})
                end 
                end)
            end)
        
        else 
            IO.puts "No followers"
        end

        {:noreply, server_state}

    end

    def handle_cast({:retweet, user, tweet, tweeter}, server_state) do
        #IO.puts "Client #{user} retweeted : #{tweet}"

        GenServer.cast(server_state[:ets_server], {:store_retweet, user, tweeter, tweet})
        my_followers = GenServer.call(server_state[:ets_server], {:my_followers, user})

        Enum.each(my_followers, fn follower -> 
            follower_pid = GenServer.call(server_state[:ets_server], {:get_pid, follower})
            GenServer.cast(follower_pid, {:tweet_feed, user, tweet, "RT"})
        end)

        {:noreply, server_state}
    end

    def handle_call({:query_tweets, user}, _from, server_state) do
        result = GenServer.call(server_state[:ets_server], {:my_tweets, user}, :infinity)
        {:reply, result, server_state}
    end
    
    def handle_call({:query_mentions, user}, _from, server_state) do
        result = GenServer.call(server_state[:ets_server], {:my_mentions, user}, :infinity)
        {:reply, result, server_state}
    end

    def handle_call({:query_hashtags, hashtag}, _from, server_state) do
        result = GenServer.call(server_state[:ets_server], {:tweets_with_hashtags, hashtag}, :infinity)
        {:reply, result, server_state}
    end

end   