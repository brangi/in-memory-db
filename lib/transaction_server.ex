defmodule TransactionServer do
  use GenServer

  def start(default \\ []) do
    GenServer.start(__MODULE__, default, name: __MODULE__)
  end

  def stop do
    GenServer.stop(__MODULE__)
  end

  def get_transactions() do
    GenServer.call(__MODULE__, :get)
  end

  def get_last_t_cmd_state do
    GenServer.call(__MODULE__, :get_last_t_cmd_state)
  end

  def get_last_t do
    GenServer.call(__MODULE__, :get_last_t)
  end

  def begin() do
    GenServer.cast(__MODULE__, :begin)
  end

  def add(t) do
    GenServer.cast(__MODULE__, {:add_cmd, t})
  end

  def rollback() do
    GenServer.cast(__MODULE__, :rollback)
  end

  def commit() do
    GenServer.cast(__MODULE__, :commit)
  end

  defp build_new_t_rec(last_t, new_list_t, new_state_t) do

    key_t = last_t |> Map.keys |> Enum.at(0)
    value_new_list = new_list_t |> Map.values |> Enum.at(0)

    key_state = last_t |> Map.keys |> Enum.at(1)
    value_new_state = new_state_t |> Map.values |> Enum.at(1)

    %{key_t => value_new_list, key_state => value_new_state}
  end

  defp get_state_value(last_cmd)do
    arg1 = Database.get_arg(last_cmd |> Enum.join(", "), 1)
    value = StoreServer.get(arg1)
    %{arg1 => value}
  end

  defp check_for_cmd(cmd, current_state, last_cmd)do
    case cmd do
      "delete" ->
        {current_state, get_state_value(last_cmd)}
      "set" ->
        {current_state, get_state_value(last_cmd)}
      _->
        {current_state, current_state}
    end
  end

  defp update_new_state_for_t(c_t_state, last_t, new_tr_rec1) do
    case c_t_state do
      nil ->
        Map.get_and_update(last_t,last_t |> Map.keys |> Enum.at(1) , fn current_state ->
          #Get last command
          last_cmd = new_tr_rec1 |> Map.values |> Enum.at(0)
          cmd_str = Database.get_arg(last_cmd |>  Enum.join(", "), 0) |> String.downcase
          check_for_cmd(cmd_str, current_state, last_cmd)
        end)
      _->
        Map.get_and_update(last_t,last_t |> Map.keys |> Enum.at(1) , fn current_state ->
          last_cmd = new_tr_rec1 |> Map.values |> Enum.at(0)
          cmd_str = Database.get_arg(last_cmd |>  Enum.join(", "), 0) |> String.downcase
          arg1 = Database.get_arg(last_cmd |>  Enum.join(", "), 1)
          add_more_state = Map.keys(current_state) |> Enum.member?(arg1)
          case add_more_state do
            false ->

              case cmd_str do
                "delete" ->
                  {current_state, Map.put(current_state, arg1, StoreServer.get(arg1))}
                "set" ->
                  {current_state, Map.put(current_state, arg1, StoreServer.get(arg1))}
                _->
                  {current_state, current_state}
              end

            true ->
              {current_state, current_state}
          end

        end)
    end
  end

  def init(_args) do
    { :ok, %{tansactions: []} }
  end

  def handle_call(:get , _from, state) do
    { :reply,  Map.get(state, :tansactions), state }
  end

  def handle_call(:get_last_t , _from, state) do
    last_t =  Map.get(state, :tansactions) |> List.first()
    { :reply,  last_t, state }
  end

  def handle_call(:get_last_t_cmd_state , _from, state) do
    last_t =  Map.get(state, :tansactions) |> List.first()
    cmd_key = last_t |> Map.keys |> Enum.at(0)
    last_state =  last_t |> Map.values |> Enum.at(1)
    last_cmd = Map.get(last_t,  cmd_key) |> List.first()
    { :reply,  {last_cmd, last_state }, state }
  end

  def handle_cast({:add_cmd, cmd}, state) do
    current_transactions = Map.get(state, :tansactions)
    case Enum.count(current_transactions) do
      0 ->
        {:noreply, state}
      _->
        last_t =  Map.get(state, :tansactions) |> List.first()

        ##Get transaction list and update
        {_, transactions} =  Map.get_and_update(state, :tansactions, fn current_transactions ->

          ##Get command list of last transaction and update
          {_, new_tr_rec1} = Map.get_and_update(last_t,last_t |> Map.keys |> Enum.at(0) , fn current_cmd_list ->
            case Enum.count(current_cmd_list) do
              0 ->
                new_list = [cmd | []]
                {current_cmd_list, new_list}
              _->
                new_list = [cmd | current_cmd_list]
                {current_cmd_list, new_list}
            end
          end)
          current_state_last_t = Map.get(last_t,last_t |> Map.keys |> Enum.at(1))
          {_, new_tr_rec2} = update_new_state_for_t(current_state_last_t, last_t,  new_tr_rec1)

          new_transactions = [ build_new_t_rec(last_t, new_tr_rec1, new_tr_rec2) | List.delete(current_transactions, last_t)]
          {current_transactions, new_transactions}
        end)

        {:noreply, transactions}
    end
  end

  def handle_cast(:rollback, state) do
    {_, transactions} =  Map.get_and_update(state, :tansactions, fn current->
      last_rec_t = current |> List.first()
      last_rec_t_values =  Map.get(last_rec_t, last_rec_t |> Map.keys() |> Enum.at(1))

      case last_rec_t_values do
        nil ->
          {_, new}  = List.pop_at(current, 0)
          {current, new}
        values  ->
          Enum.each values, fn {k, v} ->
            StoreServer.set(k, v)
          end
          {_, new}  = List.pop_at(current, 0)
          {current, new}
      end
    end)
    {:noreply, transactions}
  end

  def handle_cast(:begin, state) do
    {_, transactions} =  Map.get_and_update(state, :tansactions, fn current->
      time = :os.system_time
      t = String.to_atom("t_#{time}")
      t_d = String.to_atom("t_#{time}_alpha")
      new = [ %{ t => [], t_d => nil } | current]
      {current, new}
    end)
    {:noreply, transactions}
  end

  def handle_cast(:commit, state) do
    {_, transactions} =  Map.get_and_update(state, :tansactions, fn current->
      {_, new_t_list}  = List.pop_at(current, 0)
      {current, new_t_list}
    end)
    {:noreply, transactions}
  end

end
