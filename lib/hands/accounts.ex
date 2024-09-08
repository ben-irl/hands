defmodule Hands.Accounts do
  @moduledoc """
  The Accounts context.
  """

  alias Hands.Accounts.Member
  alias Hands.Accounts.MemberProfile
  alias Hands.Accounts.MemberToken
  alias Hands.Accounts.MemberNotifier
  alias Hands.Repo
  import Ecto.Query, warn: false

  ## Database getters

  @doc """
  Gets a member by email.

  ## Examples

      iex> get_member_by_email("foo@example.com")
      %Member{}

      iex> get_member_by_email("unknown@example.com")
      nil

  """
  def get_member_by_email(email) when is_binary(email) do
    Repo.get_by(Member, email: email)
  end

  @doc """
  Gets a member by email and password.

  ## Examples

      iex> get_member_by_email_and_password("foo@example.com", "correct_password")
      %Member{}

      iex> get_member_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_member_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    member = Repo.get_by(Member, email: email)
    if Member.valid_password?(member, password), do: member
  end

  @doc """
  Gets a single member.

  Raises `Ecto.NoResultsError` if the Member does not exist.

  ## Examples

      iex> get_member!(123)
      %Member{}

      iex> get_member!(456)
      ** (Ecto.NoResultsError)

  """
  def get_member!(id), do: Repo.get!(Member, id)

  ## Member registration

  @doc """
  Registers a member.

  ## Examples

      iex> register_member(%{field: value})
      {:ok, %Member{}}

      iex> register_member(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_member(attrs) do
    %Member{}
    |> Member.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking member changes.

  ## Examples

      iex> change_member_registration(member)
      %Ecto.Changeset{data: %Member{}}

  """
  def change_member_registration(%Member{} = member, attrs \\ %{}) do
    Member.registration_changeset(member, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the member email.

  ## Examples

      iex> change_member_email(member)
      %Ecto.Changeset{data: %Member{}}

  """
  def change_member_email(member, attrs \\ %{}) do
    Member.email_changeset(member, attrs, validate_email: false)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_member_email(member, "valid password", %{email: ...})
      {:ok, %Member{}}

      iex> apply_member_email(member, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_member_email(member, password, attrs) do
    member
    |> Member.email_changeset(attrs)
    |> Member.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  @doc """
  Updates the member email using the given token.

  If the token matches, the member email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_member_email(member, token) do
    context = "change:#{member.email}"

    with {:ok, query} <- MemberToken.verify_change_email_token_query(token, context),
         %MemberToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(member_email_multi(member, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp member_email_multi(member, email, context) do
    changeset =
      member
      |> Member.email_changeset(%{email: email})
      |> Member.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:member, changeset)
    |> Ecto.Multi.delete_all(:tokens, MemberToken.by_member_and_contexts_query(member, [context]))
  end

  @doc ~S"""
  Delivers the update email instructions to the given member.

  ## Examples

      iex> deliver_member_update_email_instructions(member, current_email, &url(~p"/account/settings/confirm_email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_member_update_email_instructions(%Member{} = member, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, member_token} = MemberToken.build_email_token(member, "change:#{current_email}")

    Repo.insert!(member_token)
    MemberNotifier.deliver_update_email_instructions(member, update_email_url_fun.(encoded_token))
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the member password.

  ## Examples

      iex> change_member_password(member)
      %Ecto.Changeset{data: %Member{}}

  """
  def change_member_password(member, attrs \\ %{}) do
    Member.password_changeset(member, attrs, hash_password: false)
  end

  @doc """
  Updates the member password.

  ## Examples

      iex> update_member_password(member, "valid password", %{password: ...})
      {:ok, %Member{}}

      iex> update_member_password(member, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_member_password(member, password, attrs) do
    changeset =
      member
      |> Member.password_changeset(attrs)
      |> Member.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:member, changeset)
    |> Ecto.Multi.delete_all(:tokens, MemberToken.by_member_and_contexts_query(member, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{member: member}} -> {:ok, member}
      {:error, :member, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_member_session_token(member) do
    {token, member_token} = MemberToken.build_session_token(member)
    Repo.insert!(member_token)
    token
  end

  @doc """
  Gets the member with the given signed token.
  """
  def get_member_by_session_token(token) do
    {:ok, query} = MemberToken.verify_session_token_query(token)

    query
    |> Repo.one()
    |> preload_member_assocs!()
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_member_session_token(token) do
    Repo.delete_all(MemberToken.by_token_and_context_query(token, "session"))
    :ok
  end

  ## Confirmation

  @doc ~S"""
  Delivers the confirmation email instructions to the given member.

  ## Examples

      iex> deliver_member_confirmation_instructions(member, &url(~p"/account/confirm/#{&1}"))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_member_confirmation_instructions(confirmed_member, &url(~p"/account/confirm/#{&1}"))
      {:error, :already_confirmed}

  """
  def deliver_member_confirmation_instructions(%Member{} = member, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if member.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, member_token} = MemberToken.build_email_token(member, "confirm")
      Repo.insert!(member_token)
      MemberNotifier.deliver_confirmation_instructions(member, confirmation_url_fun.(encoded_token))
    end
  end

  @doc """
  Confirms a member by the given token.

  If the token matches, the member account is marked as confirmed
  and the token is deleted.
  """
  def confirm_member(token) do
    with {:ok, query} <- MemberToken.verify_email_token_query(token, "confirm"),
         %Member{} = member <- Repo.one(query),
         {:ok, %{member: member}} <- Repo.transaction(confirm_member_multi(member)) do
      {:ok, member}
    else
      _ -> :error
    end
  end

  defp confirm_member_multi(member) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:member, Member.confirm_changeset(member))
    |> Ecto.Multi.delete_all(:tokens, MemberToken.by_member_and_contexts_query(member, ["confirm"]))
  end

  ## Reset password

  @doc ~S"""
  Delivers the reset password email to the given member.

  ## Examples

      iex> deliver_member_reset_password_instructions(member, &url(~p"/account/reset_password/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_member_reset_password_instructions(%Member{} = member, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, member_token} = MemberToken.build_email_token(member, "reset_password")
    Repo.insert!(member_token)
    MemberNotifier.deliver_reset_password_instructions(member, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the member by reset password token.

  ## Examples

      iex> get_member_by_reset_password_token("validtoken")
      %Member{}

      iex> get_member_by_reset_password_token("invalidtoken")
      nil

  """
  def get_member_by_reset_password_token(token) do
    with {:ok, query} <- MemberToken.verify_email_token_query(token, "reset_password"),
         %Member{} = member <- Repo.one(query) |> preload_member_assocs!() do
      member
    else
      _ -> nil
    end
  end

  @doc """
  Resets the member password.

  ## Examples

      iex> reset_member_password(member, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %Member{}}

      iex> reset_member_password(member, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_member_password(member, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:member, Member.password_changeset(member, attrs))
    |> Ecto.Multi.delete_all(:tokens, MemberToken.by_member_and_contexts_query(member, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{member: member}} -> {:ok, member}
      {:error, :member, changeset, _} -> {:error, changeset}
    end
  end


  # TODO: Refactor - see `docs/hack.md`
  def preload_member_assocs!(changeset) do
    Repo.preload(changeset, :profile)
  end

  @doc """
  Gets a single member_profile.

  Raises `Ecto.NoResultsError` if the Member profile does not exist.

  ## Examples

      iex> get_member_profile!(123)
      %MemberProfile{}

      iex> get_member_profile!(456)
      ** (Ecto.NoResultsError)

  """
  def get_member_profile!(id), do: Repo.get!(MemberProfile, id) |> preload_member_profile_assocs!()

  def get_member_profile_by_member!(%Member{id: member_id}) do
    get_member_profile_by_member!(member_id)
  end

  def get_member_profile_by_member!(member) do
    member_id =
      case member do
        id when is_binary(id) -> id
        %Member{id: id} -> id
      end

    query = from mp in MemberProfile, where: mp.member_id == ^member_id, preload: [:member]

    Repo.one!(query)
  end

  def fetch_member_profile_by_member_id!(member_id) do
    query = from mp in MemberProfile, where: mp.member_id == ^member_id, preload: [:member]

    Repo.one!(query)
  end

  @doc """
  Creates a member_profile.

  ## Examples

      iex> create_member_profile(member, %{field: value})
      {:ok, %MemberProfile{}}

      iex> create_member_profile(member, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_member_profile(member, attrs \\ %{}) do
    %MemberProfile{}
    |> MemberProfile.changeset(attrs)
    |> MemberProfile.put_member(member)
    |> Repo.insert()
  end

  @doc """
  Updates a member_profile.

  ## Examples

      iex> update_member_profile(member_profile, %{field: new_value})
      {:ok, %MemberProfile{}}

      iex> update_member_profile(member_profile, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_member_profile(%MemberProfile{} = member_profile, attrs) do
    member_profile
    |> MemberProfile.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a member_profile.

  ## Examples

      iex> delete_member_profile(member_profile)
      {:ok, %MemberProfile{}}

      iex> delete_member_profile(member_profile)
      {:error, %Ecto.Changeset{}}

  """
  def delete_member_profile(%MemberProfile{} = member_profile) do
    Repo.delete(member_profile)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking member_profile changes.

  ## Examples

      iex> change_member_profile(member_profile)
      %Ecto.Changeset{data: %MemberProfile{}}

  """
  def change_member_profile(%MemberProfile{} = member_profile, attrs \\ %{}) do
    MemberProfile.changeset(member_profile, attrs)
  end

  # TODO: Refactor - see `docs/hack.md`
  def preload_member_profile_assocs!(struct) do
    Repo.preload(struct, [:member])
  end
end
