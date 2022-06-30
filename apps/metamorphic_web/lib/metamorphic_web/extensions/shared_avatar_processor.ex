defmodule MetamorphicWeb.Extensions.SharedAvatarProcessor do
  @moduledoc """
  A GenServer to handle the temp storage of
  people's decrypted shared avatars.
  """
  use GenServer

  ## Client

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def put_ets_avatar(key, value, avatar_id) do
    :ets.insert(__MODULE__, {key, value, avatar_id})
  end

  def get_ets_avatar(key, avatar_id) do
    case :ets.match_object(__MODULE__, {key, :_, avatar_id}) do
      [] ->
        nil

      [{^key, value, ^avatar_id}] ->
        value
    end
  end

  def delete_ets_avatars(key) do
    :ets.delete(__MODULE__, key)
  end

  def delete_ets_avatar(key, avatar_id) do
    :ets.delete_object(__MODULE__, {key, :_, avatar_id})
  end

  # def sweep_on_login(sid) do
  #  case :ets.lookup(@tab, sid) do
  #    [{session_id, _}] ->
  #      :ets.delete(@tab, session_id)
  #    [_] ->
  #      :ok
  #  end
  # end

  ## Server
  def init(_) do
    :ets.new(__MODULE__, [
      :set,
      :named_table,
      :public,
      :compressed,
      read_concurrency: true,
      write_concurrency: true
    ])

    # schedule_sweep()
    {:ok, nil}
  end

  # def handle_info(:sweep, state) do
  #  :ets.delete_all_objects(@tab)
  #  schedule_sweep()
  #  {:noreply, state}
  # end

  # defp schedule_sweep do
  #  Process.send_after(self(), :sweep, @sweep_after)
  # end
end
