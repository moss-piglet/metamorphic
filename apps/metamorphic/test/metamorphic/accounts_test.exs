defmodule Metamorphic.AccountsTest do
  use Metamorphic.DataCase

  import Metamorphic.AccountsFixtures

  alias Metamorphic.Accounts
  alias Metamorphic.Accounts.{Person, PersonToken}
  alias Metamorphic.Repo

  @valid_attrs %{
    name: "Max Webb",
    pseudonym: "max",
    email: "max@example.com",
    password: "Testing Zoology Zooing Testology!",
    password_confirmation: "Testing Zoology Zooing Testology!",
    terms_of_use: true,
    role: :person
  }

  @valid_temp_email "max@example.com"
  @new_valid_password "New Valid Password Valid Password!"

  describe "Verify correct working of hashing" do
    setup do
      person = Repo.insert!(Person.registration_changeset(%Person{}, @valid_attrs))
      {:ok, person: person, email: @valid_attrs.email}
    end

    test "inserting a person sets the :email_hash field asymmetrically", %{person: person} do
      assert person.email_hash != person.email
      assert person.email_hash == @valid_temp_email
    end

    test ":email_hash field is the encrypted hash of the email", %{person: person} do
      person_from_db = Person |> Repo.one()
      assert person_from_db.email_hash != person.email
    end
  end

  describe "get_person_by_email/1" do
    test "does not return the person if the email does not exist" do
      refute Accounts.get_person_by_email("unknown@example.com")
    end

    test "returns the person if the email exists and verifies asymmetric encryption" do
      {person, temp_email, _, _} = person_fixture()
      %{id: id} = person
      assert is_nil(Accounts.get_person_by_email(person.email))
      assert %Person{id: ^id} = Accounts.get_person_by_email(temp_email)
    end
  end

  describe "get_person_by_email_and_password/1" do
    test "does not return the person if the email does not exist" do
      assert {:error, :bad_username_or_password} ==
               Accounts.get_person_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the person if the password is not valid" do
      {_, temp_email, _, _} = person_fixture()

      assert {:error, :bad_username_or_password} ==
               Accounts.get_person_by_email_and_password(temp_email, "invalid")
    end

    test "does not return the person if their account has not been confirmed" do
      {_, temp_email, _, _} = person_fixture(%{}, confirmed: false)

      assert {:error, :not_confirmed} ==
               Accounts.get_person_by_email_and_password(temp_email, valid_person_password())
    end

    test "returns the person if the email and password are valid" do
      {person, temp_email, _, _} = person_fixture()
      %{id: id} = person

      assert {:ok, %Person{id: ^id}} =
               Accounts.get_person_by_email_and_password(temp_email, valid_person_password())
    end

    test "does not return the person if they have been blocked" do
      {person, temp_email, _, _} = person_fixture()

      Accounts.block_person(person)

      assert {:error, :person_blocked} ==
               Accounts.get_person_by_email_and_password(temp_email, @valid_attrs.password)
    end
  end

  describe "block_person/1" do
    setup do
      {person, _, _, _} = person_fixture()
      token = Accounts.generate_person_session_token(person)

      %{
        person: person,
        token: token
      }
    end

    test "sets the is_blocked flag to true and removes any tokens belonging to the person", %{
      person: person,
      token: token
    } do
      assert {:ok, person} = Accounts.block_person(person)

      assert person.is_blocked == true
      refute Accounts.get_person_by_session_token(token)
    end
  end

  describe "unblock_person/1" do
    setup do
      {person, _, _, _} = person_fixture()

      {:ok, person} =
        person
        |> Accounts.block_person()

      %{person: person}
    end

    test "sets the is_blocked flag to false", %{person: person} do
      assert {:ok, person} = Accounts.unblock_person(person)
      assert person.is_blocked == false
    end
  end

  describe "get_person!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_person!(Ecto.UUID.generate())
      end
    end

    test "returns the person with the given id" do
      {person, _, _, _} = person_fixture()
      %{id: id} = person
      assert %Person{id: ^id} = Accounts.get_person!(person.id)
    end
  end

  describe "register_person/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_person(%{})

      assert %{
               name: ["can't be blank"],
               email: ["can't be blank"],
               password: ["can't be blank"],
               pseudonym: ["can't be blank"],
               terms_of_use: ["you must agree before continuing"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} =
        Accounts.register_person(%{
          email: "not valid",
          password: "not valid",
          password_confirmation: "not matching"
        })

      assert %{
               email: ["must have the @ sign, no spaces, and/or proper format"],
               password: [
                 "Uh oh! This password has appeared at least 7 times in data breaches. Please choose another password and change any accounts associated with this password.",
                 "at least one digit or special character",
                 "at least one upper case character",
                 "should be at least 20 character(s)"
               ],
               password_confirmation: ["does not match password"],
               name: ["can't be blank"],
               pseudonym: ["can't be blank"],
               terms_of_use: ["you must agree before continuing"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_person(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      {_person, temp_email, _, _} = person_fixture()
      {:error, changeset} = Accounts.register_person(%{email: temp_email})
      assert "invalid email" in errors_on(changeset).email_hash

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_person(%{email: String.upcase(temp_email)})
      assert "invalid email" in errors_on(changeset).email_hash
    end

    test "registers people with a hashed password and sets privileges to :person, verifies assymmetric hashing" do
      name = valid_person_name()
      pseudonym = unique_person_pseudonym()
      email = unique_person_email()
      password = valid_person_password()
      terms_of_use = valid_person_terms_of_use()

      {:ok, person} =
        Accounts.register_person(%{
          name: name,
          pseudonym: pseudonym,
          email: email,
          password: password,
          terms_of_use: terms_of_use
        })

      assert person.name != name
      assert person.pseudonym_hash == pseudonym
      assert person.email_hash == email
      assert is_binary(person.pseudonym_hash)
      assert is_binary(person.email_hash)
      assert is_binary(person.hashed_password)
      assert is_nil(person.confirmed_at)
      assert is_nil(person.password)
      assert person.privileges == :person
      assert person.privileges != :admin
    end

    test "when the person is created it creates a stripe_customer and billing_customer" do
      name = valid_person_name()
      pseudonym = unique_person_pseudonym()
      email = unique_person_email()
      password = valid_person_password()
      terms_of_use = valid_person_terms_of_use()

      Accounts.subscribe_on_person_created()

      {:ok, person} =
        Accounts.register_person(%{
          name: name,
          pseudonym: pseudonym,
          email: email,
          password: password,
          terms_of_use: terms_of_use
        })

      assert_received(%{person: ^person})
    end
  end

  describe "register_admin/1" do
    test "requires authorized name, pseudonym, email, password and terms to be set" do
      {:error, changeset} = Accounts.register_admin(%{})

      assert %{
               email: ["not an authorized admin"],
               password: ["can't be blank"],
               name: ["not an authorized admin"],
               pseudonym: ["not an authorized admin"],
               terms_of_use: ["you must agree before continuing"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} =
        Accounts.register_admin(%{
          email: "not valid",
          password: "not valid",
          password_confirmation: "not matching"
        })

      assert %{
               email: ["not an authorized admin"],
               name: ["not an authorized admin"],
               password: [
                 "Uh oh! This password has appeared at least 7 times in data breaches. Please choose another password and change any accounts associated with this password.",
                 "at least one digit or special character",
                 "at least one upper case character",
                 "should be at least 20 character(s)"
               ],
               password_confirmation: ["does not match password"],
               pseudonym: ["not an authorized admin"],
               terms_of_use: ["you must agree before continuing"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security regardless of authorization" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_admin(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "validates email authorization" do
      {_person, temp_email, _, _} = person_fixture()
      {:error, changeset} = Accounts.register_admin(%{email: temp_email})
      assert "not an authorized admin" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_admin(%{email: String.upcase(temp_email)})
      assert "not an authorized admin" in errors_on(changeset).email
    end

    test "only registers authorized people with a hashed password" do
      name = valid_person_name()
      pseudonym = unique_person_pseudonym()
      email = unique_person_email()
      password = valid_person_password()
      terms_of_use = valid_person_terms_of_use()

      {:error, changeset} =
        Accounts.register_admin(%{
          name: name,
          pseudonym: pseudonym,
          email: email,
          password: password,
          terms_of_use: terms_of_use
        })

      assert %{
               email: ["not an authorized admin"],
               name: ["not an authorized admin"],
               pseudonym: ["not an authorized admin"]
             } = errors_on(changeset)
    end
  end

  describe "change_person_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_person_registration(%Person{})
      assert changeset.required == [:password, :email, :pseudonym, :name]
    end

    test "allows fields to be set" do
      name = valid_person_name()
      pseudonym = unique_person_pseudonym()
      email = unique_person_email()
      password = valid_person_password()

      changeset =
        Accounts.change_person_registration(%Person{}, %{
          "name" => name,
          "pseudonym" => pseudonym,
          "email" => email,
          "password" => password
        })

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_person_email/2" do
    test "returns a person changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_person_email(%Person{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_person_email/3" do
    setup do
      {person, temp_email, _, _} = person_fixture()
      %{person: person, temp_email: temp_email}
    end

    test "requires email to change", %{person: person} do
      {:error, changeset} = Accounts.apply_person_email(person, valid_person_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{person: person} do
      {:error, changeset} =
        Accounts.apply_person_email(person, valid_person_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign, no spaces, and/or proper format"]} =
               errors_on(changeset)
    end

    test "validates maximum value for email for security", %{person: person} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_person_email(person, valid_person_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{person: person} do
      {_another_person, another_temp_email, _, _} = person_fixture()

      {:error, changeset} =
        Accounts.apply_person_email(person, valid_person_password(), %{email: another_temp_email})

      assert "invalid email" in errors_on(changeset).email_hash
    end

    test "validates current password", %{person: person} do
      {:error, changeset} =
        Accounts.apply_person_email(person, "invalid", %{email: unique_person_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{person: person} do
      email = unique_person_email()

      {:ok, person} =
        Accounts.apply_person_email(person, valid_person_password(), %{email: email})

      assert person.email == email
      assert Accounts.get_person!(person.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup do
      {person, temp_email, _, _} = person_fixture()
      %{person: person, temp_email: temp_email}
    end

    test "sends token through notification", %{person: person, temp_email: temp_email} do
      token =
        extract_person_token(fn url ->
          Accounts.deliver_update_email_instructions(
            person,
            "current@example.com",
            temp_email,
            url
          )
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert person_token = Repo.get_by(PersonToken, token: :crypto.hash(:sha256, token))
      assert person_token.person_id == person.id
      assert person_token.sent_to == temp_email
      assert person_token.context == "change:current@example.com"
    end
  end

  describe "update_person_email/4" do
    setup do
      {person, current_temp_email, _, _} = person_fixture()
      new_temp_email = unique_person_email()
      current_password = valid_person_password()

      token =
        extract_person_token(fn url ->
          Accounts.deliver_update_email_instructions(
            %{person | email: new_temp_email},
            current_temp_email,
            new_temp_email,
            url
          )
        end)

      %{
        person: person,
        token: token,
        email: new_temp_email,
        temp_email: current_temp_email,
        current_password: current_password
      }
    end

    test "updates the email with a valid token and verifies asymmetric encryption", %{
      person: person,
      token: token,
      email: email,
      temp_email: temp_email,
      current_password: current_password
    } do
      %{key: key} = Accounts.Person.valid_key_hash?(person, current_password)
      {:ok, current_person_key} = key

      assert Accounts.update_person_email(person, temp_email, token, current_person_key) == :ok
      changed_person = Repo.get!(Person, person.id)
      {:ok, hashed_email} = Metamorphic.Hashed.HMAC.dump(email)

      assert changed_person.email_hash != temp_email
      assert changed_person.email_hash != person.email_hash
      assert person.email_hash == temp_email
      assert changed_person.email_hash == hashed_email
      assert changed_person.email == "Invalid authentication"
      assert changed_person.confirmed_at
      assert changed_person.confirmed_at != person.confirmed_at
      refute Repo.get_by(PersonToken, person_id: person.id)
    end

    test "does not update email with invalid token", %{
      person: person,
      temp_email: temp_email,
      current_password: current_password
    } do
      %{key: key} = Accounts.Person.valid_key_hash?(person, current_password)
      {:ok, current_person_key} = key

      assert Accounts.update_person_email(person, temp_email, "oops", current_person_key) ==
               :error

      assert Repo.get!(Person, person.id).email == person.email
      assert Repo.get_by(PersonToken, person_id: person.id)
    end

    test "does not update email if person email not changed", %{
      person: person,
      token: token,
      current_password: current_password
    } do
      %{key: key} = Accounts.Person.valid_key_hash?(person, current_password)
      {:ok, current_person_key} = key

      assert Accounts.update_person_email(
               %{person | email: "current@example.com"},
               "current@example.com",
               token,
               current_person_key
             ) == :error

      assert Repo.get!(Person, person.id).email == person.email
      assert Repo.get_by(PersonToken, person_id: person.id)
    end

    test "does not update email if token expired", %{
      person: person,
      token: token,
      temp_email: temp_email,
      current_password: current_password
    } do
      %{key: key} = Accounts.Person.valid_key_hash?(person, current_password)
      {:ok, current_person_key} = key

      {1, nil} = Repo.update_all(PersonToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_person_email(person, temp_email, token, current_person_key) == :error
      assert Repo.get!(Person, person.id).email == person.email
      assert Repo.get_by(PersonToken, person_id: person.id)
    end
  end

  describe "change_person_password/2" do
    test "returns a person changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_person_password(%Person{})
      assert changeset.required == [:name, :pseudonym, :email, :password]
    end

    test "allows fields to be set" do
      {person, _, _, _} = person_fixture()
      current_password = valid_person_password()

      changeset =
        Accounts.change_person_password(person, current_password, %{
          "password" => @new_valid_password
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == @new_valid_password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_person_password/3" do
    setup do
      {person, temp_email, temp_name, temp_pseudonym} = person_fixture()
      current_password = valid_person_password()

      %{
        person: person,
        temp_email: temp_email,
        current_password: current_password,
        temp_name: temp_name,
        temp_pseudonym: temp_pseudonym
      }
    end

    test "validates password", %{person: person} do
      {:error, changeset} =
        Accounts.update_person_password(person, valid_person_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: [
                 "Uh oh! This password has appeared at least 7 times in data breaches. Please choose another password and change any accounts associated with this password.",
                 "at least one digit or special character",
                 "at least one upper case character",
                 "should be at least 20 character(s)"
               ],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{person: person} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_person_password(person, valid_person_password(), %{password: too_long})

      assert "should be at most 80 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{person: person} do
      {:error, changeset} =
        Accounts.update_person_password(person, "invalid", %{password: valid_person_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{
      person: person,
      temp_email: temp_email,
      current_password: current_password,
      temp_name: temp_name,
      temp_pseudonym: temp_pseudonym
    } do
      {:ok, person} =
        Accounts.update_person_password(
          person,
          current_password,
          %{
            name: temp_name,
            email: temp_email,
            pseudonym: temp_pseudonym,
            password: @new_valid_password,
            key_pair: person.key_pair,
            key_hash: person.key_hash
          },
          key_pair: person.key_pair,
          test: true
        )

      assert is_nil(person.password)
      assert Accounts.get_person_by_email_and_password(person.email, @new_valid_password)
    end

    test "deletes all tokens for the given person", %{person: person} do
      _ = Accounts.generate_person_session_token(person)

      {:ok, _} =
        Accounts.update_person_password(person, valid_person_password(), %{
          password: @new_valid_password
        })

      refute Repo.get_by(PersonToken, person_id: person.id)
    end
  end

  describe "generate_person_session_token/1" do
    setup do
      {person, _, _, _} = person_fixture()
      %{person: person}
    end

    test "generates a token", %{person: person} do
      token = Accounts.generate_person_session_token(person)
      assert person_token = Repo.get_by(PersonToken, token: token)
      assert person_token.context == "session"

      # Creating the same token for another person should fail
      {another_person, _, _, _} = person_fixture()

      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%PersonToken{
          token: person_token.token,
          person_id: another_person.id,
          context: "session"
        })
      end
    end
  end

  describe "get_person_by_session_token/1" do
    setup do
      {person, _, _, _} = person_fixture()
      token = Accounts.generate_person_session_token(person)
      %{person: person, token: token}
    end

    test "returns person by token", %{person: person, token: token} do
      assert session_person = Accounts.get_person_by_session_token(token)
      assert session_person.id == person.id
    end

    test "does not return person for invalid token" do
      refute Accounts.get_person_by_session_token("oops")
    end

    test "does not return person for expired token", %{token: token} do
      {1, nil} = Repo.update_all(PersonToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_person_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      {person, _, _, _} = person_fixture()
      token = Accounts.generate_person_session_token(person)
      assert Accounts.delete_session_token(token) == :ok
      refute Accounts.get_person_by_session_token(token)
    end
  end

  describe "deliver_person_confirmation_instructions/2" do
    setup do
      {person, temp_email, _, _} = person_fixture()
      %{person: person, temp_email: temp_email}
    end

    test "sends token through notification", %{person: person, temp_email: temp_email} do
      token =
        extract_person_token(fn url ->
          Accounts.deliver_person_confirmation_instructions(person, temp_email, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert person_token = Repo.get_by(PersonToken, token: :crypto.hash(:sha256, token))
      assert person_token.person_id == person.id
      assert person_token.sent_to == temp_email
      assert person_token.context == "confirm"
    end
  end

  describe "confirm_person/2" do
    setup do
      {person, temp_email, _, _} = person_fixture(%{}, confirmed: false)
      person = person

      token =
        extract_person_token(fn url ->
          Accounts.deliver_person_confirmation_instructions(person, temp_email, url)
        end)

      %{person: person, token: token}
    end

    test "confirms the email with a valid token", %{person: person, token: token} do
      assert {:ok, confirmed_person} = Accounts.confirm_person(token)
      assert confirmed_person.confirmed_at
      assert confirmed_person.confirmed_at != person.confirmed_at
      assert Repo.get!(Person, person.id).confirmed_at
      refute Repo.get_by(PersonToken, person_id: person.id)
    end

    test "does not confirm with invalid token", %{person: person} do
      assert Accounts.confirm_person("oops") == :error
      refute Repo.get!(Person, person.id).confirmed_at
      assert Repo.get_by(PersonToken, person_id: person.id)
    end

    test "does not confirm email if token expired", %{person: person, token: token} do
      {1, nil} = Repo.update_all(PersonToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_person(token) == :error
      refute Repo.get!(Person, person.id).confirmed_at
      assert Repo.get_by(PersonToken, person_id: person.id)
    end
  end

  describe "deliver_person_reset_password_instructions/2" do
    setup do
      {person, temp_email, _, _} = person_fixture()
      %{person: person, temp_email: temp_email}
    end

    test "sends token through notification", %{person: person, temp_email: temp_email} do
      token =
        extract_person_token(fn url ->
          Accounts.deliver_person_reset_password_instructions(person, temp_email, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert person_token = Repo.get_by(PersonToken, token: :crypto.hash(:sha256, token))
      assert person_token.person_id == person.id
      assert person_token.sent_to == temp_email
      assert person_token.context == "reset_password"
    end
  end

  describe "get_person_by_reset_password_token/1" do
    setup do
      {person, temp_email, _, _} = person_fixture()
      person = person

      token =
        extract_person_token(fn url ->
          Accounts.deliver_person_reset_password_instructions(person, temp_email, url)
        end)

      %{person: person, token: token, temp_email: temp_email}
    end

    test "returns the person with valid token", %{person: %{id: id}, token: token} do
      assert %Person{id: ^id} = Accounts.get_person_by_reset_password_token(token)
      assert Repo.get_by(PersonToken, person_id: id)
    end

    test "does not return the person with invalid token", %{person: person} do
      refute Accounts.get_person_by_reset_password_token("oops")
      assert Repo.get_by(PersonToken, person_id: person.id)
    end

    test "does not return the person if token expired", %{person: person, token: token} do
      {1, nil} = Repo.update_all(PersonToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_person_by_reset_password_token(token)
      assert Repo.get_by(PersonToken, person_id: person.id)
    end
  end

  # Currently, we do not allow someone to reset their password (forgotten password).
  @doc """
    describe "reset_person_password/2" do
      setup do
        {person, _, _, _} = person_fixture()
        %{person: person}
      end

      test "validates password", %{person: person} do
        {:error, changeset} =
          Accounts.reset_person_password(person, %{
            password: "not valid",
            password_confirmation: "another"
          })

        assert %{
          password: [
            "Uh oh! This password has appeared at least 7 times in data breaches. Please choose another password and change any accounts associated with this password.",
            "at least one digit or special character",
            "at least one upper case character",
            "should be at least 20 character(s)"
          ],
          password_confirmation: ["does not match password"]
        } = errors_on(changeset)
      end

      test "validates maximum values for password for security", %{person: person} do
        too_long = String.duplicate("db", 100)
        {:error, changeset} = Accounts.reset_person_password(person, %{password: too_long})
        assert "should be at most 80 character(s)" in errors_on(changeset).password
      end

      test "updates the password", %{person: person} do
        {:ok, updated_person} = Accounts.reset_person_password(person, %{password: @new_valid_password})
        assert is_nil(updated_person.password)
        assert Accounts.get_person_by_email_and_password(person.email, @new_valid_password)
      end

      test "deletes all tokens for the given person", %{person: person} do
        _ = Accounts.generate_person_session_token(person)
        {:ok, _} = Accounts.reset_person_password(person, %{password: @new_valid_password})
        refute Repo.get_by(PersonToken, person_id: person.id)
      end
    end
  """

  describe "inspect/2" do
    test "does not include password" do
      refute inspect(%Person{password: "123456"}) =~ "password: \"123456\""
    end
  end
end
