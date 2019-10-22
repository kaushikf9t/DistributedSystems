defmodule RunPushSum do
  def start_push_sum(actor_to_neighbours) do
    black_list =  MapSet.new()
    all_actors = List.to_tuple(Map.keys(actor_to_neighbours))
    starting_actor = elem(all_actors, 0)
    gossip_bundle = Algorithm.PushSum.send(starting_actor, actor_to_neighbours[starting_actor], black_list)
    actor_to_neighbours = start_gossip(gossip_bundle, actor_to_neighbours,black_list, 0)
  end

  def start_gossip(gossip_bundle, actor_to_neighbours, black_list, c) do
    {actor_pid, re_sum, re_w} = gossip_bundle
    # to handle no connectivity at all in random 2d grid
    actor_pid = if(actor_pid) do
      Algorithm.PushSum.receive(actor_pid, re_sum, re_w)
      actor_pid
    else
      actor_pid = Enum.random(Map.keys(actor_to_neighbours))
      Algorithm.PushSum.receive(actor_pid, re_sum, re_w)
      actor_pid
    end
    # condition handling ends
    gossip_bundle = Algorithm.PushSum.send(actor_pid, actor_to_neighbours[actor_pid], black_list)
    ratio_q = Algorithm.PushSum.get_ratio_queue(actor_pid)
    terminate = check_for_termination(ratio_q)
    {actor_to_neighbours, black_list} = if(terminate) do
      termiante_process(actor_pid, actor_to_neighbours, black_list)
    else
      {actor_to_neighbours, black_list}
    end
    actor_to_neighbours = if (map_size(actor_to_neighbours)>0) do
      chosen_one = elem(gossip_bundle, 0)
      if(chosen_one==nil) do
        new_chosen_one = Enum.random(Map.keys(actor_to_neighbours))
        gossip_bundle = put_elem(gossip_bundle, 0, new_chosen_one)
        actor_to_neighbours = start_gossip(gossip_bundle, actor_to_neighbours, black_list, c+1)
      else
        actor_to_neighbours = start_gossip(gossip_bundle, actor_to_neighbours, black_list, c+1)
      end
    else
      actor_to_neighbours
    end
  end

  def check_for_termination(ratio_q) do
    len = :queue.len(ratio_q)
    threshold = 0.0000000001  # 9 zeroes
    if len<3 do
      false
    else
      {value, ratio_q} = :queue.out(ratio_q)
      first_ratio = elem(value,1)
      {value, ratio_q} = :queue.out(ratio_q)
      second_ratio = elem(value,1)
      {value, ratio_q} = :queue.out(ratio_q)
      third_ratio = elem(value,1)
      diff1 = abs(first_ratio-second_ratio)
      diff2 = abs(second_ratio-third_ratio)
      if ((diff1<threshold) && (diff2<threshold)) do
        true
      else
        false
      end
    end
  end

  def termiante_process(actor_pid, actor_to_neighbours, black_list) do
    black_list = MapSet.put(black_list, actor_pid)
    actor_to_neighbours = Map.delete(actor_to_neighbours, actor_pid)
    {actor_to_neighbours, black_list}
  end

end
