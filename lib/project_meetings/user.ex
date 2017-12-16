defmodule ProjectMeetings.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Joken
  alias ProjectMeetings.{Meeting, User}

  @firebase_url Application.get_env(:project_meetings, ProjectMeetingsWeb.Endpoint)[:firebase_url]
  @firebase_auth Application.get_env(:project_meetings, ProjectMeetingsWeb.Endpoint)[:firebase_auth]

  @firebase_aud Application.get_env(:project_meetings, ProjectMeetingsWeb.Endpoint)[:firebase_aud]
  @firebase_iss Application.get_env(:project_meetings, ProjectMeetingsWeb.Endpoint)[:firebase_iss]

  @google_aud Application.get_env(:project_meetings, ProjectMeetingsWeb.Endpoint)[:google_aud]
  @google_iss Application.get_env(:project_meetings, ProjectMeetingsWeb.Endpoint)[:google_iss]


  @moduledoc """
  This is the User module. It helps with validating users before modifying their values in Firebase.
  """

  @doc false
  embedded_schema do
    field :display_name, :string
    field :email, :string
    field :firebase_token, :string
    field :google_token, :string
    field :instance_id, :string
    field :invites, {:array, :string}
    field :u_id, :string
  end

  @doc """
  Validates the proposed attributes and creates a new User changeset
  """
  def changeset(%User{} = user, params) do
    user
    |> cast(params, [:display_name, :email, :google_token, :firebase_token, :instance_id, :invites])
    |> validate_required([:display_name, :email, :google_token, :firebase_token, :instance_id])
    |> validate_google_token(:google_token)
    |> validate_firebase_token(:firebase_token) # Will assign u_id
    |> validate_required([:u_id])
    |> validate_length(:display_name, min: 2, max: 64)
    |> validate_length(:email, min: 2, max: 64)
    |> validate_format(:email, ~r/@/)
  end

  @doc """
  Validates the proposed attributes and updates a User changeset
  """
  def changeset_update(%User{} = old_user, params, tokens) do
    user = old_user
    |> cast(params, [:u_id, :display_name, :email, :google_token, :firebase_token, :instance_id])
    |> validate_required([:u_id, :display_name, :email, :google_token, :firebase_token, :instance_id])
    |> validate_length(:display_name, min: 2, max: 64)
    |> validate_length(:email, min: 2, max: 64)
    |> validate_format(:email, ~r/@/)

    firebase_user = get_by_u_id!(params["u_id"])

    user = if :firebase in tokens and
        params["firebase_token"] == firebase_user["firebase_token"] do
      user |> validate_firebase_token(:firebase_token)
    else
      user
    end

    if :google in tokens and
        params["google_token"] == firebase_user["google_token"] do
      user |> validate_google_token(:google_token)
    else
      user
    end
  end

  @doc """
  Given a valid email, retrieves a user from Firebase
  """
  def get_by_email(email) do
    url = "#{@firebase_url}/users_by_email/#{String.replace(email, ".", "__DOT__")}.json?auth=#{@firebase_auth}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{:status_code => 200, :body => body}} ->
        {:ok, body |> Poison.decode! |> Map.put("email", email)}
      {:ok, response} -> {:error, response}
    end
  end

  @doc """
  Given a valid email, retrieves a user from Firebase
  """
  def get_by_email!(email) do
    url = "#{@firebase_url}/users_by_email/#{String.replace(email, ".", "__DOT__")}.json?auth=#{@firebase_auth}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{:status_code => 200, :body => body}} ->
        body |> Poison.decode! |> Map.put("email", email)
      _error -> raise RuntimeError, message: "Error getting user by email #{email} from Firebase."
    end
  end

  @doc """
  Given a valid u_id, retrieves a user from Firebase
  """
  def get_by_u_id(u_id) do
    url = "#{@firebase_url}/users/#{u_id}.json?auth=#{@firebase_auth}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{:status_code => 200, :body => body}} ->
        {:ok, body |> Poison.decode! |> Map.put("u_id", u_id)}
      {:ok, response} -> {:error, response}
      _else -> {:error, 500}
    end
  end

  @doc """
  Given a valid u_id, retrieves a user from Firebase
  """
  def get_by_u_id!(u_id) do
    url = "#{@firebase_url}/users/#{u_id}.json?auth=#{@firebase_auth}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{:status_code => 200, :body => body}} ->
        body |> Poison.decode! |> Map.put("u_id", u_id)
      _error -> raise RuntimeError, message: "Error getting user by u_id #{u_id} from Firebase."
    end
  end

  @doc """
  Given a valid Firebase JWT, retrieves a User from Firebase
  """
  def get_by_firebase_token(token) do
    case decode_firebase_jwt(token) do
      {:ok, %{"sub" => u_id}} -> get_by_u_id(u_id)
      err -> err
    end
  end

  @doc """
  Given a valid User, puts a User in Firebase
  """
  def put(user) when is_map(user) do
    u_id_url = "#{@firebase_url}/users/#{user.u_id}.json?auth=#{@firebase_auth}"

    email = String.replace(user.email, ".", "__DOT__")
    email_url = "#{@firebase_url}/users_by_email/#{email}.json?auth=#{@firebase_auth}"

    u_id_body = %{
      "display_name": user.display_name,
      "email": user.email,
      "google_token": user.google_token,
      "firebase_token": user.firebase_token,
      "instance_id": user.instance_id
    }

    email_body = %{
      "display_name": user.display_name,
      "u_id": user.u_id,
      "google_token": user.google_token,
      "firebase_token": user.firebase_token,
      "instance_id": user.instance_id
    }

    if Map.has_key?(user, "invites")  do
      invites = %{}

      Enum.each user.invites, fn m_id ->
        {:ok, meeting} = Meeting.get!(m_id)
        Map.put(invites, "#{m_id}",
          %{
            name: meeting.name,
            objective: meeting.objective,
            time: meeting.time,
            time_limit: meeting.time_limit
          })
      end

      Map.put(u_id_body, "invites", invites)
      Map.put(email_body, "invites", invites)
    end

    with  %HTTPoison.Response{:status_code => 200}
            <- HTTPoison.patch!(u_id_url, u_id_body |> Poison.encode!),
          %HTTPoison.Response{:status_code => 200}
            <- HTTPoison.patch!(email_url, email_body |> Poison.encode!)
    do
      {:ok, get_by_u_id!(user.u_id)}
    else
      %HTTPoison.Response{:status_code => status_code} -> {:error, status_code}
      _else -> {:error, 500}
    end
  end

  @doc """
  Create a specified meeting for the user
  """
  def create_meeting!(u_id, email, meeting) do
    u_id_url = "#{@firebase_url}/users/#{u_id}/meetings/#{meeting.m_id}.json?auth=#{@firebase_auth}"
    email_url = "#{@firebase_url}/users_by_email/#{String.replace(email, ".", "__DOT__")}/meetings/#{meeting.m_id}.json?auth=#{@firebase_auth}"

    body = %{
      "u_id": meeting.u_id,
      "name": meeting.name,
      "objective": meeting.objective,
      "time": meeting.time,
      "time_limit": meeting.time_limit,
      "drive_folder_id": meeting.drive_folder_id
    } |> Poison.encode!

    HTTPoison.patch!(u_id_url, body)
    HTTPoison.patch!(email_url, body)
  end

  @doc """
  Remove a specified meeting for the user
  """
  def delete_meeting!(u_id, email, m_id) do
    u_id_url = "#{@firebase_url}/users/#{u_id}/meetings/#{m_id}.json?auth=#{@firebase_auth}"
    email_url = "#{@firebase_url}/users_by_email/#{String.replace(email, ".", "__DOT__")}/meetings/#{m_id}.json?auth=#{@firebase_auth}"

    HTTPoison.delete!(u_id_url)
    HTTPoison.delete!(email_url)
  end

  @doc """
  Create a specified invite for the user
  """
  def create_invite!(u_id, email, meeting) do
    cond do
      Map.has_key?(meeting, :m_id) -> create_invite_atom_keys!(u_id, email, meeting)
      Map.has_key?(meeting, "m_id") -> create_invite_string_keys!(u_id, email, meeting)
      true ->  raise RuntimeError, message: "Invalid meeting specified"
    end
  end

  # Create a specified invite for the user while meeting map has atom keys.
  defp create_invite_atom_keys!(u_id, email, meeting) do
    u_id_url = "#{@firebase_url}/users/#{u_id}/invites/#{meeting.m_id}.json?auth=#{@firebase_auth}"
    email_url = "#{@firebase_url}/users_by_email/#{String.replace(email, ".", "__DOT__")}/invites/#{meeting.m_id}.json?auth=#{@firebase_auth}"

    body = %{
      "u_id": meeting.u_id,
      "name": meeting.name,
      "objective": meeting.objective,
      "time": meeting.time,
      "time_limit": meeting.time_limit,
      "drive_folder_id": meeting.drive_folder_id
    } |> Poison.encode!

    HTTPoison.patch!(u_id_url, body)
    HTTPoison.patch!(email_url, body)
  end

  # Create a specified invite for the user while meeting map has string keys.
  defp create_invite_string_keys!(u_id, email, meeting) do
    u_id_url = "#{@firebase_url}/users/#{u_id}/invites/#{meeting["m_id"]}.json?auth=#{@firebase_auth}"
    email_url = "#{@firebase_url}/users_by_email/#{String.replace(email, ".", "__DOT__")}/invites/#{meeting["m_id"]}.json?auth=#{@firebase_auth}"

    body = %{
      "u_id": meeting["u_id"],
      "name": meeting["name"],
      "objective": meeting["objective"],
      "time": meeting["time"],
      "time_limit": meeting["time_limit"],
      "drive_folder_id": meeting["drive_folder_id"]
    } |> Poison.encode!

    HTTPoison.patch!(u_id_url, body)
    HTTPoison.patch!(email_url, body)
  end

  @doc """
  Remove a specified invite for the user
  """
  def delete_invite!(u_id, email, m_id) do
    u_id_url = "#{@firebase_url}/users/#{u_id}/invites/#{m_id}.json?auth=#{@firebase_auth}"
    email_url = "#{@firebase_url}/users_by_email/#{String.replace(email, ".", "__DOT__")}/invites/#{m_id}.json?auth=#{@firebase_auth}"

    HTTPoison.delete!(u_id_url)
    HTTPoison.delete!(email_url)
  end

  # Given a changeset and a google token, validates the token
  defp validate_google_token(changeset, :google_token) do
    validate_change changeset, :google_token, fn _, token ->
      with {:ok, data} <- decode_google_jwt(token),
        true <- valid_data?(data, @google_aud, @google_iss)
      do []
      else
         _response ->
           [{:google_token, "Invalid token provided"}]
      end
    end
  end

  # Given a changeset and a firebase token, validates the token
  defp validate_firebase_token(changeset, :firebase_token) do
    with {:ok, data} <- decode_firebase_jwt(changeset.changes.firebase_token),
      true <- valid_data?(data, @firebase_aud, @firebase_iss)
    do
      change(changeset, u_id: data["sub"])
    else
      _error -> validate_change changeset, :firebase_token, fn _, _token ->
        [{:firebase_token, "Invalid token provided"}]
      end
    end
  end

  # Decodes a given Google token
  defp decode_google_jwt(token) do
    url = "https://www.googleapis.com/oauth2/v3/tokeninfo?id_token=#{token}"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        return_data = body
        |> Poison.decode!
        |> Map.update!("exp", &(String.to_integer(&1)))
        |> Map.update!("iat", &(String.to_integer(&1)))

        {:ok, return_data}
      {:ok, %HTTPoison.Response{:status_code => status_code}} ->
        {:error, status_code: status_code}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason: reason}
    end
  end

  # Given an aud list, checks if User data is valid
  defp valid_data?(%{"aud" => aud} = data, aud_list, valid_iss) when is_list(aud_list) do
    if aud in aud_list do
      current_time = DateTime.utc_now |> DateTime.to_unix

      {:ok, data}
      |> validate_exp(current_time)
      |> validate_iat(current_time)
      |> validate_iss(valid_iss)
      |> validate_sub
      |> case do
        {:ok, _data} -> true
        {:error, _errors} -> false
      end
    else
      false
    end
  end

  # Checks if User data is valid
  defp valid_data?(data, valid_aud, valid_iss) do
    current_time = DateTime.utc_now |> DateTime.to_unix
    {:ok, data}
    |> validate_exp(current_time)
    |> validate_iat(current_time)
    |> validate_aud(valid_aud)
    |> validate_iss(valid_iss)
    |> validate_sub
    |> case do
      {:ok, _data} -> true
      {:error, _errors} -> false
    end
  end

  # Decodes a given Firebase token
  defp decode_firebase_jwt(token) do
    case public_keys() do
      {:ok, keys} ->
        decode_firebase_jwt(token, keys)
      {:error, status} -> {:error, status}
    end
  end

  # Decodes a given Firebase token, given all possible keys
  defp decode_firebase_jwt(jwt, keys) do
    try do
      token = jwt |> token
      headers = token |> peek_header

      if headers["alg"] == "RS256" and Enum.member?(keys, headers["kid"]) do
        {:ok, token |> peek}
      else
        {:error, token}
      end
    rescue
      _err -> {:error, "Invalid token"}
    end
  end

  # Gets the possible keys a firebase token could be signed with
  defp public_keys do
    url = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com"

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body |> Poison.decode! |> Map.keys }
      {:ok, %HTTPoison.Response{:status_code => status_code}} ->
        {:error, status_code: status_code}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason: reason}
    end

  end

  # Validates a token's "exp" value
  defp validate_exp({:ok, %{"exp" => exp} = token}, current_time) do
    validate_gt_params_ok(token, exp, current_time, "exp")
  end

  # Validates a token's "iat" value
  defp validate_iat({:ok, %{"iat" => iat} = token}, current_time) do
    validate_gt_params_ok(token, current_time, iat, "iat")
  end

  # Validates a token's "iat" value, given an error changeset
  defp validate_iat({:error, %{:token => token} = return_data}, current_time) do
    validate_gt_params_error(return_data, current_time, token["iat"], "iat")
  end

  # Validates a token's "aud" value
  defp validate_aud({:ok, token}, valid_aud) do
    validate_eq_params_ok(token, valid_aud, "aud")
  end

  # Validates a token's "aud" value, given an error changeset
  defp validate_aud({:error, return_data}, valid_aud) do
    validate_eq_params_error(return_data, valid_aud, "aud")
  end

  # Validates a token's "iss" value
  defp validate_iss({:ok, token}, valid_iss) do
    validate_eq_params_ok(token, valid_iss, "iss")
  end

  # Validates a token's "iss" value, given an error changeset
  defp validate_iss({:error, return_data}, valid_iss) do
    validate_eq_params_error(return_data, valid_iss, "iss")
  end

  # Validates a token's "sub" value
  defp validate_sub({:ok, %{"sub" => sub} = token}) do
    if(String.trim(sub) != "") do
      {:ok, token}
    else
      {:error, %{token: token, rejected_claims: ["sub"]}}
    end
  end

  # Validates a token's "sub" value, given an error changeset
  defp validate_sub({:error, %{:token => token,
      :rejected_claims => rejected_claims} = return_data}) do
    if(String.trim(token["sub"]) != "") do
      {:error, return_data}
    else
      {:error, %{token: return_data["token"],
        rejected_claims: ["sub" | rejected_claims || []]}}
    end
  end

  # Validates a "greater than" relationship
  defp validate_gt_params_ok(token, gt_val, lt_val, param) do
    if gt_val > lt_val do
      {:ok, token}
    else
      {:error, %{token: token, rejected_claims: [param]}}
    end
  end

  # Validates a "greater than" relationship, given an error changeset
  defp validate_gt_params_error(return_data, gt_val, lt_val, param) do
    if gt_val > lt_val do
      {:error, return_data}
    else
      {:error, %{token: return_data["token"],
        rejected_claims: [param | return_data["rejected_claims"] || []]}}
    end
  end

  # Validates an "equal" relationship
  defp validate_eq_params_ok(token, val, param) do
    if token[param] == val do
      {:ok, token}
    else
      {:error, %{token: token, rejected_claims: [param]}}
    end
  end

  # Validates an "equal" relationship, given an error changeset
  defp validate_eq_params_error(%{:token => token,
      :rejected_claims => rejected_claims} = return_data, val, param) do
    if token[param] == val do
      {:error, return_data}
    else
      {:error, %{token: token, rejected_claims: [param | rejected_claims]}}
    end
  end

end
