defmodule Monitor do
  def set_register_listener(pid) do
    
    :ets.insert(:monitor, {:registerm, pid})
    # PIDManager.set({:mpid, pid})
  end

  def set_follower_listener(pid) do
    # :ets.new(:monitor, [:set, :public, :named_table])
    :ets.insert(:monitor, {:followerm, pid})
    # PIDManager.set({:mpid, pid})
  end

  def set_tweet_listener(pid) do
    :ets.insert(:monitor, {:tweetm, pid})
  end

  def initiate(numClients) do
    :ets.new(:monitor, [:set, :public, :named_table])
    # listener = Task.async(fn -> monitoring_server(numClients, numClients, 0, 0, 0, 0, 0) end)
    register_listener = Task.async(fn -> monitor_registerations(numClients, 0, numClients) end)
    set_register_listener(register_listener.pid)
    IO.puts "#{inspect register_listener}"
    follower = Task.async(fn -> monitor_followers(numClients, 0, numClients) end)
    set_follower_listener(follower.pid)
    tweets = Task.async(fn -> monitor_followers(numClients, 0, numClients) end)
    set_tweet_listener(tweets.pid)
    IO.puts "#{inspect follower}"
    # :timer.sleep(3000)
    follower
  end

  def write_to_report(line) do
    file = File.open!("PerformanceReport.txt", [:read, :utf8, :write, :append])
    IO.puts(file, line)
  end

  def monitor_registerations(0, time_diff, totalClients) do
    avg = time_diff/totalClients
    write_to_report("Average time taken for doing registration per client = #{avg} milliseconds")
  end

  def monitor_registerations(numClients, time_diff, totalClients) do
    receive do
      {:reg_metric, ind_time_diff} -> monitor_registerations(numClients-1, time_diff+ind_time_diff, totalClients)
    end
  end

  def monitor_followers(0, time_diff, totalClients) do
    avg = time_diff/totalClients
    write_to_report("Average time taken for creating followers per client = #{avg} milliseconds")
  end

  def monitor_followers(numClients, time_diff, totalClients) do
    receive do
      {:follower_metric, ind_time_diff} -> monitor_followers(numClients-1, time_diff+ind_time_diff, totalClients)
    end
  end

  def monitor_tweets(0, time_diff, totalClients) do
    avg = time_diff/totalClients
    write_to_report("Average time taken for tweeting per client = #{avg} milliseconds")
  end

  def monitor_tweets(numClients, time_diff, totalClients) do
    receive do
      {:follower_metric, ind_time_diff} -> monitor_tweets(numClients-1, time_diff+ind_time_diff, totalClients)
    end
  end

  def monitoring_server(
        0,
        totalClients,
        tweets_time_diff,
        queries_subscribedto_time_diff,
        queries_hashtag_time_diff,
        queries_mention_time_diff,
        queries_myTweets_time_diff
      ) do
    IO.puts("Avg. time to tweet: #{tweets_time_diff / totalClients} milliseconds")

    IO.puts(
      "Avg. time to query tweets subscribe to: #{queries_subscribedto_time_diff / totalClients} milliseconds"
    )

    IO.puts(
      "Avg. time to query tweets by hashtag: #{queries_hashtag_time_diff / totalClients} milliseconds"
    )

    IO.puts(
      "Avg. time to query tweets by mention: #{queries_mention_time_diff / totalClients} milliseconds"
    )

    IO.puts(
      "Avg. time to query all relevant tweets: #{queries_myTweets_time_diff / totalClients} milliseconds"
    )
  end

  def monitoring_server(
        numClients,
        totalClients,
        tweets_time_diff,
        queries_subscribedto_time_diff,
        queries_hashtag_time_diff,
        queries_mention_time_diff,
        queries_myTweets_time_diff
      ) do
    receive do
      {:perfmetrics, a, b, c, d, e} ->
        # IO.puts("########################################## numClients:#{numClients}")

        monitoring_server(
          numClients - 1,
          totalClients,
          tweets_time_diff + a,
          queries_subscribedto_time_diff + b,
          queries_hashtag_time_diff + c,
          queries_mention_time_diff + d,
          queries_myTweets_time_diff + e
        )
    end
  end
end
