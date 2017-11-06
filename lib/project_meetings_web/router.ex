defmodule ProjectMeetingsWeb.Router do
  use ProjectMeetingsWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug ProjectMeetingsWeb.Plugs.UserAuth
  end

  scope "/", ProjectMeetingsWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/api/users/create", ProjectMeetingsWeb do
    pipe_through :api

    post "/", UserController, :create # Create a user
  end

  scope "/api/users", ProjectMeetingsWeb do
    pipe_through :api_auth

    get "/email/:email", UserController, :show_by_email # Get one user by email
    get "/uid/:u_id", UserController, :show_by_u_id # Get one user by u_id

    delete "/invites", UserController, :delete_invite # Reject an invite
  end

  scope "/api/meetings", ProjectMeetingsWeb do
    pipe_through :api_auth

    post "/", MeetingController, :update # Create a meeting

    get "/:m_id", MeetingController, :show # Get one meeting
    put "/:m_id", MeetingController, :update # Update a meeting
    delete "/:m_id", MeetingController, :delete # Delete a meeting

    post "/:m_id/invites", MeetingController, :create_invite # Create an invite
    delete "/:m_id/invites", MeetingController, :delete_invite # Retract an invite
  end
end
