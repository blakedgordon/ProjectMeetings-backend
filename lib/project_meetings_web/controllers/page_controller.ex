defmodule ProjectMeetingsWeb.PageController do
  use ProjectMeetingsWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
