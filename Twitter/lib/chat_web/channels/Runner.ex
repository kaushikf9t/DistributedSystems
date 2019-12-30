defmodule Runner do
  def main(num_users, num_msgs, socket) do
    start_time = System.system_time(:millisecond)
    TwitterEngine.start_link()
    # :sys.trace server, true 
    # num_users = Enum.at(params,0)
    # num_msgs = Enum.at(params, 1)
    # num_followers = Enum.at(params, 2)

    # start_time = System.system_time(:millisecond)

    n_users =
      if is_binary(num_users) do
        String.to_integer(num_users)
      else
        num_users
      end

    n_msgs =
      if is_binary(num_msgs) do
        String.to_integer(num_msgs)
      else
        num_msgs
      end

    # n_followers =
    #   if is_binary(num_followers) do
    #     String.to_integer(num_followers)
    #   else
    #     num_followers
    #   end

    # :global.sync()
    # Monitor.initiate(n_users)
    TwitterSimulator.start_link(n_users, n_msgs, 0, socket)
  end
end
