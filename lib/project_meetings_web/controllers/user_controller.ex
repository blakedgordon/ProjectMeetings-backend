defmodule ProjectMeetingsWeb.UserController do
  use ProjectMeetingsWeb, :controller

  alias ProjectMeetings.{Meeting, User}

  @moduledoc """
  This controller assists with manipulating ProjectMeetings.User objects in
  Firebase as well as the entities they influence.
  """

  @doc """
  Creates a new ProjectMeetings.User object in Firebase
  """
  def create(conn, params) do
    changeset = User.changeset(%User{}, params |> Map.delete("invites"))

    if changeset.valid? do
      case User.put(changeset.changes) do
        {:ok, user} -> json(conn, user)
        {:error, _status_code} ->
          conn
          |> put_status(500)
          |> json(%{message: "An unknown error occured", data: changeset.changes})
      end
    else
      conn |> send_resp(400,  "Invalid data supplied")
    end
  end

  @doc """
  Retrieves info on a specified ProjectMeetings.User object in Firebase by email
  """
  def show_by_email(conn, params) do
    try do
      case User.get_by_email!(params["email"]) do
        {:ok, user} ->
          json(conn, Map.drop(user, ["googleToken", "firebaseToken"]))
        {:error, _status_code} ->
          conn |> send_resp(500, "An unknown error occured")
      end
    rescue
      e in RuntimeError -> conn |> send_resp(500, e.message)
    end
  end

  @doc """
  Retrieves info on a specified ProjectMeetings.User object in Firebase by u_id
  """
  def show_by_u_id(conn, params) do
    case User.get_by_u_id(params["u_id"]) do
      {:ok, user} ->
        json(conn, Map.drop(user, ["googleToken", "firebaseToken"]))
      {:error, _status_code} ->
        conn |> send_resp(500, "An unknown error occured")
    end
  end

  @doc """
  Removes an existing invite from the sepcified ProjectMeetings.Meeting entity
  """
  def delete_invite(conn, params) do
    user = conn.assigns.user
    m_id = params["m_id"]

    if Map.has_key?(user, "invites") and Map.has_key?(user["invites"], m_id) do
      try do
        Meeting.delete_invite!(Meeting.get!(m_id), user)

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
end
