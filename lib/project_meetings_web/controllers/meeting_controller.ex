defmodule ProjectMeetingsWeb.MeetingController do
  use ProjectMeetingsWeb, :controller

  alias Ecto.UUID
  alias ProjectMeetings.{Meeting, User}

  @moduledoc """
  This controller assists with manipulating ProjectMeetings.Meeting objects in
  Firebase as well as the entities they influence.
  """

  @doc """
  Creates a new ProjectMeetings.Meeting object in Firebase
  """
  def create(conn, params) do
    meeting = params
    |> Map.put("u_id", conn.assigns.user["u_id"])
    |> Map.put("m_id", UUID.generate)

    handle_changeset_and_insert(conn, meeting)
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
    user = conn.assigns.user
    m_id = params["m_id"]

    if (Map.has_key?(user, "invites") and Map.has_key?(user["invites"], m_id))
        or (Map.has_key?(user, "meetings") and Map.has_key?(user["meetings"], m_id)) do
      meeting = params
      |> Map.put("u_id", user["u_id"])
      |> Map.put("m_id", m_id)
      |> Map.delete("invites")

      handle_changeset_and_insert(conn, meeting)
    else
      conn |> send_resp(401, "Unauthorized")
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
          {:ok, _status} -> conn |> send_resp(200,  "Deleted meeting #{m_id}")
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
  Invites another user to the sepcified ProjectMeetings.Meeting entity.
  """
  def create_invite(conn, params) do
    user = conn.assigns.user
    m_id = params["m_id"]

    if Map.has_key?(user, "meetings") and Map.has_key?(user["meetings"], m_id) do
      try do
        Enum.each params["emails"], fn email ->
          Meeting.add_invite!(Meeting.get!(m_id), User.get_by_email!(email))
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

  @doc """
  Removes an existing invite from the sepcified ProjectMeetings.Meeting entity
  """
  def delete_invite(conn, params) do
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

  # Helps with validating a changeset and inserting a new ProjectMeetings.Meeting entity
  defp handle_changeset_and_insert(conn, params) do
    changeset = Meeting.changeset(%Meeting{}, params)

    if changeset.valid? do
      case Meeting.put(changeset.changes) do
        {:ok, meeting} ->
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
