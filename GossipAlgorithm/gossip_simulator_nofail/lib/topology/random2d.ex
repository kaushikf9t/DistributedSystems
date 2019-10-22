defmodule Topology.Random2D do

	def get_Neighbours(gossip_actors) do
		list_coord = []
		Enum.map(gossip_actors, fn(pid) ->
		x = (Enum.random(1..10))/10
		y = (Enum.random(1..10))/10
		list_coord = list_coord ++ [{pid, [x, y]}]
		end
		) |> map_Neighbours

	end

	def map_Neighbours(gossip_actors) do

		mappedNeighbours = Enum.reduce(gossip_actors, %{}, fn(actor, mappedNeighbours) ->
			valtup = Enum.at(actor, 0)
			pid = elem(valtup, 0)
			coord = elem(valtup, 1)
			x = Enum.at(coord, 0)
			y = Enum.at(coord, 1)
			neighbours = compute_Neighbours(pid, x, y, gossip_actors)
			Map.put(mappedNeighbours, pid, neighbours)
		end)

	end


def compute_Neighbours(pid, x, y, nodesList) do

	neighbours = Enum.reduce(nodesList, [], fn(node, neighbours) ->
		valtup = Enum.at(node, 0)
      	pid1 = elem(valtup, 0)
      	coord = elem(valtup, 1)
      	x1 = Enum.at(coord, 0)
      	y1 = Enum.at(coord, 1)

      	x_sub = abs(x-x1)
      	y_sub = abs(y-y1)

      	neighbours = if (pid1 != pid) and (((x_sub <= 0.1) and (y_sub == 0)) or ((y_sub <= 0.1) and (x_sub == 0))) do
                       [pid1| neighbours]
        		    else
          			   neighbours
        		    end

	end)

end

end
