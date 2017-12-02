defmodule ProjectMeetings.Utils.FCM do
  alias ProjectMeetings.{User, Meeting}
  alias ProjectMeetings.Utils.Scheduler

  @topics [:meeting_invite, :meeting_start, :meeting_warn]

  @moduledoc """
  This module assists with sending notifications through Firebase Cloud Messaging.
  """

  def notify!(_topic, _emails, meeting) when
      is_map(meeting) == false or meeting == %{} do
    raise ArgumentError, message: "The third argument of notify!/3 must be a meeting"
  end

  def notify!(_topic, emails, _meeting) when is_list(emails) == false do
    raise ArgumentError, message: "The second argument of notify!/3 must be a list"
  end

  def notify!(topic, _emails, _meeting) when topic not in @topics do
    raise ArgumentError, message: "The first argument of notify!/3 must be one
      of the following: #{List.to_string(@topics)}"
  end

  def notify!(_topic, emails, _meeting) when length(emails) == 0 do
    %HTTPoison.Response{:status_code => 200}
  end

  @doc """
  Notify users of a new invite.
  """
  def notify!(:meeting_invite, emails, meeting) do
    registration_ids = Enum.map emails, fn(email) ->
      User.get_by_email!(email)["instance_id"]
    end

    m = to_atom_map(meeting)

    message = %{
      type: "meeting_invite",
      title: "#{User.get_by_u_id!(m.u_id)["display_name"]} invited you to a meeting!",
      body: "Tap to view \"#{m.name}\"",
      meeting: m
    }

    send_notification(message, registration_ids)
  end

  @doc """
  Warn users of a meeting about to start.
  """
  def notify!(:meeting_warn, m_id) do
    m = to_atom_map(Meeting.get!(m_id))

    registration_ids = Enum.map Map.keys(m.invites), fn(email) ->
      User.get_by_email!(email)["instance_id"]
    end ++ [to_atom_map(User.get_by_u_id!(m.u_id)).email]

    message = %{
      type: "meeting_warn",
      title: "Your meeting is about to start!",
      body: "Tap to join \"#{m.name}\"",
      meeting: m
    }

    send_notification(message, registration_ids)

    Scheduler.delete_job(String.to_atom("meeting:#{m_id}"))
  end

  @doc """
  Noritfy users of a meeting that has started.
  """
  def notify!(:meeting_start, meeting) do
    m = to_atom_map(meeting)

    registration_ids = Enum.map Map.keys(m.invites), fn(email) ->
      User.get_by_email!(email)["instance_id"]
    end

    message = %{
      type: "meeting_start",
      title: "Your meeting is starting!",
      body: "Tap to join \"#{m.name}\"",
      meeting: m
    }

    send_notification(message, registration_ids)
  end

  @doc """
  Schedule an meeting_warn FCM notification to be sent.
  """
  def schedule_notify(meeting) do
    m = to_atom_map(meeting)
    job_name = String.to_atom("meeting:#{m.m_id}")

    date = DateTime.from_unix!(m.time - 3000)

    IO.inspect(date)
    IO.inspect(date.day)

    Scheduler.delete_job(job_name)

    Scheduler.new_job()
    |> Quantum.Job.set_name(job_name)
    |> Quantum.Job.set_schedule(to_cron(DateTime.from_unix!(m.time - 300000))) # Time - 5 minutes
    |> Quantum.Job.set_task(fn -> notify!(:meeting_warn, m.m_id) end)
    |> Scheduler.add_job()
  end

  @doc """
  Unschedules an meeting_warn FCM notification from being sent.
  """
  def unschedule_notify(m_id) do
    String.to_atom("meeting:#{m_id}")
    |> Scheduler.delete_job
  end

  # Format meeting map to ensure all keys are atoms.
  defp to_atom_map(meeting) do
    if Map.has_key?(meeting, "u_id") do
      for {key, val} <- meeting, into: %{}, do: {String.to_atom(key), val}
    else
      meeting
    end
  end

  # Convert DateTime to CronExpression
  @spec to_cron(DateTime.t) :: Crontab.CronExpression.t
  defp to_cron(dt) do
    cron = "#{dt.second} #{dt.minute} #{dt.hour} #{dt.day} #{dt.month} #{dt.year}"
    Crontab.CronExpression.Parser.parse!(cron)
  end

  # Given a message and registration ids to send the message to,
  # create and deliver an FCM notification.
  defp send_notification(message, registration_ids) do
    url = "https://fcm.googleapis.com/fcm/send"

    notification = %{
      notification: message,
      data: message,
      registration_ids: registration_ids
    }

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "key=#{Application.get_env(:project_meetings,
        ProjectMeetingsWeb.Endpoint)[:firebase_server_key]}"}
    ]

    HTTPoison.post!(url, notification |> Poison.encode!, headers)
  end
end
