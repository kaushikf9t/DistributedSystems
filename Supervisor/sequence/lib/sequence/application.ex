defmodule Sequence.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    # range = 1..System.schedulers_online()
    passed_args = System.argv()
    {_, params, _} = OptionParser.parse(passed_args, strict: [debug: :boolean])
    no_args = length(params)
    IO.puts("no of args : #{no_args}")
    # Check if only 2 arguments are passed
    # if no_args === 2 do
    [argval1 | rest] = params
    [argval2 | []] = rest
    {arg_n, ""} = Integer.parse(argval1)
    {arg_k, ""} = Integer.parse(argval2)
    IO.puts("#{arg_n} and #{arg_k} <<<<")
    # end

    remote_machines = [:"one@192.168.0.76"]
    # remote_machines = []
    # Node.start(:"sukhmeet@10.136.165.92")
    # Node.set_cookie(:choco_chip)

    no_machines = length(remote_machines) + 1

    interval = Kernel.trunc((arg_k - arg_n) / no_machines)

    start_of_local = arg_n + (no_machines - 1) * interval + 1

    children = [
      # Starts a worker by calling: Sequence.Worker.start_link(arg)
      worker(Sequence.Server, [start_of_local, arg_k])
      # worker(Mix.Tasks.Boss.start_link(10_000, 20_000), [3, 2])
    ]

    # pid = 0
    ranges =
      remote_machines
      |> Enum.with_index()
      |> Enum.map(fn {machine, index} ->
        # Node.connect(machine)
        start_n = arg_n + index * interval
        end_n = start_n + (index + 1) * interval
        # ranges = [{machine, start_n, end_n} | ranges]
        {machine, start_n, end_n}
        # distriuted_work(machine, start_n, end_n, arg_k)
      end)

    IO.puts(">>>>>>>>>>>>>>>>>>")
    IO.inspect(ranges)

    children = [worker(CallExt.Server, [ranges]) | children]
    children = [{Task.Supervisor, name: Vamp.TaskSupervisor} | children]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sequence.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
