defmodule ProjectMeetingsWeb.MeetingChannel do
  use Phoenix.Channel

  alias ProjectMeetingsWeb.Presence

  @moduledoc """
  The user will connect to a room in this channel to get real-time updates
  about the specified meeting.
  """

  @doc """
  Validates the user and joins the specified meeting channel
  """
  def join("meeting:" <> m_id, _params, socket) do
    current_user = socket.assigns[:current_user]

    if (Map.has_key?(current_user, "invites") and
        Map.has_key?(current_user["invites"], m_id)) or
        (Map.has_key?(current_user, "meetings") and
        Map.has_key?(current_user["meetings"], m_id)) do
      reply = %{
        msg: "Successfully connected to meeting #{m_id}. " <>
          "Welcome, #{current_user["display_name"]}!",
        in_progress: Map.has_key?(Presence.list("meeting:#{m_id}"), m_id)
      }

      send self(), :after_join

      {:ok, reply, assign(socket, :m_id, m_id)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @doc """
  Validates that the caller is authorized and then starts the meeting.
  """
  def handle_in("start_meeting", _body, socket) do
    current_user = socket.assigns[:current_user]
    m_id = socket.assigns[:m_id]

    if Map.has_key?(current_user, "meetings") and
        Map.has_key?(current_user["meetings"], m_id) do
      broadcast! socket, "start_meeting", %{}
    end

    {:noreply, socket}
  end

  @doc """
  Posts a new message to the meeting.
  """
  def handle_in("new_msg", %{"msg" => msg}, socket) do
    current_user = socket.assigns[:current_user]

    broadcast! socket, "new_msg", %{u_id: current_user["u_id"], msg: msg}

    {:noreply, socket}
  end

  @doc """
  Posts a new applause to the meeting.
  """
  def handle_in("new_applause", _body, socket) do
    current_user = socket.assigns[:current_user]

    broadcast! socket, "new_applause", %{u_id: current_user["u_id"]}

    {:noreply, socket}
  end

  @doc """
  Tracks the user's presence in the meeting
  """
  def handle_info(:after_join, socket) do
    current_user = socket.assigns.current_user
    {:ok, _} = Presence.track(socket, current_user["u_id"], %{
      data: current_user |> Map.drop(["google_token", "firebase_token"]),
      online_at: inspect(System.system_time(:seconds))
    })

    push socket, "presence_state", Presence.list(socket)

    {:noreply, socket}
  end

  @doc """
  Tracks the meeting's presence as it's in progress
  """
  def handle_info(:after_start, socket) do
    m_id = socket.assigns.m_id
    {:ok, _} = Presence.track(socket, m_id, %{
      updated_at: inspect(System.system_time(:seconds))
    })

    push socket, "presence_state", Presence.list(socket)

    {:noreply, socket}
  end

  @doc """
  Untracks the meeting's presence when it concludes
  """
  def handle_info(:after_end, socket) do
    {:ok, _} = Presence.untrack(socket, socket.assigns.m_id)

    push socket, "presence_state", Presence.list(socket)

    {:noreply, socket}
  end
end
