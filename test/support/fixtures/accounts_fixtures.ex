defmodule Hands.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Hands.Accounts` context.
  """

  def unique_member_email, do: "member#{System.unique_integer()}@example.com"
  def valid_member_password, do: "hello world!"

  def valid_member_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_member_email(),
      password: valid_member_password()
    })
  end

  def member_fixture(attrs \\ %{}) do
    {:ok, member} =
      attrs
      |> valid_member_attributes()
      |> Hands.Accounts.register_member()

    member
  end

  def extract_member_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end

  @doc """
  Generate a member_profile.
  """
  def member_profile_fixture(member, attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        age: 42,
        gender: "man",
        name: "some name",
        want_genders: ["woman"],
      })

    {:ok, member_profile} = Hands.Accounts.create_member_profile(member, attrs)

    member_profile
  end
end
