defmodule Pastry do
  alias Pastry.Network
  alias Peers.Tables

  def main(args) do
    case length(args) do
      1 ->[num] = args
          {num,_} = Integer.parse(num)
          max_requests = 1
          failure_percentage = 0
          main(num, max_requests, failure_percentage)

      2 -> 
        [num, max_requests] = args
        {num,_} = Integer.parse(num)
        {max_requests,_} = Integer.parse(max_requests)
        failure_percentage = 0 
        main(num, max_requests, failure_percentage)
      3 ->
        [num, max_requests, failure_percentage] = args 
        {num,_} = Integer.parse(num)
        {max_requests,_} = Integer.parse(max_requests)
        {failure_percentage,_} = Integer.parse(failure_percentage)
        main(num, max_requests, failure_percentage)
      _ -> IO.puts("Please recheck your arguments")
    end
    
  end

  def main( num , max_requests \\ 1, failure_percentage \\ 0) do
    rows = 
      case round(:math.ceil(:math.log(num) / :math.log(16))) do
        0 -> 1 
        rows -> rows
      end
    IO.puts "Number of Requests: #{inspect(max_requests)}"
    failed_nodes = round(num*failure_percentage/100)
    my_bin = bin(rows,[""], String.split("0123456789ABCDEF","", trim: true) ++ [""])
    init_network (%Network{num: num, my_bin: my_bin, rows: rows, failed_nodes: failed_nodes})
    Process.sleep(:infinity)

  end

  def init_network( %Network{ num: num, my_bin: my_bin, rows: rows } = network ) do
    GenServer.start_link(Pastry, %Network{ network| main_pid: self()}, name: MyServer)
    row_empty_lists = mk_empty_row(Map.new(),"0123456789ABCDEF")
    peers =
      for x <- 1..num do
        peer = hash_input("#{inspect x}")
        GenServer.start(Peers, %Network{ network | peer: peer, row_empty_lists: row_empty_lists} , name: peer)
        GenServer.cast( MyServer, {:update_bin, peer})
        peer
      end
    sp = Enum.sort(peers, fn(x,y) -> 
      {v1, _} = Integer.parse(to_string(x), 16)
      {v2, _} = Integer.parse(to_string(y), 16) 
      v1<v2 
    end)
    GenServer.cast(MyServer, {:update_sorted_peers, sp})
    for peer <- sp do
      GenServer.cast(peer,{:start_updating, 1})
    end
  end
  
  #Server 
  def init(network) do
    {:ok,network}
  end

  def handle_cast({:update_sorted_peers, sp}, network) do
    spm = sp|>Enum.with_index(0)|>Enum.map(fn {k,v}->{k,v} end) |> Map.new
    {:noreply, %Network{ network | sorted_peers: sp , sorted_peers_map: spm}}
  end

  def handle_cast({:trial_count, [hops, request_num]}, %Network{last_request: l,num: num,max_requests: requests, trial_count: c, total_hops: h, print: print, max_hops: m} = network) do
    l = 
    case request_num > l do
      true -> 
        request_num
      false -> 
        l
    end

    print =
      case print == 1 and requests == l and (c+1)/num > 0.98 do
        true -> 
          Process.sleep(1000)
          IO.puts "Max hops: #{inspect(m)}"
          GenServer.cast(MyServer,{:end_everything,1})
          0
        false -> print
      end  
    {:noreply, %Network{ network | last_request: l, print: print, trial_count: c+1, total_hops: h+hops , max_hops: Kernel.max(hops, m)}}
  end

  def handle_cast({:update_bin, peer}, %Network{ my_bin: my_bin, rows: rows} = network) do
    peer_string = to_string(peer)
    my_bin = update_bin(peer_string,peer,rows,my_bin)
    {:noreply, %Network{ network | my_bin: my_bin }}
  end

  def handle_cast({:end_everything,_}, %Network{main_pid: pid} = network) do
    Process.sleep(3000)
    Process.exit(pid,:kill)
    {:noreply, network}
  end

  def handle_cast({:request_tables, %Tables{ routing_table: rt, self_atom: peer} = tables},
                 %Network{ my_bin: my_bin, failed_nodes: failed_nodes, sorted_peers: sp, sorted_peers_map: spm, num: num, table_updated_peers: tup} = network) do  
    ready_rt = fill_rt_table(rt,my_bin,Map.keys(rt),peer)
    GenServer.cast(peer,{:ready_tables,  %Tables{tables | routing_table: ready_rt}})
    case tup+1 == num do
      true -> IO.puts "Peers will now start SENDING REQUESTS...\n"
        num =
        case failed_nodes != 0 do
          true -> 
            IO.puts "TESTING: #{failed_nodes} of #{num} nodes intentionally killed\nThe process will continue as normal\n---------------------------------------------"
            for node <- Enum.take_random(sp,failed_nodes) do
              Process.exit(Process.whereis(node), :kill)
            end
            num = num - failed_nodes
          false-> num
        end
      
        for peer <- sp do
          GenServer.cast(peer,{:start_requesting, 1})
        end
      false -> ""
    end
    {:noreply,  %Network{ network | num: num,table_updated_peers: tup + 1 }}
  end

  def fill_rt_table(rt, my_bin, [r|rows], self ) do
    updated_row = fill_rt_table_row( my_bin,r, rt[r], String.split("0123456789ABCDEF","", trim: true),self)
    case rows do
      []->Map.replace(rt, r, updated_row)
      _ ->fill_rt_table(Map.replace(rt, r, updated_row),my_bin, rows,self)
    end
  end

  def fill_rt_table_row(my_bin,r,row, [c|columns], self) do
    {:ok,list} = Map.fetch(my_bin, r<>c)
    peer = 
      case Enum.empty?(List.delete(list,self)) do
        true -> nil
        false -> Enum.random(List.delete(list,self))
      end      
    case columns do
      []->Map.replace(row, c, peer)
      _ ->fill_rt_table_row(my_bin, r,Map.replace(row,c,peer), columns, self)
    end
  end

  def update_bin(peer_string,peer, sz, my_bin) do
    case sz do
      0 -> my_bin
      sz ->
        prefix =  String.slice(peer_string, 0..sz-1)
        {:ok,value} = Map.fetch(my_bin, prefix)
        new_bin = Map.replace(my_bin, prefix, value ++ [peer])
        update_bin(peer_string,peer,sz-1, new_bin)
    end
  end

  def hash_input(input) do 
    {_,value} = 
      :crypto.hash(:sha,input)    
      |> Base.encode16
      |> String.split_at(-10)
    value |> String.to_atom
  end

  def bin(rows, my_bin, add) do
    case rows do
      0 ->
        Map.new(my_bin, fn x -> {x, []} end)
      _ ->       
        new_bin = 
          for x <- my_bin , y <- add do
            x<>y
          end
        new_bin = List.delete(new_bin, "")
        bin(rows - 1, new_bin, add)
    end
  end

  def mk_empty_row(row,list) do
    <<h::bytes-size(1)>> <> string = list
    case string do
      "" -> Map.put( row, h, nil)
      _ -> row = Map.put( row, h, nil)
        mk_empty_row(row, string)
    end    
  end
end
