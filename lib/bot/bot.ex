defmodule Agala.Bot do
  @moduledoc """
  This module represents main Bot supervisor.

  **Bot** is a complex module, that can retreive information, handle it and send either to recepient
  or to another Bot module.

  Defining new **Bot** requires only `name`, `provider` and `handler`.

  When the **Bot** is starting it will automaticly make supervision tree for next modules:

  * `Agala.Bot.PollServer` - module which gets new data from the recepient defined as a `provider`
  * `Agala.Bot.PollHandler` - module which is handling messages, that are incoming to the `bot`
  * `Agala.Bot.Responser` - module, that converts your application responses into form,
    acceptable by the recepient
  """
  use Supervisor

  def child_spec(bot_params = %{name: name}) do
    %{
      id: "Agala.Bot##{name}",
      start: {Agala.Bot, :start_link, [bot_params]},
      type: :supervisor
    }
  end

  defp via_tuple(name) do
    {:global, {:agala, :bot, name}}
  end

  @doc """
  Main function, starts the supervision tree
  """
  def start_link(bot_params) do
    Supervisor.start_link(__MODULE__, bot_params, name: via_tuple(bot_params.name))
  end

  def init(bot_params = %{
    storage: storage,
    provider: provider
  }) do
    case function_exported?(storage, :child_spec, 1) do
      true -> [{storage, bot_params}]
      false -> []
    end ++ [
      {provider.get_responser(), bot_params},
      {Agala.Bot.Handler, bot_params},
      {provider.get_receiver(), bot_params},
    ]
    |> Supervisor.init(strategy: :one_for_one, max_restarts: 1000, max_seconds: 1)
  end
end
