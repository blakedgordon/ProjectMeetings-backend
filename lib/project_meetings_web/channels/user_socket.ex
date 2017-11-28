defmodule ProjectMeetingsWeb.UserSocket do
  use Phoenix.Socket

  alias ProjectMeetings.User

  ## Channels
  channel "user:*", ProjectMeetingsWeb.UserChannel
  channel "meeting:*", ProjectMeetingsWeb.MeetingChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket,
    timeout: :infinity,
    check_origin: false,
    check_origin: ["//localhost", "//ec2-34-226-155-228.compute-1.amazonaws.com"],
    transport_log: false
  # transport :longpoll, Phoenix.Transports.LongPoll

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  def connect(%{"token" => token}, socket) do
    case User.get_by_firebase_token(token) do
      {:ok, current_user} ->
        {:ok, assign(socket, :current_user, current_user)}
      {:error, _reason} ->
        :error
    end
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     ProjectMeetingsWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
