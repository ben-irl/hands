# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Hands.Repo.insert!(%Hands.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

placeholders = %{inserted_at: DateTime.truncate(DateTime.utc_now(), :second)}

# For Demo

demo_members =
  Enum.map(1..2, fn n ->
    %{
      id: Ecto.UUID.generate(),
      email: "test#{n}@example.com",
      hashed_password: Bcrypt.hash_pwd_salt("passwordpassword"),
      inserted_at: {:placeholder, :inserted_at},
      updated_at: {:placeholder, :inserted_at}
    }
  end)

demo_member_profiles =
  Enum.map(demo_members, fn %{id: member_id} ->
    %{
      id: Ecto.UUID.generate(),
      member_id: member_id,
      name: Faker.Person.first_name(),
      age: Enum.random(19..60),
      # TODO: Make random, matching algo doesnt do anything so this isnt problem.
      gender: Enum.random([:woman, :man, :non_binary]),
      want_genders: Enum.random([["woman", "man", "non_binary"], ["woman"], ["man"]]),
      is_ready: true,
      inserted_at: {:placeholder, :inserted_at},
      updated_at: {:placeholder, :inserted_at}
    }
  end)

Hands.Repo.insert_all(Hands.Accounts.Member, demo_members, placeholders: placeholders)
Hands.Repo.insert_all(Hands.Accounts.MemberProfile, demo_member_profiles, placeholders: placeholders)

# Seed

members =
  Enum.map(1..1, fn _ ->
    %{
      id: Ecto.UUID.generate(),
      email: Faker.Internet.safe_email(),
      hashed_password: Bcrypt.hash_pwd_salt("password"),
      inserted_at: {:placeholder, :inserted_at},
      updated_at: {:placeholder, :inserted_at}
    }
  end)

member_profiles =
  Enum.map(members, fn  %{id: member_id} ->
    %{
      id: Ecto.UUID.generate(),
      member_id: member_id,
      name: Faker.Person.first_name(),
      age: Enum.random(19..60),
      # TODO: Make random, matching algo doesnt do anything so this isnt problem.
      gender: Enum.random([:woman, :man, :non_binary]),
      want_genders: Enum.random([["woman", "man", "non_binary"], ["woman"], ["man"]]),
      is_ready: true,
      inserted_at: {:placeholder, :inserted_at},
      updated_at: {:placeholder, :inserted_at}
    }
  end)

Hands.Repo.insert_all(Hands.Accounts.Member, members, placeholders: placeholders)
Hands.Repo.insert_all(Hands.Accounts.MemberProfile, member_profiles, placeholders: placeholders)
