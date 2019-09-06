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

    children = [
      # Starts a worker by calling: Sequence.Worker.start_link(arg)
      worker(Sequence.Server, [arg_n, arg_k])
      # worker(Mix.Tasks.Boss.start_link(10_000, 20_000), [3, 2])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sequence.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
