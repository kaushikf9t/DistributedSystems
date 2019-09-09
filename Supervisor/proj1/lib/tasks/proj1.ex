defmodule Proj1 do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    # range = 1..System.schedulers_online()
    passed_args = System.argv()
    {_, params, _} = OptionParser.parse(passed_args, strict: [debug: :boolean])
    [argval1 | rest] = params
    [argval2 | []] = rest
    {arg_n, ""} = Integer.parse(argval1)
    {arg_k, ""} = Integer.parse(argval2)

    remote_machines = []
    # remote_machines = []
    # Node.start(:"sukhmeet@10.136.165.92")
    # Node.set_cookie(:choco_chip)

    no_machines = length(remote_machines) + 1

    interval = Kernel.trunc((arg_k - arg_n) / no_machines)

    start_of_local =
      if Enum.count(remote_machines) > 0 do
        arg_n + (no_machines - 1) * interval + 1
      else
        arg_n
      end

    children = [
      worker(Local.Server, []),
      worker(Boss, [start_of_local, arg_k])
    ]

    # pid = 0
    ranges =
      remote_machines
      |> Enum.with_index()
      |> Enum.map(fn {machine, index} ->
        start_n = arg_n + index * interval
        end_n = start_n + (index + 1) * interval
        {machine, start_n, end_n}
      end)

    children = [worker(CallExt.Server, [ranges]) | children]

    opts = [strategy: :one_for_one, name: Sequence.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
