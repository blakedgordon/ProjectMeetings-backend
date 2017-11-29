defmodule ProjectMeetingsWeb.UserChannel do
  use Phoenix.Channel

  alias ProjectMeetingsWeb.Presence

  intercept ["presence_diff"]

  @moduledoc """
  The user will connect to this channel to get realtime updates
  about invites and upcoming meetings.
  """

  @doc """
  Validates the user and joins the specified user channel
  """
  def join("user:" <> u_id, _params, socket) do
    current_user = socket.assigns[:current_user]

    if u_id == current_user["u_id"] do
      reply = "Successfully connected. " <>
        "Welcome, #{current_user["display_name"]}!"

      send self(), :after_join

      {:ok, reply, assign(socket, :u_id, u_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  Checks if anyone is still in the room. If not, untrack the meeting's presence.
  """
  def handle_out("presence_diff", _body, socket) do
    u_id = socket.assigns[:u_id]

    if length(Presence.list("user:#{u_id}")[u_id].metas) == 0 do
      send self(), :after_leave
    end
    {:noreply, socket}
  end


  @doc """
  Tracks the user's presence
  """
  def handle_info(:after_join, socket) do
    current_user = socket.assigns.current_user
    {:ok, _} = Presence.track(socket, current_user["u_id"], %{
      current_user: current_user,
      online_at: inspect(System.system_time(:seconds))
    })

    push socket, "presence_state", Presence.list(socket)

    {:noreply, socket}
  end

  @doc """
  Untracks the meeting's presence when it concludes
  """
  def handle_info(:after_end, socket) do
    {:ok, _} = Presence.untrack(socket, socket.assigns.u_id)

    push socket, "presence_state", Presence.list(socket)

    {:noreply, socket}
  end
end
