defmodule Topology.Full do

	def get_Neighbours(gossip_actors) do
		mapped_neighbours = Enum.reduce(gossip_actors, %{}, fn(actor, mapped_neighbours) ->
			neighbours = compute_neighbours(actor, gossip_actors)
			Map.put(mapped_neighbours, actor, neighbours)
		end)
	end

	def compute_neighbours(mainactor, gossip_actors) do
		neighbours = Enum.reduce(gossip_actors, [], fn(actor, neighbours) ->
			neighbours = if (mainactor != actor) do
							[actor|neighbours]

						else
							neighbours
			end

		end)
	end

end
