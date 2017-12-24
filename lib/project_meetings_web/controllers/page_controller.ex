defmodule ProjectMeetingsWeb.PageController do
  use ProjectMeetingsWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def privacy_policy(conn, _params) do
    render conn, "privacy_policy.html"
  end
end
