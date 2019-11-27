defmodule TwitterClient do
    use GenServer

    def start_link(state) do
        GenServer.start_link(__MODULE__, state)
    end
    
    def init(state) do
      register(state)
      create_followers(state)
      {:ok, state}

    end

    def register(state) do
        Task.start fn -> send(state["server"], {:register_client, state["client_id"], self()}) end        
    end
    
    def create_followers(state) do
      num_followers = state["num_followers"]
      client_id = state["client_id"]
      my_followers = Enum.reduce(1..num_followers, [], fn _, acc -> [add_followers(num_followers, client_id)|acc] end)
      IO.puts "Followers of #{client_id} are #{inspect my_followers}"
      send(state["server"], {:init_followers, client_id, self(), my_followers})
    end

    def handle_info({:tweet}, state) do
      #IO.puts "At least starts tweeting"
      Process.send_after(self(), {:keep_tweeting}, state["client_id"] )
      {:noreply, state}
    end

    def handle_info({:keep_tweeting}, state) do
      #IO.puts "Keeps tweeting"
      tweet = generate_tweet(state)
      GenServer.cast(state["server"], {:tweet, state["client_id"], tweet})
      {:noreply, state}

    end

    def handle_cast({:tweet_feed, tweeter, tweet}, state) do
       IO.puts "Tweeter #{tweeter} tweeted #{tweet}"
      {:noreply, state}
    end

    def add_followers(num_followers, my_id) do
      foll = Enum.random(1..num_followers)
      
      if foll == my_id do
        add_followers(num_followers, my_id)
      
      else 
        foll
      end
    end

    def generate_name(name) do
        n = :rand.uniform(26)
        char = List.to_string([<<96+n>>])
        name = name <> char
        if String.length(name) < 6 do
            generate_name(name)
        else
            name
        end
    end

    def generate_tweet(state) do
      name = generate_name("")
      rand_mention = generate_random_mention(state["client_id"], state["num_clients"])
      tweet = name <> " " <>"@" <> Integer.to_string(rand_mention)
      tweet
    end

    def generate_random_mention(client_id, num_clients) do
      rand_mention = Enum.random(1..num_clients)
      if(rand_mention == client_id) do
        generate_random_mention(client_id, num_clients)
      else
        rand_mention
      end 
    end

end