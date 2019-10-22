defmodule Runner do
  def main(args) do
    [numNodesStr | [ topology | [algorithm | _]]] = args
    {numActors, ""} = Integer.parse(numNodesStr)
    executeAlgorithm(numActors, topology, algorithm)
  end

  defp executeAlgorithm(numNodes, topology, algorithm) do
    IO.puts "Actors: #{numNodes}"
    gossip_actors = cond do
      String.downcase(algorithm) == "gossip" ->
        IO.puts "Algorithm: Gossip"
        Enum.reduce((1..numNodes), [], fn(i, gossip_actors) ->
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

    neighborActors = cond do
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
        IO.puts "Topology: 3-D Torus Grid"
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
    IO.puts "Topology Created"
    IO.puts "Algorithm started"
    {time, _} = if(String.downcase(algorithm) == "gossip") do
      :timer.tc(RunGossip, :trigger_gossip, [gossip_actors, neighborActors])
    else
      :timer.tc(RunPushSum, :start_push_sum, [neighborActors])
    end
    IO.puts "Completed Convergence"
    time = time/1000.0
    IO.puts "Time : #{time} milliseconds"
  end

end
