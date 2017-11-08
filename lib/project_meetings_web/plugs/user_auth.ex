defmodule ProjectMeetingsWeb.Plugs.UserAuth do
  require Logger
  import Plug.Conn

  alias ProjectMeetings.User

  @moduledoc """
  This user authentication plug helps with verifying tokens and gathering data about the token's owner.
  """

  @doc """
  Initializes plug
  """
  def init(default), do: default

  @doc """
  Verifies the token and stores the associated user data in conn
  """
  def call(conn, _default) do
    with [token | _tail] <- conn |> get_req_header("token"),
      {:ok, user} <- User.get_by_firebase_token(token)
    do
      conn |> assign(:user, user)
    else
      _error ->
        conn
        |> send_resp(401, "Unauthorized AF, my dude")
        |> halt
    end
  end
end
