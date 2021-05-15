defmodule Database do
  def main(_args) do
    StoreServer.start()
    receive_command()
  end

  defp get_arg(io_str, index) do
    io_str
    |> String.split(" ")
    |> Enum.at(index)
    |> String.trim
    |> String.downcase
  end

  defp receive_command do
    io_str = IO.gets(">>")
    cmd = get_arg(io_str, 0)
    cmd_list = io_str
               |> String.split(~r{\s+})
               |> Enum.join(" ")
               |> String.split(" ", trim: true)
    case Enum.count(cmd_list) do
      1 ->
        execute_command(cmd)
      2 ->
        arg1 = get_arg(io_str, 1)
        execute_command(cmd, arg1)
      3->
        arg1 = get_arg(io_str, 1)
        arg2 = get_arg(io_str, 2)
        execute_command(cmd, arg1, arg2)
      _->
        execute_command(:invalid)
    end

  end

  defp execute_command("set", arg1, arg2) do
    StoreServer.set(arg1, arg2)
    receive_command()
  end

  defp execute_command("get", arg) do
    case StoreServer.get(arg) do
      nil -> IO.puts "NULL"
      value -> IO.puts value
    end
    receive_command()
  end

  defp execute_command("delete", arg) do
    StoreServer.delete(arg)
    receive_command()
  end

  defp execute_command("count", arg) do
    count = StoreServer.count(arg) |>  Map.get(:count)
    IO.puts count
    receive_command()
  end

  defp execute_command("begin") do
    IO.puts "\nbegin."
    receive_command()
  end

  defp execute_command("rollback") do
    IO.puts "\nrollback."
    receive_command()
  end

  defp execute_command("commit") do
    IO.puts "\ncommit."
    receive_command()
  end

  defp execute_command("end") do
    IO.puts "\nExit."
  end

  defp execute_command(_) do
    IO.puts "\nInvalid command."
    receive_command()
  end
end
