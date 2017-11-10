defmodule ProjectMeetingsWeb.UserController do
  use ProjectMeetingsWeb, :controller

  alias ProjectMeetings.{Meeting, User}

  @moduledoc """
  This controller assists with manipulating ProjectMeetings.User objects in
  Firebase as well as the entities they influence.
  """

  @doc """
  Creates/updates a ProjectMeetings.User object in Firebase
  """
  def update(conn, params) do
    changeset = with [token | _tail] <- conn |> get_req_header("token"),
      {:ok, user} <- User.get_by_firebase_token(token)
    do
      User.changeset_update(%User{}, Map.merge(user, params) |> Map.delete("invites"))
    else
      _no_token -> User.changeset(%User{}, params |> Map.delete("invites"))
    end

    if changeset.valid? do
      try do
        case User.put(changeset.changes) do
          {:ok, user} -> json(conn, user)
          {:error, _status_code} ->
            conn
            |> put_status(500)
            |> json(%{message: "An unknown error occured", data: changeset.changes})
        end
      rescue
         e in RuntimeError -> conn |> send_resp(500, e.message)
      end
    else
      errors = Enum.reduce changeset.errors, %{}, fn err, err_map ->
        name = Kernel.elem(err, 0)
        msg = Kernel.elem(err, 1) |> Kernel.elem(0)

        Map.put(err_map, name, msg)
      end

      conn
      |> put_status(400)
      |> json(%{message: "Invalid data supplied", errors: errors})
    end
  end

  @doc """
  Retrieves info on a specified ProjectMeetings.User object in Firebase by email
  """
  def show_by_email(conn, params) do
    try do
      case User.get_by_email(params["email"]) do
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
    try do
      case User.get_by_u_id(params["u_id"]) do
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
