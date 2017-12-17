defmodule ProjectMeetings.Meeting do
  use Ecto.Schema
  import Ecto.Changeset
  alias ProjectMeetings.{Meeting, User}
  alias ProjectMeetings.Utils.FCM

  @firebase_url Application.get_env(:project_meetings, ProjectMeetingsWeb.Endpoint)[:firebase_url]
  @firebase_auth Application.get_env(:project_meetings, ProjectMeetingsWeb.Endpoint)[:firebase_auth]

  @public_user_values ["u_id", "email", "display_name"]

  @moduledoc """
  This is the Meeting module. It helps with validating meeting parameters before modifying their values in Firebase.
  """

  @doc false
  embedded_schema do
    field :drive_folder_id, :string
    field :invites, {:array, :string}
    field :m_id, :string
    field :time, :integer
    field :name, :string
    field :objective, :string
    field :time_limit, :integer
    field :u_id, :string
  end

  @doc """
  Validates the proposed attributes and returns a new Meeting changeset
  """
  def changeset(%Meeting{} = meeting, params) do
    user = if Map.has_key?(params, "u_id") do
      User.get_by_u_id!(params["u_id"])
    else
      nil
    end

    meeting
    |> cast(params, [:m_id, :u_id, :name, :objective, :time, :time_limit, :drive_folder_id, :invites])
    |> validate_required([:m_id, :u_id, :name, :objective, :time, :time_limit, :drive_folder_id])
    |> validate_length(:name, min: 1, max: 50)
    |> validate_length(:objective, max: 100)
    |> validate_number(:time, greater_than: DateTime.to_unix(DateTime.utc_now))
    |> validate_number(:time_limit, greater_than_or_equal_to: 60000)
    |> validate_creator(user, :u_id)
    |> validate_drive_folder_id(user, :u_id, :drive_folder_id)
    |> validate_invites(user, :invites)
  end

  @doc """
  Given a valid m_id, retrieves data on a Meeting from Firebase
  """
  def get(m_id) do
    url = "#{@firebase_url}/meetings/#{m_id}.json?auth=#{@firebase_auth}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{:status_code => 200, :body => body}} ->
        {:ok, body |> Poison.decode! |> Map.put("m_id", m_id)}
      {:ok, %HTTPoison.Response{:status_code => status_code}} ->
        {:error, status_code}
    end
  end

  @doc """
  Given a valid m_id, retrieves a Meeting from Firebase
  """
  def get!(m_id) do
    url = "#{@firebase_url}/meetings/#{m_id}.json?auth=#{@firebase_auth}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{:status_code => 200, :body => body}} ->
        body |> Poison.decode! |> Map.put("m_id", m_id)
      _error -> raise RuntimeError, message: "Error getting meeting #{m_id} from Firebase."
    end
  end

  @doc """
  Given a valid Meeting, puts a Meeting in Firebase
  """
  def put(meeting) do
    url = "#{@firebase_url}/meetings/#{meeting.m_id}.json?auth=#{@firebase_auth}"

    body = %{
      "u_id": meeting.u_id,
      "name": meeting.name,
      "objective": meeting.objective,
      "time": meeting.time,
      "time_limit": meeting.time_limit,
      "drive_folder_id": meeting.drive_folder_id
    }

    email = User.get_by_u_id!(meeting.u_id)["email"]
    |> String.replace(".", "__DOT__")

    User.create_meeting!(meeting.u_id, email, meeting)

    body = if Map.has_key?(meeting, :invites) do
      emails = Map.keys(meeting.invites)
      invites = Enum.reduce emails, %{}, fn email, inv_map ->
        user = meeting.invites[email]
        |> Map.take(@public_user_values)

        User.create_invite!(user["u_id"], user["email"], meeting)
        Map.put(inv_map, email, user)
      end

      Map.put(body, "invites", invites)
    else
      body
    end

    case HTTPoison.patch!(url, body |> Poison.encode!) do
       %HTTPoison.Response{:status_code => 200} -> {:ok, meeting}
       _else -> {:error, 500}
    end
  end

  @doc """
  Given a valid meeting and email, delets a Meeting from Firebase
  """
  def delete(meeting, user) do
    m_id = meeting["m_id"]
    url = "#{@firebase_url}/meetings/#{m_id}.json?auth=#{@firebase_auth}"

    if Map.has_key?(meeting, "invites") do
      Enum.each Map.keys(meeting["invites"]), fn email ->
        user = meeting["invites"][email]
        User.delete_invite!(user["u_id"], user["email"], m_id)
      end
    end

    User.delete_meeting!(meeting["u_id"], user["email"], m_id)

    case HTTPoison.delete!(url) do
      %HTTPoison.Response{:status_code => 200} -> {:ok, meeting}
      %HTTPoison.Response{:status_code => status_code} -> {:error, status_code}
      _else -> {:error, 500}
    end
  end

  @doc """
  Invite a specific user to a specified meeting
  """
  def create_invite!(meeting, u) do
    user = u |> Map.take(@public_user_values)

    u_id = user["u_id"]
    email = user["email"] |> String.replace(".", "__DOT__")
    url = "#{@firebase_url}/meetings/#{meeting["m_id"]}/invites/#{email}.json?auth=#{@firebase_auth}"

    with  true <- u == nil and u_id != meeting["u_id"],
          %HTTPoison.Response{:status_code => 200} <- HTTPoison.patch!(url, Poison.encode!(user)),
          %HTTPoison.Response{:status_code => 200} <- User.create_invite!(u_id, email, meeting)
    do
      spawn(FCM, :notify!, [:meeting_invite, [email], meeting])
      {:ok, meeting}
    else
      %HTTPoison.Response{:status_code => status_code} -> {:error, status_code}
      _else -> raise RuntimeError, "Email \"#{u["email"]}\" invalid."
    end
  end

  @doc """
  Remove a specific user from a specified meeting
  """
  def delete_invite!(meeting, user) do
    m_id = meeting["m_id"]
    u_id = user["u_id"]
    email = user["email"] |> String.replace(".", "__DOT__")
    url = "#{@firebase_url}/meetings/#{m_id}/invites/#{email}.json?auth=#{@firebase_auth}"
    
    User.delete_invite!(u_id, email, m_id)
    HTTPoison.delete!(url)
  end

  # Given a changeset and the u_id, validate the u_id
  defp validate_creator(changeset, user, :u_id) do
    if user != nil do
      changeset
    else
      validate_change changeset, :u_id, fn _,_u_id ->
        [{:u_id, "Invalid u_id"}]
      end
    end
  end

  # Given a changeset, u_id, and drive_folder_id, validate the drive_folder_id
  defp validate_drive_folder_id(changeset, user, :u_id, :drive_folder_id) do
    if user != nil
        and drive_folder_exists?(user, changeset.changes.drive_folder_id) == true do
      changeset
    else
      validate_change changeset, :drive_folder_id, fn _, _drive_folder_id ->
        [{:drive_folder_id, "Invalid drive folder"}]
      end
    end
  end

  # Given a changeset and proposed invites, validate the invites
  defp validate_invites(changeset, user, :invites) do
    invites = if Map.has_key?(changeset.changes, :invites) do
      changeset.changes.invites
    else
      nil
    end

    valid = if invites != nil and length(invites) > 0 and user != nil do
      if (Enum.member?(invites, user["email"])) do
         false
      else
        case validate_users(invites) do
          {:ok, users} ->
            changeset = put_change(changeset, :invites, users)
            true
          _error -> false
        end
      end
    else
      true
    end

    if valid do
      changeset
    else
      validate_change changeset, :invites, fn _atom, _invites ->
        [{:invites, "Invalid Invites"}]
      end
    end
  end

  # Given invited users, verify users exists
  defp validate_users([email | tail] = users) when length(users) > 1 do
    with  {:ok, user} <- User.get_by_email(email),
          {:ok, users} <- validate_users(tail)
    do
      {:ok, Map.put(users, "#{String.replace(email, ".", "__DOT__")}", user)}
    else
      _error -> {:error, "Invalid users"}
    end
  end

  # Given invited user, verify user exists
  defp validate_users([email] = _user) do
    case User.get_by_email(email) do
        {:ok, user} ->
          {:ok, Map.put(%{}, "#{String.replace(email, ".", "__DOT__")}", user)}
        err -> err
    end
  end

  # Goven a u_id and a drive_folder_id, verify the folder's existence
  defp drive_folder_exists?(_user, drive_folder_id) do
    if is_binary(drive_folder_id) and String.length(drive_folder_id) > 0 do
      true
    else
      false
    end

    # url = "https://www.googleapis.com/drive/v3/files/#{drive_folder_id}"
    # headers = ["Authorization": "Bearer #{user["google_token"]}"]
    #
    # IO.inspect HTTPoison.get(url, headers)
    #
    # case HTTPoison.get(url, headers) do
    #   {:ok, %HTTPoison.Response{:status_code => 200,
    #     :body => %{mime_type: "application/vnd.google-apps.folder"}}} -> true
    #   {_code, _response} -> false
    # end
  end

end
