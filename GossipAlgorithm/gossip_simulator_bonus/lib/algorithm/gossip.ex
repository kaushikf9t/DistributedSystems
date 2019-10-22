defmodule Algorithm.Gossip do
  use GenServer
  def start_link() do
    GenServer.start_link(__MODULE__, 0)
  end

  def send(pid, neighbours, black_list) do
      neighbours = Enum.filter(neighbours, & !is_nil(&1))
      if (MapSet.subset?(MapSet.new(neighbours), black_list)===true) do
        0
      else
        rand_pid = get_random_neighbour(neighbours, black_list)
      end
  end

  def receive(pid) do
      GenServer.call(pid, :receive, :infinity) 
  end

  def getCount(actor_pid) do
  
    GenServer.call(actor_pid, :getcount, :infinity)
  end

  def get_random_neighbour(neighbours, black_list) do
    rand_pid = Enum.random(neighbours)
    
    rand_pid = if (MapSet.member?(black_list, rand_pid)===true) do
      get_random_neighbour(neighbours, black_list)
    else
      rand_pid
    end
    
    rand_pid
  end

  def init(args) do
    count = args
    {:ok, count}
  end

  def handle_call(:receive, _from, count) do
    
    {:reply, self(), count+1}
  end

  def handle_call(:send, _from, count) do
    
    {:reply, self(), count+1}
  end

  def handle_call(:getcount, _from, count) do
    {:reply, count, count}
  end

end