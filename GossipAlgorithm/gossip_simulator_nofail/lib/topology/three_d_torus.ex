defmodule Topology.ThreeDTorus do

  def generate_topology(gossip_actors) do
    gossip_actors_tuple = List.to_tuple(gossip_actors)
    actors_size = length(gossip_actors)
    {is_perfect , dim} = get_perfect_cube(actors_size)
    grid = generate_and_fill_perfect_space(gossip_actors_tuple, dim)
    expanded_grid = unless is_perfect do
      idx_covered = Kernel.trunc(:math.pow(dim,3))
      rem_actors = Enum.reduce((idx_covered..actors_size-1), [], fn(x, rem_actors) ->
        [elem(gossip_actors_tuple, x) | rem_actors]
      end)
      expand_space(grid, List.to_tuple(rem_actors), dim)
    else
      grid
    end
    #IO.inspect expanded_grid
    get_neighbours(expanded_grid)
  end

  def get_perfect_cube(actors_size) do
    cube_root = :math.pow(actors_size,1/3)
    rounded_cube_root = Kernel.trunc(cube_root)
    if (rounded_cube_root == cube_root) do
      {true, rounded_cube_root}
    else
      {false, rounded_cube_root}
    end
  end

  def generate_and_fill_perfect_space(gossip_actors, dim_len) do
    dim = (1..dim_len)
    grid = Enum.reduce(dim, %{}, fn(xi, x)->
      xi_val = Enum.reduce(dim, %{}, fn(yi, y)->
        yi_val = Enum.reduce(dim, %{}, fn(zi, z)->
          idx = zi + (dim_len*(yi-1)) + ((dim_len * dim_len) * (xi-1))
          Map.put(z, zi, elem(gossip_actors, idx-1))
        end)
        Map.put(y, yi, yi_val)
      end)
      Map.put(x, xi, xi_val)
    end)
    grid
  end

  def expand_space(grid, rem_actors, dim_len) do
    # IO.puts "Rem Actors:#{inspect rem_actors}"
    old_dim = (1..dim_len)
    new_dim = (1..dim_len+1)
    tuple_limit = tuple_size(rem_actors) -1
    expanded_grid = Enum.reduce(old_dim, %{}, fn(xi, x)->
      xi_val = Enum.reduce(old_dim, %{}, fn(yi, y)->
        idx = (dim_len*(xi-1)) + yi-1
        actor = if idx<=tuple_limit, do: elem(rem_actors, idx), else: nil
        yi_val = Map.put(grid[xi][yi], dim_len+1,  actor)
        Map.put(y, yi, yi_val)
      end)
      new_y = Enum.reduce(new_dim, %{}, fn(zi, z)->
        idx = (dim_len*dim_len) + ((dim_len+1)*(xi-1)) + zi-1
        actor = if idx<=tuple_limit, do: elem(rem_actors, idx), else: nil
        Map.put(z, zi, actor)
      end)
      xi_val = Map.put(xi_val, dim_len+1, new_y)
      Map.put(x, xi, xi_val)
    end)
    new_len = dim_len+1
    xi_val = Enum.reduce(new_dim, %{}, fn(yi, y)->
      yi_val = Enum.reduce(new_dim, %{}, fn(zi, z)->
        idx = (dim_len*(dim_len+dim_len)) +  dim_len + (new_len*(yi-1)) + zi-1
        actor = if idx<=tuple_limit, do: elem(rem_actors, idx), else: nil
        Map.put(z, zi, actor)
      end)
      Map.put(y, yi, yi_val)
    end)
    Map.put(expanded_grid, dim_len+1,  xi_val)
  end

  def getFirstInRow(xyz, x, y, z, grid) when xyz == "basKar" do
    grid[x][y][z]
  end

  def getFirstInRow(xyz, _x, _y, _z, _grid) when xyz == "rehnDe" do
    nil
  end

  def getFirstInRow(xyz, x, y, z, grid) do
    if grid[x][y][z] do
      getFirstInRow("basKar", x, y, z, grid)
    else
      case xyz do
        "x" ->
          # IO.puts "In getFristInRow xyz: #{xyz}, xi:#{x}, yi:#{y}, zi:#{z}"
          if x==map_size(grid) do
            getFirstInRow("rehnDe", x, y, z, grid)
          else
            getFirstInRow("x", x+1, y, z, grid)
          end

        "y" ->
          # IO.puts "In getFristInRow xyz: #{xyz}, xi:#{x}, yi:#{y}, zi:#{z}"
          if y==map_size(grid) do
            getFirstInRow("rehnDe", x, y, z, grid)
          else
            getFirstInRow("y", x, y+1, z, grid)
          end

        "z" ->
          # IO.puts "In getFristInRow xyz: #{xyz}, xi:#{x}, yi:#{y}, zi:#{z}"
          if z==map_size(grid) do
            getFirstInRow("rehnDe", x, y, z, grid)
          else
            getFirstInRow("z", x, y, z+1, grid)
          end
      end
    end
  end

  def getLastInRow(xyz, x, y, z, grid) when xyz == "basKar" do
    grid[x][y][z]
  end

  def getLastInRow(xyz, _x, _y, _z, _grid) when xyz == "rehnDe" do
    nil
  end

  def getLastInRow(xyz, x, y, z, grid) do
    if grid[x][y][z] do
      getLastInRow("basKar", x, y, z, grid)
    else
      case xyz do
        "x" ->
          # IO.puts "In getLastInRow xyz: #{xyz}, xi:#{x}, yi:#{y}, zi:#{z}"
          if x==0 do
            getLastInRow("rehnDe", x, y, z, grid)
          else
            getLastInRow("x", x-1, y, z, grid)
          end

        "y" ->
          # IO.puts "In getLastInRow xyz: #{xyz}, xi:#{x}, yi:#{y}, zi:#{z}"
          if y==0 do
            getLastInRow("rehnDe", x, y, z, grid)
          else
            getLastInRow("y", x, y-1, z, grid)
          end

        "z" ->
          # IO.puts "In getLastInRow xyz: #{xyz}, xi:#{x}, yi:#{y}, zi:#{z}"
          if z==0 do
            getLastInRow("rehnDe", x, y, z, grid)
          else
            getLastInRow("z", x, y, z-1, grid)
          end
      end
    end
  end

  def get_neighbours(grid) do
    dim = (1..map_size(grid))
    neighbour_map_x = Enum.reduce(dim, %{}, fn(xi, neighbour_map_x)->
      neighbour_map_y = Enum.reduce(dim, %{}, fn(yi, neighbour_map_y)->
        neighbour_map_z = Enum.reduce(dim, %{}, fn(zi, neighbour_map_z)->
          cur = grid[xi][yi][zi]
          if(cur) do
            neighbours = []

            #### X-Neighbours ####
            neighbours = if grid[xi+1][yi][zi] do
                [grid[xi+1][yi][zi] | neighbours]
              else
                foundNeighbour = getFirstInRow("x", 0, yi, zi, grid)
                if foundNeighbour == nil do
                  neighbours
                else
                  [foundNeighbour | neighbours]
                end
              end

            neighbours = if grid[xi-1][yi][zi] do
                [grid[xi-1][yi][zi] | neighbours]
              else
                foundNeighbour = getLastInRow("x", map_size(grid), yi, zi, grid)
                if foundNeighbour == nil do
                  neighbours
                else
                  [foundNeighbour | neighbours]
                end
              end

            #### Y-Neighbours ####
            neighbours = if grid[xi][yi+1][zi] do
                [grid[xi][yi+1][zi] | neighbours]
              else
                foundNeighbour = getFirstInRow("y", xi, 0, zi, grid)
                if foundNeighbour == nil do
                  neighbours
                else
                  [foundNeighbour | neighbours]
                end
              end

            neighbours = if grid[xi][yi-1][zi] do
                [grid[xi][yi-1][zi] | neighbours]
              else
                foundNeighbour = getLastInRow("y", xi, map_size(grid), zi, grid)
                if foundNeighbour == nil do
                  neighbours
                else
                  [foundNeighbour | neighbours]
                end
              end

            #### Z-Neighbours ####
            neighbours = if grid[xi][yi][zi+1] do
                [grid[xi][yi][zi+1] | neighbours]
              else
                foundNeighbour = getFirstInRow("z", xi, yi, 0, grid)
                if foundNeighbour == nil do
                  neighbours
                else
                  [foundNeighbour | neighbours]
                end
              end
            neighbours = if grid[xi][yi][zi-1] do
                [grid[xi][yi][zi-1] | neighbours]
              else
                foundNeighbour = getLastInRow("z", xi, yi, map_size(grid), grid)
                if foundNeighbour == nil do
                  neighbours
                else
                  [foundNeighbour | neighbours]
                end
              end
            # IO.puts "cur and neighbours values"
            # IO.puts "#{xi},#{yi},#{zi}"
            # IO.inspect cur
            # IO.inspect neighbours
            Map.put(neighbour_map_z, cur, neighbours)
          else
            neighbour_map_z
          end
        end)
        #IO.puts "my map neighbour_map_z"
        #IO.inspect neighbour_map_z
        Map.merge(neighbour_map_y, neighbour_map_z)
      end)
      #IO.puts "my map neighbour_map_y"
      #IO.inspect neighbour_map_y
      Map.merge(neighbour_map_x, neighbour_map_y)
    end)
    #IO.puts "my map neighbour_map_x"
    #IO.inspect neighbour_map_x
    neighbour_map_x
  end

end
