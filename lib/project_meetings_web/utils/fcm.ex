defmodule ProjectMeetings.Utils.FCM do
  alias ProjectMeetings.User

  @topics [:invite, :meeting]

  def notify!(_topic, _emails, meeting) when
      is_map(meeting) == false or meeting == %{} do
    raise ArgumentError, message: "The third argument of notify!/3 must be a meeting"
  end

  def notify!(_topic, emails, _meeting) when is_list(emails) == false do
    raise ArgumentError, message: "The second argument of notify!/3 must be a list"
  end

  def notify!(topic, _emails, _meeting) when topic not in @topics do
    raise ArgumentError, message: "The first argument of notify!/3 must be one
      of the following: #{@topics}"
  end

  def notify!(_topic, emails, _meeting) when length(emails) == 0 do
    %HTTPoison.Response{:status_code => 200}
  end

  def notify!(:invite, emails, meeting) do
    registration_ids = Enum.map emails, fn(email) ->
      User.get_by_email!(email)["instance_id"]
    end

    m = if Map.has_key?(meeting, "u_id") do
      for {key, val} <- meeting, into: %{}, do: {String.to_atom(key), val}
    else
      meeting
    end

    u_name = User.get_by_u_id!(m.u_id)["display_name"]
    m_name = m.name

    message = %{
      notification: %{
        title: "#{u_name}NAME invited you to a meeting!",
        body: "Tap to view \"#{m_name}\""
      },
      data: %{
        title: "#{u_name}NAME invited you to a meeting!",
        body: "Tap to view \"#{m_name}\""
      },
      registration_ids: registration_ids
    }

    send_notification(message)
  end

  def notify!(:meeting, emails, meeting) do
    registration_ids = Enum.map emails, fn(email) ->
      User.get_by_email!(email)["instance_id"]
    end

    m = if Map.has_key?(meeting, "u_id") do
      for {key, val} <- meeting, into: %{}, do: {String.to_atom(key), val}
    else
      meeting
    end

    message = %{
      notification: %{
        title: "Your meeting is about to start!",
        body: "Tap to join \"#{m.name}\""
      },
      data: %{
        title: "Your meeting is about to start!",
        body: "Tap to join \"#{m.name}\""
      },
      registration_ids: registration_ids
    }

    send_notification(message)
  end

  defp send_notification(message) do
    url = "https://fcm.googleapis.com/fcm/send"

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "key=#{Application.get_env(:project_meetings, ProjectMeetingsWeb.Endpoint)[:firebase_server_key]}"}
    ]

    HTTPoison.post!(url, message |> Poison.encode!, headers)
  end
end
