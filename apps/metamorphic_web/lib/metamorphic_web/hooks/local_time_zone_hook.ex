defmodule MetamorphicWeb.Hooks.LocalTimeZoneHook do
  @moduledoc false
  import Phoenix.LiveView

  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> attach_hook(:local_time_zone, :handle_event, fn
       "local-timezone", %{"local_timezone" => local_timezone}, socket ->
         # Handle the very special event and then detach the hook
         socket =
           socket
           |> assign(:local_timezone, local_timezone)

         {:halt, detach_hook(socket, :local_time_zone, :handle_event)}

       _event, _params, socket ->
         {:cont, socket}
     end)}
  end
end
