defmodule Peers do
  alias Pastry.Network
  alias Pastry.Message
  alias Peers.Tables

  def init(%Network{ my_bin: my_bin, rows: rows, peer: peer, row_empty_lists: row_empty_lists, max_requests: mr} = network) do
    Process.flag(:trap_exit, true)
    rt = mk_empty_rt(Map.new(),rows - 1,row_empty_lists,to_string(peer))
    {:ok, %Tables{ routing_table: rt, self: to_string(peer), self_atom: peer, max_requests: mr, rows: rows}}
  end

  def handle_cast({:start_updating, _ }, tables) do
    GenServer.cast(MyServer, {:request_tables, tables})  
    {:noreply,tables}
  end

  def handle_cast({:start_requesting, _ }, 
    %Tables{ request_number: n, self: peer,self_atom: self, max_requests: mr, routing_table: rt} = tables) do
    case mr+1 == n do
      false->
        mid = 
          peer<>"#{inspect n}"
          |> Pastry.hash_input    
        GenServer.cast(self,{:handle_message, %Message{mid: mid, request_init: self, prev_peer: self, request_number: n}})
        Process.sleep(1000)
        GenServer.cast(self,{:start_requesting, 1})
      true->"#send message to server that requests completed"      
    end
    {:noreply,%Tables{ tables | request_number: n+1 }}
  end

  def handle_cast({:handle_message, %Message{mid: mid, num_hops: hops, received_through: through,request_init: init, prev_peer: p, request_number: req_num} = message},
   %Tables{routing_table: rt, rows: rows, self_atom: s} = tables) do 
          [row,col,mid] = which_route(to_string(mid),rt,rows)
          {table,loc,next_hop} =  {:rt,[row,col], mid}
          #end
        case next_hop do
          nil ->
            GenServer.cast(s,{:handle_message, %Message{message | received_through: :rt}})
          _ ->
          case next_hop == s or Process.whereis(next_hop) != nil do
            true ->
                GenServer.cast(next_hop,{:handle_message, %Message{message | received_through: :rt, num_hops: hops+1, prev_peer: s}})
            false -> 
              next_hop = 
              case next_hop == s do
                true -> nil
                false -> next_hop
              end
              GenServer.cast(s,{:remove_inactive_peer, [next_hop,loc,table] })
              GenServer.cast(s,{:handle_message, %Message{message | received_through: :rt}})
          end
        end
      GenServer.cast(MyServer, {:trial_count, [hops,req_num]})
    #end   
    {:noreply,tables}
  end

  def handle_cast({:remove_inactive_peer, [peer,loc,table]}, %Tables{ routing_table: rt} = tables) do
    case table do
      :rt -> [row,col] = loc
        {:noreply, %Tables{tables | routing_table: Map.replace(rt,row,Map.replace(rt[row],col,nil)) }}
    end
  end

  def handle_cast({:ready_tables, %Tables{routing_table: rt} =tables }, _state) do
    {:noreply, %Tables{ tables| ready_rt: true}}
  end

  def which_route(mid_string,routing_table,rows) do
    {prefix, tail} = String.split_at(mid_string,rows-1)
    case rows-1 <0 do
      true-> 
        [nil,nil,nil]
      false->
        case routing_table[prefix] do
          nil -> which_route(mid_string,routing_table,rows-1)
          row -> 
            {a,_} = String.split_at(tail,1)
            case row[a] do
              nil-> which_route(mid_string,routing_table,rows-1)              
              hop_to -> [prefix,a,hop_to]
            end
        end
    end    
  end

  def mk_empty_rt(rt,prefix_len,row_empty_lists,self) do
    {h,_} = String.split_at(self,prefix_len)
    case prefix_len do
      0 -> Map.put( rt, h, row_empty_lists)
      _ -> rt = Map.put( rt, h, row_empty_lists)
        mk_empty_rt(rt,prefix_len - 1 ,row_empty_lists, self)
    end    
  end
end
