defmodule ProjectMeetingsWeb.Router do
  use ProjectMeetingsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :browser_auth do
    plug ProjectMeetingsWeb.Plugs.UserWsAuth
    plug :put_user_token
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug ProjectMeetingsWeb.Plugs.UserApiAuth
  end

  scope "/", ProjectMeetingsWeb do
    pipe_through :browser # Use the default browser stack
    get "/", PageController, :index
  end

  scope "/socket", ProjectMeetingsWeb do
    pipe_through :browser # Use the default browser stack
    pipe_through :browser_auth

    get "/", PageController, :index
  end

  scope "/api/users", ProjectMeetingsWeb do
    pipe_through :api

    put "/", UserController, :update # Create/update a user

    pipe_through :api_auth

    get "/email/:email", UserController, :show_by_email # Get one user by email
    get "/uid/:u_id", UserController, :show_by_u_id # Get one user by u_id

    delete "/invites/:m_id", UserController, :delete_invite # Reject an invite
  end

  scope "/api/meetings", ProjectMeetingsWeb do
    pipe_through :api_auth

    post "/", MeetingController, :create # Create a meeting

    get "/:m_id", MeetingController, :show # Get one meeting
    put "/:m_id", MeetingController, :update # Update a meeting
    delete "/:m_id", MeetingController, :delete # Delete a meeting

    post "/:m_id/invites", MeetingController, :create_invites # Create an invite
    delete "/:m_id/invites", MeetingController, :delete_invites # Retract an invite
  end

  defp put_user_token(conn, _) do
    IO.puts "PUT"
    if current_user = conn.assigns[:user] do
      token = Phoenix.Token.sign(conn, "user socket", current_user)
      assign(conn, :user_token, token)
    else
      conn
    end
  end
end
