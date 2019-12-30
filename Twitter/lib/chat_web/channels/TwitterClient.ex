defmodule TwitterClient do
  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  # def get_register_monitor do
  #     [keyVal] = :ets.lookup(:monitor, :registerm)
  #     elem(keyVal, 1)
  # end

  # def get_follower_monitor do
  #     [keyVal] = :ets.lookup(:monitor, :followerm)
  #     elem(keyVal, 1)
  # end

  # def get_tweet_monitor do
  #     [keyVal] = :ets.lookup(:monitor, :tweetm)
  #     elem(keyVal, 1)
  # end

  def init(state) do
    register(state)
    create_followers(state)
    {:ok, state}
  end

  def register(state) do
    start_time = System.system_time(:millisecond)
    # :timer.sleep(10)
    send(state["server"], {:register_client, state["client_id"], self()})
    register_time_diff = System.system_time(:millisecond) - start_time
    # send(get_register_monitor(), {:reg_metric, register_time_diff})     
  end

  def create_followers(state) do
    start_time = System.system_time(:millisecond)
    num_followers = state["num_followers"]
    client_id = state["client_id"]

    my_followers =
      Enum.reduce(1..num_followers, [], fn _, acc ->
        [add_followers(num_followers, client_id) | acc]
      end)

    my_followers = Enum.uniq(my_followers)
    # IO.puts "Followers of #{client_id} are #{inspect my_followers}"
    send(state["server"], {:init_followers, client_id, self(), my_followers})
    followers_time_diff = System.system_time(:millisecond) - start_time
    # send(get_follower_monitor(), {:follower_metric, followers_time_diff})
  end

  def handle_info({:tweet, num_msgs, socket}, state) do
    start_time = System.system_time(:millisecond)
    Enum.each(1..num_msgs, fn _ -> send(self(), {:keep_tweeting, socket}) end)
    time_diff = System.system_time(:millisecond) - start_time
    # send(get_tweet_monitor(), {:tweet_metric, time_diff})
    {:noreply, state}
  end

  def handle_info({:keep_tweeting, socket}, state) do
    tweet = generate_tweet(state)
    userId = state["client_id"]

    if userId == 53 do
      :timer.sleep(4000)
    end

    send_payload(userId, tweet, socket)
    GenServer.cast(state["server"], {:tweet, state["client_id"], tweet})
    {:noreply, state}
  end

  def handle_cast({:tweet_feed, tweeter, tweet, received_through}, state) do
    IO.puts("Tweeter #{tweeter} tweeted #{tweet} #{received_through}")
    # Once things come up on my tweet, I will choose to retweet/not
    Process.sleep(2)

    handle_retweet(state["server"], state["client_id"], tweet, tweeter)

    Process.sleep(2)
    query_my_tweets(state["server"], state["client_id"])

    {:noreply, state}
  end

  def handle_retweet(server, user, tweet, tweeter) do
    should_retweet = Enum.random(1..100)

    if should_retweet > 80 do
      # IO.puts "User #{user} is going to retweet #{tweeter}'s tweet #{tweet}"
      GenServer.cast(server, {:retweet, user, tweet, tweeter})
    end
  end

  def query_my_tweets(server, user) do
    should_query = Enum.random(1..100)

    if should_query > 80 do
      Task.start(fn ->
        query_response = GenServer.call(server, {:query_tweets, user}, :infinity)
        # IO.puts "Got the reply for my tweets query by user #{user}"
        IO.puts(
          "Got the reply for my tweets query by user #{user} and the tweets: #{
            inspect(query_response)
          }"
        )
      end)

      Task.start(fn ->
        query_response = GenServer.call(server, {:query_mentions, user}, :infinity)
        # IO.puts "Got the reply for the my mentions query by user #{user}"
        IO.puts(
          "Got the reply for the my mentions query by user #{user} and the tweets: #{
            inspect(query_response)
          }"
        )
      end)

      Task.start(fn ->
        hashtag = get_random_hashtag()
        query_response = GenServer.call(server, {:query_hashtags, hashtag}, :infinity)
        # IO.puts "Got the reply for get hashtags query for the hashtag #{hashtag}"
        IO.puts(
          "Got the reply for get hashtags query for the hashtag #{hashtag} and the tweets: #{
            inspect(query_response)
          }"
        )
      end)
    end
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
    char = List.to_string([<<96 + n>>])
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
    tweet = name <> " " <> "@" <> Integer.to_string(rand_mention) <> " " <> get_random_hashtag()
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

  def get_random_hashtag() do
    some_random_hashtags = [
      "#COP5615IsGreat",
      "#Dracarys",
      "#CyberTruck",
      "#OkGoogle",
      "#LetsFIFA20",
      "#BohemianRhapsody",
      "#Joker",
      "#MacbookPro",
      "#LifeOnMars",
      "#DriverlessCars"
    ]

    rand_index = Enum.random(0..(length(some_random_hashtags) - 1))
    Enum.at(some_random_hashtags, rand_index)
  end

  def handle_info(:kill_me_pls, state) do
    {:stop, :normal, state}
  end

  def send_payload(userid, text, socket) do
    payload = %{
      name: userid,
      message: text
    }

    ChatWeb.Endpoint.broadcast("room:lobby", "shout", payload)
  end
end
