defmodule ETSServer do
    use GenServer

    def start_link() do
        GenServer.start_link(__MODULE__, :ok, name: {:global, :ets_server})
    end

    def get_monitor do
        [keyVal] = :ets.lookup(:monitor, :mpid)
        elem(keyVal, 1)
    end

    def init(_) do
        ets_server_state = %{:clients_registry => :ets.new(:registry, [:set, :public, :named_table]), 
                             :followers => :ets.new(:followers, [:set, :public, :named_table]),
                             :tweets => :ets.new(:tweets, [:set, :public, :named_table]), 
                             :mentions => :ets.new(:mentions, [:set, :public, :named_table]),
                             :hashtags => :ets.new(:hashtags, [:set, :public, :named_table]),
                             :retweets => :ets.new(:retweets, [:set, :public, :named_table])
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
        # followers_time_diff = System.system_time(:millisecond) - start_time
        # send(get_monitor(), {:follower_metric, followers_time_diff})
        {:noreply, ets_server_state}
    end

    def handle_cast({:store_tweet, client_id, tweet_id, tweet}, ets_server_state) do
        new_row = :ets.insert(:tweets, {client_id, {tweet_id, tweet}})
        ets_server_state = Map.put(ets_server_state, :tweets, new_row)
        {:noreply, ets_server_state}
    end

    def handle_cast({:store_retweet, client_id, received_through, tweet}, ets_server_state) do
        new_row = :ets.insert(:retweets, {client_id, {received_through, tweet}})
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
            [{client_id, []}]
        end

        #IO.inspect row
        just_tweets = if elem(row,1) != [] do
            tweet_list = Tuple.to_list(elem(row, 1))
            tweet_list
        else
            []
        end
        {:reply, just_tweets, ets_server_state}
        
    end

    def handle_call({:my_retweets, client_id}, _from, ets_server_state) do
        [row] = if :ets.lookup(:retweets, client_id) != [] do
            :ets.lookup(:retweets, client_id)
        else
            [{client_id, {[],[]}}]
        end

        retweets = elem(elem(row,1),1)
        {:reply, retweets, ets_server_state}
    end

    def handle_call({:tweets_with_hashtags, hashtag}, _from, ets_server_state) do
        hash_trimmed_tag = String.trim_leading(hashtag, "#")
        [row] = if :ets.lookup(:hashtags, hash_trimmed_tag) != [] do
            :ets.lookup(:hashtags, hash_trimmed_tag)
        else
            [{hash_trimmed_tag, []}]
        end
        tweets_with_hashtag = Enum.at(elem(row,1),0)

        {:reply, tweets_with_hashtag, ets_server_state}
    end

    def handle_call({:my_mentions, mentioned}, _from, ets_server_state) do
        [row] = if :ets.lookup(:mentions, mentioned) != [] do
            :ets.lookup(:mentions, mentioned)
            
        else
            [{mentioned, []}]
        end

        just_tweets = if elem(row,1) != [] do
            tweet_list = elem(row, 1)
            mentioned_list = Enum.map(tweet_list, fn x -> elem(x,1) end)
            mentioned_list
        else
            []
        end

        {:reply, just_tweets, ets_server_state}
    end
   
    
    def handle_call({:get_pid, client_id}, _from, ets_server_state) do
        
        [row] = if :ets.lookup(:registry, client_id) != [] do
                   :ets.lookup(:registry, client_id)
                else
                   [{client_id, []}] 
                end
        pid = elem(row,1)
        
        {:reply, pid, ets_server_state}
    end

    def handle_call({:all_my_tweets, client_id}, _from, ets_server_state) do
        [tweets] = if :ets.lookup(:tweets, client_id) != [] do
                    :ets.lookup(:tweets, client_id)
                   else
                        []
                   end
        [retweets] = if :ets.lookup(:retweets, client_id) != [] do
                        :ets.lookup(:retweets, client_id)
                     else
                        []
                     end
        result = retweets ++ tweets
        result = Enum.filter(result, fn x -> x != [] end)
        all_my_tweets = elem(elem(result, 1),1)

        {:reply, all_my_tweets, ets_server_state}             
    
    end

    def handle_cast({:add_mentions, mentioned, tweeter, tweet}, ets_server_state) do
        if :ets.lookup(:mentions, mentioned) == [] do
            mentioned_list = []
            mentioned_list = [{tweeter, tweet} | mentioned_list]
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

    def handle_cast({:store_tweet, client_id, tweet_id, tweet}, ets_server_state) do
        if :ets.lookup(:tweets, client_id) == [] do
            tweet_list = []
            tweet_list = [{tweet_id, tweet} | tweet_list]
            :ets.insert(:tweets, {client_id, tweet_list})
            ets_server_state = Map.put(ets_server_state, :tweets, tweet_list)

        else
            my_tweets = :ets.lookup(:tweets, client_id)
            my_tweets = [{tweet_id, tweet} | my_tweets]
            :ets.insert(:tweets, {client_id, my_tweets})
            :ets_server_state = Map.put(ets_server_state, :tweets, my_tweets)
        end

        {:noreply, ets_server_state}
    end

    def handle_cast({:add_hashtags, hashtag, tweet}, ets_server_state) do
        hash_trimmed_tag = String.trim_leading(hashtag, "#")
        if :ets.lookup(:hashtags, hash_trimmed_tag) == [] do
            tweets_with_hashtag = []
            tweets_with_hashtag = [tweet| tweets_with_hashtag]
            :ets.insert(:hashtags, {hash_trimmed_tag, tweets_with_hashtag})
            ets_server_state = Map.put(ets_server_state, :hashtags, tweets_with_hashtag)
        
        else
            tweets_with_hashtag = :ets.lookup(:hashtags, hash_trimmed_tag)
            tweets_with_hashtag = [tweet | tweets_with_hashtag]
            :ets.insert(:hashtags, {hash_trimmed_tag, tweets_with_hashtag})
            ets_server_state = Map.put(ets_server_state, :hashtags, tweets_with_hashtag)
        end
        {:noreply, ets_server_state}
    end    
end