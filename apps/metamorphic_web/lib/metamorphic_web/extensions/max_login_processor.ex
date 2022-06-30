defmodule MetamorphicWeb.Extensions.MaxLoginProcessor do
  @moduledoc """
  A GenServer to limit log in attempts to 5
  every hour.
  """
  use GenServer

  @max_per_hour 5
  @sweep_after :timer.hours(1)
  @tab :rate_limiter_requests

  ## Client

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def log(sid) do
    case :ets.update_counter(@tab, sid, {2, 1}, {sid, 0}) do
      count when count >= @max_per_hour -> {:error, :rate_limited}
      count -> {:ok, count}
    end
  end

  def sweep_on_login(sid) do
    case :ets.lookup(@tab, sid) do
      [{session_id, _}] ->
        :ets.delete(@tab, session_id)

      [_] ->
        :ok
    end
  end

  ## Server
  def init(_) do
    :ets.new(@tab, [:set, :named_table, :public, read_concurrency: true, write_concurrency: true])
    schedule_sweep()
    {:ok, %{}}
  end

  def handle_info(:sweep, state) do
    :ets.delete_all_objects(@tab)
    schedule_sweep()
    {:noreply, state}
  end

  defp schedule_sweep do
    Process.send_after(self(), :sweep, @sweep_after)
  end
end
