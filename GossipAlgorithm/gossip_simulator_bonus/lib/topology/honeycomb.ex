defmodule Topology.Honeycomb do
	def buildTopology(actors) do
		num_nodes = Enum.count(actors)

		nodePIDMap = 1..length(actors) |> Stream.zip(actors) |> Enum.into(%{})
		instMoves = Map.new()
		{instMoves, actualMoves} = initMaps
		#Num_nodes 0 or just 1
		coord_list = []
		coordIDMap = Map.new()
		coord_list = [{0,0} | coord_list]
		coordIDMap = Map.put(coordIDMap, 1, coord_list)
		result = generateTopology(num_nodes, 0, 0, :start, coord_list, %{}, coordIDMap , 1,instMoves, actualMoves)
		neighborsMap = elem(result, 1)
		pidNeighborsMap = Enum.reduce(neighborsMap, %{}, fn({k,v}, acc) ->
			pid = Map.get(nodePIDMap, k)
			v = Enum.reduce(v, [], fn(x, list) ->
				list = [Map.get(nodePIDMap, x) | list] end)
			acc = Map.put(acc, pid, v) 
		end)
		pidNeighborsMap
	end

	def generateTopology(num_nodes, x, y, move, coord_list, acc, coordIDMap, actorNumber, instMoves, actualMoves) when actorNumber > num_nodes do
		result = {coord_list, acc}
	end

	#Add neighbors logic
	#If actor + 1 < num_actors 
	#Have a list called neighbors, store IDs for now
	#map that to the accumulator
	#Make sure to have actors startung with ID one
	def generateTopology(num_nodes, x, y, move, coord_list, acc, coordIDMap, actorNumber, instMoves, actualMoves) do
		coord = {x,y}
		coordIDMap = Map.put(coordIDMap, actorNumber, coord)
		if get_successor(actorNumber, num_nodes) != nil do
			nextMove = Map.get(instMoves, move)
			nextCoord = get_coord(nextMove, elem(coord,0), elem(coord,1))
			currentNodeNeighbors = []
			#Check if the coordinates already exist
			if Enum.member?(coord_list, nextCoord) do
				neighborID = Enum.reduce(coordIDMap, 0, fn({k,v}, key) ->
				if v == nextCoord, do: key = key + k, else: key end)
			 	currentNodeNeighbors = [neighborID|currentNodeNeighbors]
			 	list = [actorNumber|Map.get(acc, neighborID)]
			 	acc = Map.put(acc, neighborID, list)#put 6 to 1's list
			 	acc = Map.put(acc, actorNumber, currentNodeNeighbors)# put 1 to 6's list
			 	
			 	#This is to add actor 7
			 	actualMove = Map.get(actualMoves, nextMove)
			 	nextCoord = get_coord(actualMove, elem(coord,0), elem(coord,1))
			 	actNeighborID = get_successor(actorNumber, num_nodes)
			 	currentNodeNeighbors = [actNeighborID|currentNodeNeighbors]
			 	predID = get_predecessor(actorNumber, 1)
			 	currentNodeNeighbors = [predID|currentNodeNeighbors]
			 	acc = Map.put(acc, actorNumber, currentNodeNeighbors)
			 	#IO.inspect acc
			 	coord_list = [nextCoord|coord_list]
			 	#IO.inspect coord_list
			 	generateTopology(num_nodes, elem(nextCoord,0) , elem(nextCoord,1) , actualMove, coord_list, acc, coordIDMap, actorNumber+1, instMoves, actualMoves)

			else 
				neighborID = get_successor(actorNumber, num_nodes)
				predID = get_predecessor(actorNumber, 1)
				
				currentNodeNeighbors = [neighborID|currentNodeNeighbors]
				currentNodeNeighbors = if predID != nil, do: [predID|currentNodeNeighbors], else: currentNodeNeighbors 	
				acc = Map.put(acc, actorNumber, currentNodeNeighbors)
				
				coord_list = [nextCoord|coord_list]
				#IO.inspect acc
				#IO.inspect coord_list
				generateTopology(num_nodes, elem(nextCoord,0) , elem(nextCoord,1) , nextMove, coord_list, acc, coordIDMap, actorNumber+1, instMoves, actualMoves)
			end	
		else
			coord = {x,y}
			coordIDMap = Map.put(coordIDMap, actorNumber, coord)
			predID = get_predecessor(actorNumber, 1)
			nextMove = Map.get(instMoves, move)
			nextCoord = get_coord(nextMove, elem(coord,0), elem(coord,1))
			currentNodeNeighbors = []
			if Enum.member?(coord_list, nextCoord) do
				neighborID = Enum.reduce(coordIDMap, 0, fn({k,v}, key) ->
				if v == nextCoord, do: key = key + k, else: key end)
								
				currentNodeNeighbors = [neighborID|currentNodeNeighbors]
				currentNodeNeighbors = [predID|currentNodeNeighbors]
				acc = acc = Map.put(acc, actorNumber, currentNodeNeighbors)
				list = [actorNumber|Map.get(acc, neighborID)]
				acc = Map.put(acc, neighborID, list)
				generateTopology(num_nodes, 0,0, nil, coord_list, acc, coordIDMap, actorNumber+1, instMoves, actualMoves)
			else
				currentNodeNeighbors = [predID|currentNodeNeighbors]
				acc = Map.put(acc, actorNumber, currentNodeNeighbors)
				generateTopology(num_nodes, 0,0, nil, coord_list, acc, coordIDMap, actorNumber+1, instMoves, actualMoves)
			end 

		end

		# if Map.get(acc,{x,y}) do
		# 	IO.puts "#{Map.get(acc,{x,y})}"
		# end

		# IO.puts "x=#{x} y=#{y}"
		# generateTopology(x+1 , y+1 ,acc, actorNumber + 1)
	end

	def initMaps do
		instMoves = Map.new()
		instMoves = Map.put_new(instMoves, :start, :go_east)
		instMoves = Map.put_new(instMoves, :go_east, :go_southeast)
		instMoves = Map.put_new(instMoves, :go_southeast, :go_southwest)
		instMoves = Map.put_new(instMoves, :go_southwest, :go_west)
		instMoves = Map.put_new(instMoves, :go_west, :go_northwest)
		instMoves = Map.put_new(instMoves, :go_northwest, :go_northeast)
		instMoves = Map.put_new(instMoves, :go_northeast, :go_east)

		actualMoves = Map.new()
		actualMoves = Map.put_new(actualMoves, :go_northeast, :go_west)
		actualMoves = Map.put_new(actualMoves, :go_southeast, :go_northeast)
		actualMoves = Map.put_new(actualMoves, :go_southwest, :go_east)
		actualMoves = Map.put_new(actualMoves, :go_west, :go_southeast)
		actualMoves = Map.put_new(actualMoves, :go_northwest, :go_southwest)
		actualMoves = Map.put_new(actualMoves, :go_east, :go_northwest)

		{instMoves,actualMoves}

	end
	
	#Pass the actors in future
	def get_successor(cur_id, num_actors) do
    	if cur_id != num_actors, do: cur_id + 1 
   	end

   	def get_predecessor(cur_id, start) do
    	if cur_id > 1, do: cur_id - 1 
   	end

	def get_coord(dir, x, y) do
		case dir do
			:go_north -> {c1,c2} = go_north(x,y)
			:go_south -> {c1,c2} = go_south(x,y)
			:go_east ->  {c1,c2} = go_east(x,y)
			:go_west -> {c1,c2} = go_west(x,y)
			:go_southwest -> {c1,c2} = go_southwest(x,y)
			:go_southeast -> {c1,c2} = go_southeast(x,y)
			:go_northeast -> {c1,c2} = go_northeast(x,y)
			:go_northwest -> {c1,c2} = go_northwest(x,y)
		end
	end

	def go_southeast(x,y)do
		coord1 = x+1
		coord2 = y-1
		{coord1, coord2}
	end
	def go_southwest(x,y)do
		coord1 = x-1
		coord2 = y-1
		{coord1, coord2}
	end
	def go_northeast(x,y)do
		coord1 = x+1
		coord2 = y+1
		{coord1, coord2}
	end
	def go_northwest(x,y)do
		coord1 = x-1
		coord2 = y+1
		{coord1, coord2}
	end

	def go_north(x,y)do
		coord1 = x
		coord2 = y+1
		{coord1, coord2}
	end

	def go_south(x,y)do
		coord1 = x
		coord2 = y-1
	end

	def go_east(x,y)do
		coord1 = x+1
		coord2 = y
		{coord1, coord2}
	end
	def go_west(x,y)do
		coord1 = x-1
		coord2 = y
		{coord1, coord2}
	end
end

