defmodule ProjectMeetingsWeb.MeetingController do
  use ProjectMeetingsWeb, :controller

  alias Ecto.UUID
  alias ProjectMeetings.{Meeting, User}
  alias ProjectMeetings.Utils.FCM

  @moduledoc """
  This controller assists with manipulating ProjectMeetings.Meeting objects in
  Firebase as well as the entities they influence.
  """

  @doc """
  Creates a new ProjectMeetings.Meeting object in Firebase
  """
  def create(conn, params) do
    try do
      meeting = params
      |> Map.put("u_id", conn.assigns.user["u_id"])
      |> Map.put("m_id", UUID.generate)

      spawn(FCM, :notify!, [:meeting_invite, params["invites"], meeting])
      handle_changeset_and_insert(conn, meeting)
    rescue
      e in RuntimeError ->
        conn |> send_resp(500, e.message)
    end
  end

  @doc """
  Retrieves info on a specified ProjectMeetings.Meeting object in Firebase
  """
  def show(conn, params) do
    user = conn.assigns.user
    m_id = params["m_id"]

    if (Map.has_key?(user, "invites") and Map.has_key?(user["invites"], m_id))
        or (Map.has_key?(user, "meetings") and Map.has_key?(user["meetings"], m_id)) do
      case Meeting.get(m_id) do
        {:ok, meeting} ->
          conn
          |> put_status(200)
          |> json(meeting)
        {:error, _status_code} ->
          conn |> send_resp(500,  "An unknown error occured")
      end
    else
      conn |> send_resp(401, "Unauthorized")
    end
  end

  @doc """
  Updates an existing ProjectMeetings.Meeting object in Firebase
  """
  def update(conn, params) do
    try do
      user = conn.assigns.user
      m_id = params["m_id"]

      meeting = if (Map.has_key?(user, "invites") and Map.has_key?(user["invites"], m_id)) or
          (Map.has_key?(user, "meetings") and Map.has_key?(user["meetings"], m_id))  do
        Meeting.get!(m_id)
        |> Map.merge(params)
        |> Map.delete("invites")
        |> Map.put("u_id", user["u_id"])
        |> Map.put("m_id", m_id)
      else
        conn
        |> send_resp(401, "Unauthorized")
        |> halt
      end

      handle_changeset_and_insert(conn, meeting)
    rescue
      e in RuntimeError -> conn |> send_resp(500, e.message)
    end
  end

  @doc """
  Deletes an existing ProjectMeetings.Meeting object from Firebase
  """
  def delete(conn, params) do
    user = conn.assigns.user
    m_id = params["m_id"]

    if Map.has_key?(user, "meetings") and Map.has_key?(user["meetings"], m_id) do
      try do
        case Meeting.delete(Meeting.get!(m_id), user) do
          {:ok, _status} ->
            FCM.unschedule_notify(m_id)
            conn |> send_resp(200,  "Deleted meeting #{m_id}")
          {:error, _status} -> conn |> send_resp(500,  "An unknown error occured")
        end
      rescue
        e in RuntimeError -> conn |> send_resp(500, e.message)
      end
    else
      conn |> send_resp(401, "Unauthorized")
    end
  end

  @doc """
  Invites specific users to the sepcified ProjectMeetings.Meeting entity.
  """
  def create_invites(conn, params) do
    user = conn.assigns.user
    m_id = params["m_id"]

    if Map.has_key?(user, "meetings") and Map.has_key?(user["meetings"], m_id) do
      try do
        Enum.each params["emails"], fn email ->
          Meeting.create_invite!(Meeting.get!(m_id), User.get_by_email!(email))
        end

        FCM.notify!(:meeting_invite, params["emails"], Meeting.get!(m_id))

        conn
        |> put_status(200)
        |> json(params)
      rescue
        e in RuntimeError -> conn |> send_resp(500, e.message)
      end
    else
      conn |> send_resp(401, "Unauthorized")
    end
  end

  @doc """
  Removes specific existing invites from the sepcified ProjectMeetings.Meeting entity
  """
  def delete_invites(conn, params) do
    user = conn.assigns.user
    m_id = params["m_id"]

    if Map.has_key?(user, "meetings") and Map.has_key?(user["meetings"], m_id) do
      try do
        Enum.each params["emails"], fn email ->
          Meeting.delete_invite!(Meeting.get!(m_id), User.get_by_email!(email))
        end

        conn
        |> put_status(200)
        |> json(params)
      rescue
        e in RuntimeError -> conn |> send_resp(500, e.message)
      end
    else
      conn |> send_resp(401, "Unauthorized")
    end
  end

  # Helps with validating a changeset inserting ProjectMeetings.Meeting entities
  # into Firebase, and calling for FCM notifications to be scheduled.
  defp handle_changeset_and_insert(conn, params) do
    changeset = Meeting.changeset(%Meeting{}, params)

    IO.inspect params

    if changeset.valid? do
      case Meeting.put(changeset.changes) do
        {:ok, meeting} ->
          spawn(FCM, :schedule_notify, [meeting])

          conn
          |> put_status(200)
          |> json(meeting)
        {:error, _status_code} ->
          conn
          |> put_status(500)
          |> json(%{message: "An unknown error occured", data: changeset.changes})
      end
    else
      conn |> send_resp(400,  "Invalid data supplied")
    end
  end
end
