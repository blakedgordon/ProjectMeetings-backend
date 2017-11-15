defmodule ProjectMeetingsWeb.UserChannel do
  use Phoenix.Channel

  alias ProjectMeetingsWeb.Presence

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

      {:ok, reply, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  Checks if the user is online, then notifies them about an invitation accordingly
  """
  def handle_out("invite_notify", %{"body" => body}, socket) do
    u_id = body["u_id"]

    if length(Presence.list("user:#{u_id}")[u_id].metas) > 0 do
      broadcast! socket, "invite_notify", %{body: body}
    else
      # TODO: Send push notification
    end

    {:noreply, socket}
  end

  @doc """
  Checks if the user is online, then notifies them about an upcoming meeting accordingly
  """
  def handle_out("meeting_notify", %{"body" => body}, socket) do
    u_id = body["u_id"]

    if length(Presence.list("user:#{u_id}")[u_id].metas) > 0 do
      broadcast! socket, "meeting_notify", %{body: body}
    else
      # TODO: Send push notification
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
end
