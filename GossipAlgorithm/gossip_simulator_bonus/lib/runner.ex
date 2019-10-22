defmodule Runner do
  def main(args) do
    [numNodesStr | [ topology | [algorithm | [failurePercentageStr | _]]]] = args
    {numNodes, ""} = Integer.parse(numNodesStr)
    numNodes=if String.contains?(topology,"sphere"), do: round(:math.pow(round(:math.sqrt(numNodes)),2)), else: numNodes
    {failurePercentage, ""} = Integer.parse(failurePercentageStr)
    start_algo(numNodes, topology, algorithm, failurePercentage)
  end

  defp start_algo(numNodes, topology, algorithm, failurePercentage) do
    failureCount = round((numNodes * failurePercentage)/100.0)
    IO.puts "Actors: #{numNodes}"
    gossip_actors = cond do
      String.downcase(algorithm) == "gossip" ->
        IO.puts "Algorithm: Gossip"
        Enum.reduce((1..numNodes), [], fn(_i, gossip_actors) ->
          {:ok, pid} = Algorithm.Gossip.start_link()
          [pid | gossip_actors]
        end)
      String.downcase(algorithm) == "push-sum" ->
        IO.puts "Algorithm: Push-Sum"
        Enum.reduce((1..numNodes), [], fn(i, gossip_actors) ->
          {:ok, pid} = Algorithm.PushSum.start_link(i)
          [pid | gossip_actors]
        end)
      true ->
        IO.puts "Invalid Algorithm"
    end

    actor_to_neighbours = cond do
      String.downcase(topology) == "honeycomb" ->
        IO.puts "Topology: Honeycomb"
        Topology.Honeycomb.buildTopology(gossip_actors)
     String.downcase(topology) == "randhoneycomb" ->
        IO.puts "Topology: Random Honeycomb"
        Topology.RandomHoneycomb.buildRandHoneycomb(gossip_actors)
      String.downcase(topology) == "full" ->
        IO.puts "Topology: Full Topology"
        Topology.Full.get_Neighbours(gossip_actors)
      String.downcase(topology) == "3dtorus" ->
        IO.puts "Topology: 3-D Grid"
        Topology.ThreeDTorus.generate_topology(gossip_actors)
      String.downcase(topology) == "rand2d" ->
        IO.puts "Topology: Random 2D Grid"
        Topology.Random2D.get_Neighbours(gossip_actors)
      String.downcase(topology) == "line" ->
        IO.puts "Topology: Line"
        Topology.Line.generate_topology(gossip_actors)
      true ->
        IO.puts "Invalid Topology"
    end

    #IO.puts "Actors are:"
    #IO.inspect gossip_actors
    #IO.puts "Actors to Neighbours Map:"
    #IO.inspect actor_to_neighbours
    #RunPushSum.start_push_sum(actor_to_neighbours)

    up_actor_to_neighbours = induce_failure(gossip_actors, actor_to_neighbours, failureCount)
    #IO.puts "Neighbourhood map after failure:"
    #IO.inspect up_actor_to_neighbours
    #IO.inspect map_size(up_actor_to_neighbours)
    IO.puts "Topology Created"
    IO.puts "Algorithm started"
    {time, _rem_map} = if(String.downcase(algorithm) == "gossip") do
      :timer.tc(RunGossip, :trigger_gossip, [gossip_actors, actor_to_neighbours])
    else
      :timer.tc(RunPushSum, :start_push_sum, [up_actor_to_neighbours])
    end
    #IO.puts "rem_map"
    #IO.inspect rem_map
    IO.puts "Converged!!"
    time = time/1000.0
    IO.puts "Summary:"
    IO.puts "Time Taken: #{time} milliseconds"
    connected_graph_size = map_size(up_actor_to_neighbours)
    IO.puts "Nodes converged: #{connected_graph_size}"
    failed_to_converge = numNodes - failureCount - connected_graph_size
    IO.puts "Nodes failed to converge: #{failed_to_converge}"
  end

  def induce_failure(gossip_actors, actor_to_neighbours, failureCount) do
    actors_to_fail = Enum.take_random(gossip_actors, failureCount)
    IO.puts "Failing #{failureCount} actors"
    #IO.puts "actors_to_fail"
    #IO.inspect actors_to_fail
    actor_to_neighbours = Enum.reduce(actors_to_fail, actor_to_neighbours, fn(act, acc)->
      Map.delete(acc, act)
    end)
    active_actors = Map.keys(actor_to_neighbours)
    actor_to_neighbours = Enum.reduce(active_actors, actor_to_neighbours, fn(act, acc)->
      working_list = Map.get(acc, act)
      new_working_list = MapSet.to_list(MapSet.difference(MapSet.new(working_list), MapSet.new(actors_to_fail)))
      Map.put(acc, act, new_working_list)
    end)
    #IO.puts "After deleteing"
    #IO.inspect actor_to_neighbours
    #actor_to_neighbours
    g = Graph.new |> Graph.add_vertices(active_actors)
    edges = Enum.reduce(active_actors, [], fn(act, acc)->
      connections = Map.get(actor_to_neighbours, act)
      two = Enum.reduce(connections, [], fn(nei, two)->
        [{act, nei} | two]
      end)
      two ++ acc
    end)
    #IO.puts "edges are:"
    #IO.inspect edges
    g = Graph.add_edges(g, edges)
    #IO.puts "graph is:"
    #IO.inspect g
    connected = Graph.strong_components(g)
    #IO.puts "connected graph is:"
    #IO.inspect connected
    #IO.puts "connected graph length is:"
    #IO.inspect length(connected)
    len_mapping = Enum.map(connected, fn(isolated_g)->
      length(isolated_g)
    end)
    #IO.puts "len mapping is:"
    #IO.inspect len_mapping
    max_len = Enum.max(len_mapping)
    #IO.puts "max_len is:"
    #IO.inspect max_len
    max_len_idx = Enum.find_index(len_mapping, fn x -> x == max_len end)
    #IO.puts "max_len_idx is:"
    #IO.inspect max_len_idx
    largest_graph = Enum.at(connected, max_len_idx)
    #IO.puts "largest_graph is:"
    #IO.inspect largest_graph
    new_neighbour_list = Enum.reduce(largest_graph, %{}, fn(l_g_ele, acc)->
      working_list = Map.get(actor_to_neighbours, l_g_ele)
      Map.put(acc, l_g_ele, working_list)
    end)
    #IO.puts "final is:"
    #IO.inspect new_neighbour_list
    #IO.inspect map_size(new_neighbour_list)
    new_neighbour_list
  end
end
