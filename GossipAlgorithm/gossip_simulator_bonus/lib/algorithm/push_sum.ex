defmodule Algorithm.PushSum do
  use GenServer

  def start_link(sum) do
    GenServer.start_link(__MODULE__, sum)
  end

  def get_sum_estimate(pid) do
    GenServer.call(pid, :get_sum_estimate)
  end

  def get_ratio_queue(pid) do
    GenServer.call(pid, :get_ratio_queue)
  end

  def receive(pid, re_sum, re_w) do
    GenServer.call(pid, {:receive, re_sum, re_w})
  end

  def send(pid, neighbours, black_list) do
    cond do
      neighbours == nil ->
        GenServer.call(pid, :send_alone)
        MapSet.subset?(MapSet.new([]), black_list)===true ->
        GenServer.call(pid, :send_alone)
      neighbours == [] ->
        GenServer.call(pid, :send_alone)
        MapSet.subset?(MapSet.new(neighbours), black_list)===true ->
        GenServer.call(pid, :send_alone)
      true ->
        rand_pid = get_random_neighbour(neighbours, black_list)
        GenServer.call(pid, {:send, rand_pid})
    end
  end

  def get_random_neighbour(neighbours, black_list) do
    rand_pid = Enum.random(neighbours)
    rand_pid = if (MapSet.member?(black_list, rand_pid)===true) do
      get_random_neighbour(neighbours, black_list)
    else
      rand_pid
    end
    rand_pid
  end

  def init(sum) do
    w = 1
    ratio_q = :queue.new
    {:ok, [[sum,w], ratio_q]}
  end

  def handle_call(:get_ratio_queue, _from, cur_state) do
    [_sum_state | [ratio_q]] = cur_state
    {:reply, ratio_q, cur_state}
  end

  def handle_call(:get_sum_estimate, _from, cur_state) do
    [sum_state | [_ratio_q]] = cur_state
    [sum | [w]] = sum_state
    sum_estimate = sum/w
    {:reply, sum_estimate, cur_state}
  end

  def handle_call({:receive, re_sum, re_w}, _from, cur_state) do
    [sum_state | [ratio_q]] = cur_state
    [sum | [w]] = sum_state
    new_sum = sum + re_sum
    new_w = w + re_w
    {:reply, cur_state, [[new_sum, new_w], ratio_q]}
  end

  def handle_call({:send, rand_pid}, _from, cur_state) do
    [sum_state | [ratio_q]] = cur_state
    [sum | [w]] = sum_state
    up_sum = sum/2
    up_w = w/2
    updated_ratio_q = update_ratio_queue(ratio_q, up_sum, up_w)
    new_state = [[up_sum, up_w], updated_ratio_q]
    gossip_bundle = {rand_pid, up_sum, up_w}
    {:reply, gossip_bundle, new_state}
  end

  def handle_call(:send_alone, _from, cur_state) do
    [sum_state | [ratio_q]] = cur_state
    [sum | [w]] = sum_state
    up_sum = sum/2
    up_w = w/2
    updated_ratio_q = update_ratio_queue(ratio_q, up_sum, up_w)
    new_state = [[up_sum, up_w], updated_ratio_q]
    gossip_bundle = {nil, up_sum, up_w}
    {:reply, gossip_bundle, new_state}
  end

  def update_ratio_queue(ratio_q, up_sum, up_w) do
    cur_ratio = up_sum/up_w
    len = :queue.len(ratio_q)
    if len<3 do
      :queue.in(cur_ratio, ratio_q)
    else
      {_, ratio_q} = :queue.out(ratio_q)
      :queue.in(cur_ratio, ratio_q)
    end
  end

end
