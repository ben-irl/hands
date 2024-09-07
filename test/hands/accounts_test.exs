defmodule Hands.AccountsTest do
  use Hands.DataCase

  alias Hands.Accounts

  import Hands.AccountsFixtures
  alias Hands.Accounts.{Member, MemberToken}

  describe "get_member_by_email/1" do
    test "does not return the member if the email does not exist" do
      refute Accounts.get_member_by_email("unknown@example.com")
    end

    test "returns the member if the email exists" do
      %{id: id} = member = member_fixture()
      assert %Member{id: ^id} = Accounts.get_member_by_email(member.email)
    end
  end

  describe "get_member_by_email_and_password/2" do
    test "does not return the member if the email does not exist" do
      refute Accounts.get_member_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the member if the password is not valid" do
      member = member_fixture()
      refute Accounts.get_member_by_email_and_password(member.email, "invalid")
    end

    test "returns the member if the email and password are valid" do
      %{id: id} = member = member_fixture()

      assert %Member{id: ^id} =
               Accounts.get_member_by_email_and_password(member.email, valid_member_password())
    end
  end

  describe "get_member!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_member!(-1)
      end
    end

    test "returns the member with the given id" do
      %{id: id} = member = member_fixture()
      assert %Member{id: ^id} = Accounts.get_member!(member.id)
    end
  end

  describe "register_member/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_member(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_member(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_member(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = member_fixture()
      {:error, changeset} = Accounts.register_member(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_member(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers accounts_members with a hashed password" do
      email = unique_member_email()
      {:ok, member} = Accounts.register_member(valid_member_attributes(email: email))
      assert member.email == email
      assert is_binary(member.hashed_password)
      assert is_nil(member.confirmed_at)
      assert is_nil(member.password)
    end
  end

  describe "change_member_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_member_registration(%Member{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_member_email()
      password = valid_member_password()

      changeset =
        Accounts.change_member_registration(
          %Member{},
          valid_member_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_member_email/2" do
    test "returns a member changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_member_email(%Member{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_member_email/3" do
    setup do
      %{member: member_fixture()}
    end

    test "requires email to change", %{member: member} do
      {:error, changeset} = Accounts.apply_member_email(member, valid_member_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{member: member} do
      {:error, changeset} =
        Accounts.apply_member_email(member, valid_member_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{member: member} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_member_email(member, valid_member_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{member: member} do
      %{email: email} = member_fixture()
      password = valid_member_password()

      {:error, changeset} = Accounts.apply_member_email(member, password, %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{member: member} do
      {:error, changeset} =
        Accounts.apply_member_email(member, "invalid", %{email: unique_member_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{member: member} do
      email = unique_member_email()
      {:ok, member} = Accounts.apply_member_email(member, valid_member_password(), %{email: email})
      assert member.email == email
      assert Accounts.get_member!(member.id).email != email
    end
  end

  describe "deliver_member_update_email_instructions/3" do
    setup do
      %{member: member_fixture()}
    end

    test "sends token through notification", %{member: member} do
      token =
        extract_member_token(fn url ->
          Accounts.deliver_member_update_email_instructions(member, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert member_token = Repo.get_by(MemberToken, token: :crypto.hash(:sha256, token))
      assert member_token.member_id == member.id
      assert member_token.sent_to == member.email
      assert member_token.context == "change:current@example.com"
    end
  end

  describe "update_member_email/2" do
    setup do
      member = member_fixture()
      email = unique_member_email()

      token =
        extract_member_token(fn url ->
          Accounts.deliver_member_update_email_instructions(%{member | email: email}, member.email, url)
        end)

      %{member: member, token: token, email: email}
    end

    test "updates the email with a valid token", %{member: member, token: token, email: email} do
      assert Accounts.update_member_email(member, token) == :ok
      changed_member = Repo.get!(Member, member.id)
      assert changed_member.email != member.email
      assert changed_member.email == email
      assert changed_member.confirmed_at
      assert changed_member.confirmed_at != member.confirmed_at
      refute Repo.get_by(MemberToken, member_id: member.id)
    end

    test "does not update email with invalid token", %{member: member} do
      assert Accounts.update_member_email(member, "oops") == :error
      assert Repo.get!(Member, member.id).email == member.email
      assert Repo.get_by(MemberToken, member_id: member.id)
    end

    test "does not update email if member email changed", %{member: member, token: token} do
      assert Accounts.update_member_email(%{member | email: "current@example.com"}, token) == :error
      assert Repo.get!(Member, member.id).email == member.email
      assert Repo.get_by(MemberToken, member_id: member.id)
    end

    test "does not update email if token expired", %{member: member, token: token} do
      {1, nil} = Repo.update_all(MemberToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_member_email(member, token) == :error
      assert Repo.get!(Member, member.id).email == member.email
      assert Repo.get_by(MemberToken, member_id: member.id)
    end
  end

  describe "change_member_password/2" do
    test "returns a member changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_member_password(%Member{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_member_password(%Member{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_member_password/3" do
    setup do
      %{member: member_fixture()}
    end

    test "validates password", %{member: member} do
      {:error, changeset} =
        Accounts.update_member_password(member, valid_member_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{member: member} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_member_password(member, valid_member_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{member: member} do
      {:error, changeset} =
        Accounts.update_member_password(member, "invalid", %{password: valid_member_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{member: member} do
      {:ok, member} =
        Accounts.update_member_password(member, valid_member_password(), %{
          password: "new valid password"
        })

      assert is_nil(member.password)
      assert Accounts.get_member_by_email_and_password(member.email, "new valid password")
    end

    test "deletes all tokens for the given member", %{member: member} do
      _ = Accounts.generate_member_session_token(member)

      {:ok, _} =
        Accounts.update_member_password(member, valid_member_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(MemberToken, member_id: member.id)
    end
  end

  describe "generate_member_session_token/1" do
    setup do
      %{member: member_fixture()}
    end

    test "generates a token", %{member: member} do
      token = Accounts.generate_member_session_token(member)
      assert member_token = Repo.get_by(MemberToken, token: token)
      assert member_token.context == "session"

      # Creating the same token for another member should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%MemberToken{
          token: member_token.token,
          member_id: member_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_member_by_session_token/1" do
    setup do
      member = member_fixture()
      token = Accounts.generate_member_session_token(member)
      %{member: member, token: token}
    end

    test "returns member by token", %{member: member, token: token} do
      assert session_member = Accounts.get_member_by_session_token(token)
      assert session_member.id == member.id
    end

    test "does not return member for invalid token" do
      refute Accounts.get_member_by_session_token("oops")
    end

    test "does not return member for expired token", %{token: token} do
      {1, nil} = Repo.update_all(MemberToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_member_by_session_token(token)
    end
  end

  describe "delete_member_session_token/1" do
    test "deletes the token" do
      member = member_fixture()
      token = Accounts.generate_member_session_token(member)
      assert Accounts.delete_member_session_token(token) == :ok
      refute Accounts.get_member_by_session_token(token)
    end
  end

  describe "deliver_member_confirmation_instructions/2" do
    setup do
      %{member: member_fixture()}
    end

    test "sends token through notification", %{member: member} do
      token =
        extract_member_token(fn url ->
          Accounts.deliver_member_confirmation_instructions(member, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert member_token = Repo.get_by(MemberToken, token: :crypto.hash(:sha256, token))
      assert member_token.member_id == member.id
      assert member_token.sent_to == member.email
      assert member_token.context == "confirm"
    end
  end

  describe "confirm_member/1" do
    setup do
      member = member_fixture()

      token =
        extract_member_token(fn url ->
          Accounts.deliver_member_confirmation_instructions(member, url)
        end)

      %{member: member, token: token}
    end

    test "confirms the email with a valid token", %{member: member, token: token} do
      assert {:ok, confirmed_member} = Accounts.confirm_member(token)
      assert confirmed_member.confirmed_at
      assert confirmed_member.confirmed_at != member.confirmed_at
      assert Repo.get!(Member, member.id).confirmed_at
      refute Repo.get_by(MemberToken, member_id: member.id)
    end

    test "does not confirm with invalid token", %{member: member} do
      assert Accounts.confirm_member("oops") == :error
      refute Repo.get!(Member, member.id).confirmed_at
      assert Repo.get_by(MemberToken, member_id: member.id)
    end

    test "does not confirm email if token expired", %{member: member, token: token} do
      {1, nil} = Repo.update_all(MemberToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_member(token) == :error
      refute Repo.get!(Member, member.id).confirmed_at
      assert Repo.get_by(MemberToken, member_id: member.id)
    end
  end

  describe "deliver_member_reset_password_instructions/2" do
    setup do
      %{member: member_fixture()}
    end

    test "sends token through notification", %{member: member} do
      token =
        extract_member_token(fn url ->
          Accounts.deliver_member_reset_password_instructions(member, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert member_token = Repo.get_by(MemberToken, token: :crypto.hash(:sha256, token))
      assert member_token.member_id == member.id
      assert member_token.sent_to == member.email
      assert member_token.context == "reset_password"
    end
  end

  describe "get_member_by_reset_password_token/1" do
    setup do
      member = member_fixture()

      token =
        extract_member_token(fn url ->
          Accounts.deliver_member_reset_password_instructions(member, url)
        end)

      %{member: member, token: token}
    end

    test "returns the member with valid token", %{member: %{id: id}, token: token} do
      assert %Member{id: ^id} = Accounts.get_member_by_reset_password_token(token)
      assert Repo.get_by(MemberToken, member_id: id)
    end

    test "does not return the member with invalid token", %{member: member} do
      refute Accounts.get_member_by_reset_password_token("oops")
      assert Repo.get_by(MemberToken, member_id: member.id)
    end

    test "does not return the member if token expired", %{member: member, token: token} do
      {1, nil} = Repo.update_all(MemberToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_member_by_reset_password_token(token)
      assert Repo.get_by(MemberToken, member_id: member.id)
    end
  end

  describe "reset_member_password/2" do
    setup do
      %{member: member_fixture()}
    end

    test "validates password", %{member: member} do
      {:error, changeset} =
        Accounts.reset_member_password(member, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{member: member} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_member_password(member, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{member: member} do
      {:ok, updated_member} = Accounts.reset_member_password(member, %{password: "new valid password"})
      assert is_nil(updated_member.password)
      assert Accounts.get_member_by_email_and_password(member.email, "new valid password")
    end

    test "deletes all tokens for the given member", %{member: member} do
      _ = Accounts.generate_member_session_token(member)
      {:ok, _} = Accounts.reset_member_password(member, %{password: "new valid password"})
      refute Repo.get_by(MemberToken, member_id: member.id)
    end
  end

  describe "inspect/2 for the Member module" do
    test "does not include password" do
      refute inspect(%Member{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "member_profiles" do
    alias Hands.Accounts.MemberProfile

    import Hands.AccountsFixtures

    @invalid_attrs %{name: nil, age: nil, gender: nil, want_genders: nil}

    test "list_member_profiles/0 returns all member_profiles" do
      member_profile = member_profile_fixture()
      assert Accounts.list_member_profiles() == [member_profile]
    end

    test "get_member_profile!/1 returns the member_profile with given id" do
      member_profile = member_profile_fixture()
      assert Accounts.get_member_profile!(member_profile.id) == member_profile
    end

    test "create_member_profile/1 with valid data creates a member_profile" do
      valid_attrs = %{name: "some name", age: 42, gender: "some gender", want_genders: "some want_genders"}

      assert {:ok, %MemberProfile{} = member_profile} = Accounts.create_member_profile(valid_attrs)
      assert member_profile.name == "some name"
      assert member_profile.age == 42
      assert member_profile.gender == "some gender"
      assert member_profile.want_genders == "some want_genders"
    end

    test "create_member_profile/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_member_profile(@invalid_attrs)
    end

    test "update_member_profile/2 with valid data updates the member_profile" do
      member_profile = member_profile_fixture()
      update_attrs = %{name: "some updated name", age: 43, gender: "some updated gender", want_genders: "some updated want_genders"}

      assert {:ok, %MemberProfile{} = member_profile} = Accounts.update_member_profile(member_profile, update_attrs)
      assert member_profile.name == "some updated name"
      assert member_profile.age == 43
      assert member_profile.gender == "some updated gender"
      assert member_profile.want_genders == "some updated want_genders"
    end

    test "update_member_profile/2 with invalid data returns error changeset" do
      member_profile = member_profile_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_member_profile(member_profile, @invalid_attrs)
      assert member_profile == Accounts.get_member_profile!(member_profile.id)
    end

    test "delete_member_profile/1 deletes the member_profile" do
      member_profile = member_profile_fixture()
      assert {:ok, %MemberProfile{}} = Accounts.delete_member_profile(member_profile)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_member_profile!(member_profile.id) end
    end

    test "change_member_profile/1 returns a member_profile changeset" do
      member_profile = member_profile_fixture()
      assert %Ecto.Changeset{} = Accounts.change_member_profile(member_profile)
    end
  end
end
