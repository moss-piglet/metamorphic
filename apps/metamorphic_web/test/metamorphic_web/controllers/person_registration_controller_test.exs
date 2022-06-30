defmodule MetamorphicWeb.PersonRegistrationControllerTest do
  use MetamorphicWeb.ConnCase, async: true

  import Metamorphic.AccountsFixtures

  describe "GET /people/register" do
    test "renders registration page", %{socket: socket} do
      socket = get(socket, Routes.person_registration_path(socket, :new))
      response = html_response(socket, 200)
      assert response =~ "<h1>Register</h1>"
      assert response =~ "Log in</a>"
      assert response =~ "Register</a>"
    end

    test "redirects if already logged in", %{socket: socket} do
      socket =
        socket
        |> log_in_person(person_fixture())
        |> get(Routes.person_registration_path(socket, :new))

      assert redirected_to(socket) == "/"
    end
  end

  describe "POST /people/register" do
    @tag :capture_log
    test "creates account and does not log the person in", %{socket: socket} do
      email = unique_person_email()

      socket =
        post(socket, Routes.person_registration_path(socket, :create), %{
          "person" => %{
            "email" => email,
            "password" => valid_person_password(),
            "password_confirmation" => valid_person_password()
          }
        })

      refute get_session(socket, :person_token)
      assert redirected_to(socket) =~ "/people/log_in"

      assert flash_messages_contain(
               socket,
               "Account created successfully. Please check your email for confirmation instructions."
             )
    end

    defp flash_messages_contain(socket, text) do
      socket
      |> Phoenix.Controller.get_flash()
      |> Enum.any?(fn item -> String.contains?(elem(item, 1), text) end)
    end

    test "render errors for invalid data", %{socket: socket} do
      socket =
        post(socket, Routes.person_registration_path(socket, :create), %{
          "person" => %{
            "email" => "with spaces",
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(socket, 200)
      assert response =~ "<h1>Register a new account</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "should be at least 12 character"
      assert response =~ "does not match password"
    end
  end
end
