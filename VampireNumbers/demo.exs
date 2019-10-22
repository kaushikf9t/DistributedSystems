 #Cobbled together ("untested") demonstration code - no production value
# The intention is to flood all CPU cores with "work"
#
# Created for: https://elixirforum.com/t/finding-vampire-numbers/25098/10
#
defmodule Primes do
  require Integer

  @primes :primes
  @init_last 3
  @next_timeout 5_000

  # ---
  # GenServer related

  def init(init_arg) do
    precache = Keyword.get(init_arg, :precache, @init_last)
    {:ok, [], {:continue, precache}}
  end

  def handle_continue(precache, []) do
    initialize()
    last_prime = :ets.last(@primes)
    {:noreply, {%{}, last_prime, prime_next(precache, last_prime)}}
  end

  # keep generating values until limit is reached
  #
  def handle_cast(:next_prime, {requests, last_prime, precache}) do
    new_prime = next_prime(last_prime)
    new_requests = dispatch_replies(requests, new_prime)
    new_precache = prime_next(precache, new_prime)
    {:noreply, {new_requests, new_prime, new_precache}}
  end

  def handle_call({:next_prime, n}, from, {requests, last_prime, precache}) do
    new_requests = add_request(requests, from, n)

    new_precache =
      case precache <= n do
        false ->
          # still to be generated
          precache

        _ when precache <= last_prime ->
          # restart generation
          prime_next(n + 1, last_prime)

        _ ->
          # bump up ongoing generation limit
          n + 1
      end

    {:noreply, {new_requests, last_prime, new_precache}}
  end

  def start_link(opts) do
    {precache, opts} = Keyword.pop(opts, :precache, @init_last)
    init_arg = [precache: precache]
    opts = [{:name, __MODULE__} | opts]
    GenServer.start_link(__MODULE__, init_arg, opts)
  end

  # ---
  # GenServer State

  defp prime_next(precache, last_prime) when precache > last_prime do
    GenServer.cast(self(), :next_prime)
    precache
  end

  defp prime_next(_, last_prime) do
    IO.puts("Primes stopped: #{last_prime}")
    last_prime
  end

  defp add_request(requests, from, last_prime),
    do: Map.update(requests, last_prime, [from], &[from | &1])

  defp dispatch_replies(requests, last_prime) do
    requests
    |> Map.to_list()
    |> List.foldl(%{}, make_dispatch(last_prime))
  end

  defp make_dispatch(last_prime) do
    fn
      {n, pids}, pending when n < last_prime ->
        next_prime = :ets.next(@primes, n)
        dispatch_next(next_prime, pids)
        pending

      {n, pids}, pending ->
        # not ready
        Map.put(pending, n, pids)
    end
  end

  defp dispatch_next(_, []) do
    :ok
  end

  defp dispatch_next(value, [pid | others]) do
    GenServer.reply(pid, value)
    dispatch_next(value, others)
  end

  # ---
  # Cache population

  defp initialize() do
    :ets.new(@primes, [:ordered_set, :named_table])
    :ets.insert(@primes, {2})
    :ets.insert(@primes, {@init_last})
  end

  defp next_prime(n) when Integer.is_odd(n),
    do: add_next_prime(n + 2)

  defp add_next_prime(n) do
    if uncached_prime?(n) do
      :ets.insert(@primes, {n})
      n
    else
      add_next_prime(n + 2)
    end
  end

  defp uncached_prime?(n),
    do: uncached_prime?(n, @init_last)

  # number divisible by a prime cannot be a prime
  defp uncached_prime?(n, p) when rem(n, p) == 0 do
    false
  end

  defp uncached_prime?(n, last_prime) do
    case :ets.next(@primes, last_prime) do
      prime when is_integer(prime) ->
        uncached_prime?(n, prime)

      _ ->
        # ran out of primes - n as prime
        true
    end
  end

  # ---
  # Client functions

  def first(),
    do: :ets.first(@primes)

  def next(last_prime) do
    case :ets.next(@primes, last_prime) do
      prime when is_integer(prime) ->
        prime

      _ ->
        prime_request(last_prime)
    end
  end

  defp prime_request(last_prime),
    do: GenServer.call(__MODULE__, {:next_prime, last_prime}, @next_timeout)
end

defmodule Vnum do
  require Integer

  def isqrt(x) when x < 0,
    do: raise(ArithmeticError)

  def isqrt(x),
    do: isqrt(x, 1, div(1 + x, 2))

  defp isqrt(x, m, n) when abs(m - n) <= 1 and n * n <= x,
    do: n

  defp isqrt(_x, m, n) when abs(m - n) <= 1,
    do: n - 1

  defp isqrt(x, _, n),
    do: isqrt(x, n, div(n + div(x, n), 2))

  #
  # prime_factors(1530, Primes, 2, [])
  #
  # Output:
  # [{2, 1}, {3, 2}, {5, 1}, {17, 1}]
  #
  defp prime_factors(num, primes, prime, factors) do
    if prime <= isqrt(num) do
      {exponent, remainder} = prime_exponent(num, prime, 0)
      new_factors = if(exponent > 0, do: [{prime, exponent} | factors], else: factors)

      next_prime = primes.next(prime)
      prime_factors(remainder, primes, next_prime, new_factors)
    else
      new_factors = if(num >= 2, do: [{num, 1} | factors], else: factors)
      :lists.reverse(new_factors)
    end
  end

  defp prime_exponent(num, prime, count) when rem(num, prime) == 0 do
    num
    |> div(prime)
    |> prime_exponent(prime, count + 1)
  end

  defp prime_exponent(num, _, count) do
    {count, num}
  end

  #
  # Input:
  # [{2, 1}, {3, 2}, {5, 1}, {17, 1}]
  #
  # Output:
  # [17, 85, 5, 153, 765, 45, 9, 51, 255, 15, 3, 34, 170, 10, 306, 1530, 90, 18, 102, 510, 30, 6, 2, 1]
  #
  defp divisors(factors),
    do: divisors(factors, 1, [1])

  defp divisors([], _, acc),
    do: acc

  defp divisors([{prime, exponent} | rest], factor, acc) do
    new_acc = acc_divisors(rest, prime, exponent, factor, acc)
    divisors(rest, factor, new_acc)
  end

  defp acc_divisors(factors, prime, count, factor, acc) when count > 0 do
    new_factor = factor * prime
    new_acc = divisors(factors, new_factor, [new_factor | acc])
    acc_divisors(factors, prime, count - 1, new_factor, new_acc)
  end

  defp acc_divisors(_, _, _, _, acc) do
    acc
  end

  #
  # Input:
  # [17, 85, 5, 153, 765, 45, 9, 51, 255, 15, 3, 34, 170, 10, 306, 1530, 90, 18, 102, 510, 30, 6, 2, 1]
  #
  # Output:
  # [{1, 1530}, {2, 765}, {3, 510}, {5, 306}, {6, 255}, {9, 170}, {10, 153}, {15, 102}, {17, 90}, {18, 85}, {30, 51}, {34, 45}]
  #
  defp pair_divisors(divisors) do
    count =
      divisors
      |> length()
      |> div(2)

    {lower, upper} =
      divisors
      |> Enum.sort()
      |> Enum.split(count)

    List.zip([lower, :lists.reverse(upper)])
  end

  #
  # ordered_digits(1530) -> {"0135", 4}
  #
  defp ordered_digits(n) do
    digits = Integer.digits(n)
    {ordered_string(digits), length(digits)}
  end

  #
  # ordered_string([1, 5, 3, 0]) -> "0135"
  #
  defp ordered_string(digits) do
    digits
    |> Enum.sort()
    |> Enum.join()
  end

  # ref: https://oeis.org/A014575
  #
  # fangs?("0135", 2, {30, 51}) -> true
  # fangs?("0135", 2, {34, 45}) -> false
  #
  defp fangs?(ordered, size, {x, y}) do
    with x_digits <- Integer.digits(x),
         {x_digits, true} <- {x_digits, length(x_digits) === size},
         {x_digits, y_digits} <- {x_digits, Integer.digits(y)},
         {x_digits, y_digits, true} <- {x_digits, y_digits, length(y_digits) === size},
         {x_digits, y_digits, true} <- {x_digits, y_digits, rem(x, 10) !== 0 or rem(y, 10) !== 0} do
      ordered == ordered_string(x_digits ++ y_digits)
    else
      _ ->
        false
    end
  end

  def filter_fangs(pairs, ordered, fang_size),
    do: Enum.filter(pairs, &fangs?(ordered, fang_size, &1))

  def extract_fangs(primes, n) do
    {ordered, digit_count} = ordered_digits(n)

    with true <- Integer.is_even(digit_count) and digit_count > 2 do
      fang_size = div(digit_count, 2)

      n
      |> prime_factors(primes, 2, [])
      |> divisors()
      |> pair_divisors()
      |> filter_fangs(ordered, fang_size)
    else
      _ ->
        []
    end
  end
end

defmodule Demo do
  def run(x, y) do
    {m, n} = adjust(x, y)
    Primes.start_link(precache: div(n, 2))

    opts = [timeout: 5_000]

    m..n
    |> Task.async_stream(__MODULE__, :extract_fangs, [Primes], opts)
    |> Enum.reduce([], &keep_vampires/2)
  end

  defp adjust(x, y) when is_integer(x) and is_integer(y) do
    {m, n} = if(x <= y, do: {x, y}, else: {y, x})

    {max(m, 1000), max(n, 1000)}
  end

  def extract_fangs(n, primes),
    do: {n, Vnum.extract_fangs(primes, n)}

  defp keep_vampires({:ok, {_n, [_ | _]} = vampire_result}, others),
    do: [vampire_result | others]

  defp keep_vampires(_non_vampire_result, others),
    do: others
end

IO.puts("Schedulers online: #{System.schedulers_online()}")

# http://oeis.org/A048939
args = [100_000, 200_000]

# args = [1_000_000_000, 2_000_000_000]
{time, result} = :timer.tc(Demo, :run, args)

IO.puts("Seconds: #{div(time, 1_000_000)}")
IO.inspect(result)