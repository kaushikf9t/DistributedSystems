defmodule Topology.RandomHoneycomb do

	def buildRandHoneycomb(actors) do
		num_nodes = Enum.count(actors)
		nodePIDMap = 1..length(actors) |> Stream.zip(actors) |> Enum.into(%{})
		instMoves = Map.new()
		{instMoves, actualMoves} = Topology.Honeycomb.initMaps()
		# IO.inspect instMoves
		coord_list = []
		coordIDMap = Map.new()
		coord_list = [{0,0} | coord_list]
		coordIDMap = Map.put(coordIDMap, 1, coord_list)
		honeycombNeighbors = elem(Topology.Honeycomb.generateTopology(num_nodes, 0, 0, :start, coord_list, %{}, coordIDMap , 1, instMoves, actualMoves), 1)
		neighborsMap = generateRandHoneycomb(num_nodes, honeycombNeighbors, %{}, 1)

		pidNeighborsMap = Enum.reduce(neighborsMap, %{}, fn({k,v}, acc) ->
			pid = Map.get(nodePIDMap, k)
			v = Enum.reduce(v, [], fn(x, list) ->
				list = [Map.get(nodePIDMap, x) | list] end)
			acc = Map.put(acc, pid, v)
		end)
		pidNeighborsMap

	end

	def getNewRandomNeighbor(currentNeighbors, num_nodes) do
		randNeighbor = Enum.random(1..num_nodes)
		randNeighbor = if Enum.member?(currentNeighbors, randNeighbor) == false, do: randNeighbor , else: getNewRandomNeighbor(currentNeighbors, num_nodes)
	end

	def generateRandHoneycomb(num_nodes, honeycombNeighbors, acc, actorNumber) when actorNumber > num_nodes do
		acc
	end

	def generateRandHoneycomb(num_nodes, honeycombNeighbors, acc, actorNumber) do
		currentNeighbors = Map.get(honeycombNeighbors, actorNumber)
		randNeighbor = getNewRandomNeighbor(currentNeighbors, num_nodes)
		currentNeighbors = [randNeighbor|currentNeighbors]
		acc = Map.put(acc, actorNumber, currentNeighbors)
		generateRandHoneycomb(num_nodes, honeycombNeighbors, acc, actorNumber+1)

	end

end
