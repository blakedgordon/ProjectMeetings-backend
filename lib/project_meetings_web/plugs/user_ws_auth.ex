defmodule ProjectMeetingsWeb.Plugs.UserWsAuth do
  require Logger
  import Plug.Conn

  alias ProjectMeetings.User

  @moduledoc """
  This user authentication plug helps with verifying tokens for websocket
  connections and gathering data about the token's owner.
  """

  @doc """
  Initializes plug
  """
  def init(default), do: default

  @doc """
  Verifies the token and stores the associated user data in conn
  """
  def call(conn, _default) do
    try do
      with token <- conn.query_params["token"],
        {:ok, user} <- User.get_by_firebase_token(token)
      do
        conn |> assign(:user, user)
      else
        _error ->
          IO.inspect ProjectMeetingsWeb.Presence.list("user:wKnVfBOGOWYUCBG9Bmon3ey8Kcn1")

          conn
          |> send_resp(401, "Unauthorized AF, my dude")
          |> halt
      end
    rescue
      e in RuntimeError ->
        conn
        |> send_resp(403, e.message)
        |> halt
    end
  end
end
