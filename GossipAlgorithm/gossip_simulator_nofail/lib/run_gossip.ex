defmodule RunGossip do

  def trigger_gossip(gossip_actors, actor_to_neighbours) do

    IO.puts "Start Gossip Daenerys is Mad Queen"
    black_list =  MapSet.new()
    start_gossip(gossip_actors, actor_to_neighbours,black_list)

  end

  def isActorAlive(actor_pid, black_list) do
    !MapSet.member?(black_list, actor_pid)
  end

  def terminate_process(actor_pid, gossip_actors, actor_to_neighbours, black_list) do

    black_list = MapSet.put(black_list, actor_pid)

    actor_to_neighbours = Map.delete(actor_to_neighbours, actor_pid)

    gossip_actors = List.delete(gossip_actors, actor_pid)

    {gossip_actors, actor_to_neighbours, black_list}
  end

  def check_for_termination(count) do
    if count > 9 do
      true
    else
      false
    end
  end

  def start_gossip(gossip_actors, actor_to_neighbours, black_list) do

    info = Enum.reduce(gossip_actors, {}, fn(actor_pid, info) ->
        gossip_neighbour_pid = Algorithm.Gossip.send(actor_pid, actor_to_neighbours[actor_pid], black_list)

        {gossip_actors, actor_to_neighbours, black_list}  = if gossip_neighbour_pid != 0 do
          Algorithm.Gossip.receive(gossip_neighbour_pid)
          gossip_count = Algorithm.Gossip.getCount(gossip_neighbour_pid)


          terminate = check_for_termination(gossip_count)
          {gossip_actors, actor_to_neighbours, black_list} = if(terminate) do
            terminate_process(gossip_neighbour_pid, gossip_actors, actor_to_neighbours, black_list)
          else
           {gossip_actors, actor_to_neighbours, black_list}
          end
        else
          {gossip_actors, actor_to_neighbours, black_list} = terminate_process(actor_pid, gossip_actors, actor_to_neighbours, black_list)

        end

        len_gossip_actor = Kernel.length(gossip_actors)
        if(len_gossip_actor != 1) do
          {gossip_actors, actor_to_neighbours, black_list}
        else
          1
        end
     end)

     if (info == 1) do

     else
      {gossip_actors, actor_to_neighbours, black_list} = info

      start_gossip(gossip_actors, actor_to_neighbours, black_list)
     end

  end
end
