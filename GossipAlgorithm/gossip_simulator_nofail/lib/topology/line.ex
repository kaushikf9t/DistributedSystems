defmodule Topology.Line do

  def generate_topology(gossip_actors) do
    gossip_actors_tuple = List.to_tuple(gossip_actors)
    actors_len = length(gossip_actors)
    actor_to_neighbour = Enum.reduce((0..actors_len-1), %{}, fn(actor_idx, actor_to_neighbour) ->
      actor = elem(gossip_actors_tuple, actor_idx)
      successor = get_successor(gossip_actors_tuple, actor_idx)
      predecessor = get_predecessor(gossip_actors_tuple, actor_idx)
      neighbours = [successor, predecessor]
      # neighbours = if type==:imperfect do
      #   random_neighbour = get_random_neighbour(gossip_actors, actor, successor, predecessor)
      #   [random_neighbour | neighbours]
      # else
      #   neighbours
      # end
      neighbours = Enum.reject(neighbours, &is_nil/1)
      Map.put(actor_to_neighbour, actor, neighbours)
    end)
    actor_to_neighbour
  end

  def get_successor(actors, cur_idx) do
    if cur_idx != tuple_size(actors)-1, do: elem(actors, cur_idx+1)
  end

  def get_predecessor(actors, cur_idx) do
    if cur_idx != 0, do: elem(actors, cur_idx-1)
  end

  def get_random_neighbour(actors, actor, successor, predecessor) do
    sans_neighbours = actors -- [actor, successor, predecessor]
    Enum.random(sans_neighbours)
  end

end
