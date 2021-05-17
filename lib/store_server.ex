defmodule StoreServer do
  use GenServer

  def start(default \\ []) do
    GenServer.start(__MODULE__, default, name: __MODULE__)
  end

  def set(name, value) do
    GenServer.cast(__MODULE__, { :set, name, value })
  end

  def get(name) do
    GenServer.call(__MODULE__, { :get, name })
  end

  def count(value) do
    GenServer.call(__MODULE__, { :count, value })
  end

  def delete(name) do
    GenServer.cast(__MODULE__, { :remove, name })
  end

  def stop do
    GenServer.stop(__MODULE__)
  end

  def init(args) do
    { :ok, Enum.into(args, %{}) }
  end

  def handle_call({ :get, name }, _from, state) do
    { :reply, Map.get(state, name), state }
  end

  def handle_call({ :count, value }, _from, state) do
    count_values = Map.values(state)
    IO.inspect count_values
    IO.inspect value


    count_name_values = Enum.reduce count_values, 0, fn(x, acc) ->
      if x === value do
        acc + 1
      end
    end
   count = case count_name_values do
      nil -> 0
      _-> count_name_values
    end
    IO.inspect count
    { :reply, %{count: count} , state }
  end

  def handle_cast({ :set, name, value }, state) do
    { :noreply, Map.put(state, name, value) }
  end

  def handle_cast({ :remove, name }, state) do
    { :noreply, Map.delete(state, name) }
  end

end
