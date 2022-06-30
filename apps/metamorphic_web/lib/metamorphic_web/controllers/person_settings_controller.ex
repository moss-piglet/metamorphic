defmodule MetamorphicWeb.PersonSettingsController do
  use MetamorphicWeb, :controller

  alias Metamorphic.Accounts
  alias Metamorphic.Constructor
  alias Metamorphic.Letters
  alias Metamorphic.Memories
  alias Metamorphic.Relationships
  alias Metamorphic.Billing
  alias Metamorphic.Encrypted
  alias MetamorphicWeb.PersonAuth
  alias MetamorphicWeb.Router.Helpers, as: Routes

  alias Metamorphic.Extensions.CSV.Builder

  @stripe_service Application.compile_env(:metamorphic, :stripe_service)

  def confirm_email(conn, %{"token" => token}) do
    # audit_context = conn.assigns.audit_context
    person = conn.assigns.current_person
    current_person_key = conn.private.plug_session["key"]

    decrypted_email =
      Encrypted.People.Utils.decrypt_person_email(
        person.email,
        person.person_key,
        person,
        current_person_key
      )

    customer = Billing.get_billing_customer_for_person(person)

    case Accounts.update_person_email(person, decrypted_email, token, current_person_key) do
      {:ok, new_temp_email} ->
        {:ok, _customer} =
          @stripe_service.Customer.update(customer.stripe_id, %{email: new_temp_email})

        conn
        |> put_flash(:success, "Your email was changed successfully.")
        |> redirect(to: Routes.person_settings_path(conn, :index))

      :error ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: Routes.person_settings_path(conn, :index))
    end
  end

  def update_password(conn, %{"current_password" => password, "person" => person_params}) do
    # audit_context = conn.assigns.audit_context
    person = conn.assigns.current_person

    case Accounts.update_person_password(person, password, person_params) do
      {:ok, person} ->
        conn
        |> put_flash(:success, "Password updated successfully.")
        |> PersonAuth.log_in_person(person)

      _ ->
        conn
        |> put_flash(:error, "We were unable to update your password. Please try again.")
        |> redirect(to: Routes.person_settings_path(conn, :index))
    end
  end

  ## Download Data
  #
  #
  # Currently downloads `%Person{}`, Stripe, and `%Relationship{}`
  # data. All downloads are authorized against the `current_person`
  # in the `conn`.
  #
  # Everything is downloaded as it would be handed over through a
  # legal court ordered mandated. That is, it is asymmetrically
  # encrypted if the field has been asymmetrically encrypted.
  #
  # Currently, we do **not** decrypt with people's session key
  # for security.
  #
  # TODO: download `%Memory{}`, `%Portal{}`, and `%Letter{}`
  # data; and allow people to download their decrypted data
  # upon successful confirmation of their current password.

  @doc """
  Downloads the current_person's Stripe data. This includes
  `%Customer{}`, `%Plan{}`, `%Product{}`, and `%Subscription{}`
  data.

  This downloads all of their Stripe data on our end. We
  authorize against the current_person in the connection.
  """
  def download_stripe_data(conn, %{"current_person_id" => current_person_id, "email" => email})
      when is_binary(conn.assigns.current_person.id) do
    if conn.assigns.current_person.id === current_person_id do
      current_person = Accounts.get_person_by_id_and_email(current_person_id, email)
      current_customer = Billing.get_billing_customer_for_person(current_person)
      data = Billing.safe_download_list_subscription_data(current_customer)

      if is_nil(data) || Enum.empty?(data) || data == [nil] do
        conn
        |> send_download(
          {:binary, "No data or unauthorized."},
          content_type: "text/json",
          filename: "no-data.txt"
        )
      else
        conn
        |> send_download(
          {
            :binary,
            Builder.stripe_data_to_csv(
              [
                :id,
                :cancel_at,
                :current_period_end_at,
                :status,
                :stripe_id,
                :stripe_id_hash,
                :trial_end_at,
                :updated_at,
                :inserted_at,
                :customer_id,
                :plan_id,
                :customer_default_source,
                :customer_stripe_id,
                :customer_stripe_id_hash,
                :customer_free_trial,
                :customer_inserted_at,
                :customer_updated_at,
                :customer_person_id,
                :plan_amount,
                :plan_stripe_id,
                :plan_stripe_plan_name,
                :plan_billing_product_id,
                :product_id,
                :product_stripe_id,
                :product_stripe_product_name,
                :product_inserted_at,
                :product_updated_at
              ],
              data
            )
          },
          content_type: "application/csv",
          filename: "metamorphic-person-stripe-data.csv"
        )
      end
    else
      conn
      |> send_download(
        {:binary, "No data or unauthorized."},
        content_type: "text/json",
        filename: "no-data.txt"
      )
    end
  end

  @doc """
  Downloads the current_person's `%Person{}` data.

  This downloads all of their asymmetric `%Person{}` data on our end.
  It is **not** decrypted with their session key. We authorize against
  the current_person in the connection.
  """
  def download_encrypted_person_data(conn, %{
        "current_person_id" => current_person_id,
        "email" => email
      })
      when is_binary(conn.assigns.current_person.id) do
    if conn.assigns.current_person.id === current_person_id do
      current_person = Accounts.get_person_by_id_and_email(current_person_id, email)
      data = Accounts.safe_download_list_person_data(current_person)

      if is_nil(data) || Enum.empty?(data) || data == [nil] do
        conn
        |> send_download(
          {:binary, "No data or unauthorized."},
          content_type: "text/json",
          filename: "no-data.txt"
        )
      else
        conn
        |> send_download(
          {
            :binary,
            Builder.person_data_to_csv(
              [
                :id,
                :name,
                :hashed_name,
                :pseudonym,
                :pseudonym_hash,
                :early_access_member,
                :email,
                :email_hash,
                :hashed_password,
                :beta_invite_code,
                :avatar_urls,
                :key_hash,
                :is_blocked,
                :privileges,
                :key_pair,
                :person_avatar_key,
                :terms_of_use,
                :password_reminder,
                :updated_at,
                :inserted_at,
                :confirmed_at
              ],
              data
            )
          },
          content_type: "application/csv",
          filename: "metamorphic-encrypted-person-data.csv"
        )
      end
    else
      conn
      |> send_download(
        {:binary, "No data or unauthorized."},
        content_type: "text/json",
        filename: "no-data.txt"
      )
    end
  end

  @doc """
  Downloads the current admin's `%Person{}` data.

  This downloads all of their asymmetric `%Person{}` data on our end.
  It is **not** decrypted with their session key. We authorize against
  the current_person in the connection.
  """
  def download_encrypted_admin_data(conn, %{
        "current_person_id" => current_person_id,
        "email" => email
      })
      when is_binary(conn.assigns.current_person.id) do
    if conn.assigns.current_person.id === current_person_id &&
         conn.assigns.current_person.privileges === :admin do
      current_person = Accounts.get_person_by_id_and_email(current_person_id, email)
      data = Accounts.safe_download_list_person_data(current_person)

      if is_nil(data) || Enum.empty?(data) || data == [nil] do
        conn
        |> send_download(
          {:binary, "No data or unauthorized."},
          content_type: "text/json",
          filename: "no-data.txt"
        )
      else
        conn
        |> send_download(
          {
            :binary,
            Builder.person_data_to_csv(
              [
                :id,
                :name,
                :hashed_name,
                :pseudonym,
                :pseudonym_hash,
                :early_access_member,
                :email,
                :email_hash,
                :hashed_password,
                :beta_invite_code,
                :avatar_urls,
                :key_hash,
                :is_blocked,
                :privileges,
                :key_pair,
                :person_avatar_key,
                :terms_of_use,
                :password_reminder,
                :updated_at,
                :inserted_at,
                :confirmed_at
              ],
              data
            )
          },
          content_type: "application/csv",
          filename: "metamorphic-encrypted-admin-data.csv"
        )
      end
    else
      conn
      |> send_download(
        {:binary, "No data or unauthorized."},
        content_type: "text/json",
        filename: "no-data.txt"
      )
    end
  end

  @doc """
  Downloads the current_person's `%Relationship{}` **relation** data.

  This downloads all of their asymmetric `%Relationship{}` **relation**
  data on our end. It is **not** decrypted with their session key.
  We authorize against the current_person in the connection.
  """
  def download_encrypted_relationship_relation_data(conn, %{
        "current_person_id" => current_person_id,
        "email" => email
      })
      when is_binary(conn.assigns.current_person.id) do
    if conn.assigns.current_person.id === current_person_id do
      current_person = Accounts.get_person_by_id_and_email(current_person_id, email)
      data = Relationships.safe_download_list_relation_relationships(current_person)

      if is_nil(data) || Enum.empty?(data) || data == [nil] do
        conn
        |> send_download(
          {:binary, "No data or unauthorized."},
          content_type: "text/json",
          filename: "no-data.txt"
        )
      else
        conn
        |> send_download(
          {
            :binary,
            Builder.relationship_data_to_csv(
              [
                :id,
                :relation_id,
                :relation_name,
                :relation_pseudonym,
                :relation_email,
                :person_key,
                :relationship_key,
                :is_blocked,
                :privileges,
                :key_pair,
                :can_download_memories?,
                :relationship_type_id,
                :relationship_type_name,
                :relationship_type_name_hash,
                :relationship_type_inserted_at,
                :relationship_type_updated_at,
                :updated_at,
                :inserted_at,
                :confirmed_at
              ],
              data
            )
          },
          content_type: "application/csv",
          filename: "metamorphic-encrypted-people-relation-data.csv"
        )
      end
    else
      conn
      |> send_download(
        {:binary, "No data or unauthorized."},
        content_type: "text/json",
        filename: "no-data.txt"
      )
    end
  end

  @doc """
  Downloads the current_person's `%Relationship{}` **person** data.

  This downloads all of their asymmetric `%Relationship{}` **person**
  data on our end. It is **not** decrypted with their session key.
  We authorize against the current_person in the connection.
  """
  def download_encrypted_relationship_person_data(conn, %{
        "current_person_id" => current_person_id,
        "email" => email
      })
      when is_binary(conn.assigns.current_person.id) do
    if conn.assigns.current_person.id === current_person_id do
      current_person = Accounts.get_person_by_id_and_email(current_person_id, email)
      data = Relationships.safe_download_list_person_relationships(current_person)

      if is_nil(data) || Enum.empty?(data) || data == [nil] do
        conn
        |> send_download(
          {:binary, "No data or unauthorized."},
          content_type: "text/json",
          filename: "no-data.txt"
        )
      else
        conn
        |> send_download(
          {
            :binary,
            Builder.relationship_data_to_csv(
              [
                :id,
                :person_id,
                :person_name,
                :person_pseudonym,
                :person_email,
                :person_key,
                :relationship_key,
                :is_blocked,
                :privileges,
                :key_pair,
                :can_download_memories?,
                :relationship_type_id,
                :relationship_type_name,
                :relationship_type_name_hash,
                :relationship_type_inserted_at,
                :relationship_type_updated_at,
                :updated_at,
                :inserted_at,
                :confirmed_at
              ],
              data
            )
          },
          content_type: "application/csv",
          filename: "metamorphic-encrypted-people-person-data.csv"
        )
      end
    else
      conn
      |> send_download(
        {:binary, "No data or unauthorized."},
        content_type: "text/json",
        filename: "no-data.txt"
      )
    end
  end

  @doc """
  Downloads the current_person's `%Memory{}` data.

  This downloads all of their asymmetric `%Memory{}`
  data on our end. It is **not** decrypted with their session key.
  We authorize against the current_person in the connection.
  """
  def download_encrypted_memory_data(conn, %{
        "current_person_id" => current_person_id,
        "email" => email
      })
      when is_binary(conn.assigns.current_person.id) do
    if conn.assigns.current_person.id === current_person_id do
      current_person = Accounts.get_person_by_id_and_email(current_person_id, email)
      data = Memories.safe_download_list_memories(current_person)

      if is_nil(data) || Enum.empty?(data) || data == [nil] do
        conn
        |> send_download(
          {:binary, "No data or unauthorized."},
          content_type: "text/json",
          filename: "no-data.txt"
        )
      else
        conn
        |> send_download(
          {
            :binary,
            Builder.memory_data_to_csv(
              [
                :id,
                :name,
                :name_hash,
                :file_size,
                :file_type,
                :memory_urls,
                :description,
                :person_key,
                :favorite,
                :hidden,
                :person_id
              ],
              data
            )
          },
          content_type: "application/csv",
          filename: "metamorphic-encrypted-memory-data.csv"
        )
      end
    else
      conn
      |> send_download(
        {:binary, "No data or unauthorized."},
        content_type: "text/json",
        filename: "no-data.txt"
      )
    end
  end

  @doc """
  Downloads the current_person's `%Portal{}` data.

  This downloads all of their asymmetric `%Portal{}`
  data on our end. It is **not** decrypted with their session key.
  We authorize against the current_person in the connection.
  """
  def download_encrypted_portal_data(conn, %{
        "current_person_id" => current_person_id,
        "email" => email
      })
      when is_binary(conn.assigns.current_person.id) do
    if conn.assigns.current_person.id === current_person_id do
      current_person = Accounts.get_person_by_id_and_email(current_person_id, email)
      data = Constructor.safe_download_list_portals(current_person)

      if is_nil(data) || Enum.empty?(data) || data == [nil] do
        conn
        |> send_download(
          {:binary, "No data or unauthorized."},
          content_type: "text/json",
          filename: "no-data.txt"
        )
      else
        conn
        |> send_download(
          {
            :binary,
            Builder.portal_data_to_csv(
              [
                :id,
                :person_id,
                :person_key,
                :name,
                :slug,
                :slug_hash,
                :portal_pass,
                :hashed_portal_pass
              ],
              data
            )
          },
          content_type: "application/csv",
          filename: "metamorphic-encrypted-portal-data.csv"
        )
      end
    else
      conn
      |> send_download(
        {:binary, "No data or unauthorized."},
        content_type: "text/json",
        filename: "no-data.txt"
      )
    end
  end

  @doc """
  Downloads the current_person's `%Letter{}` data.

  This downloads all of their asymmetric `%Letter{}`
  data on our end. It is **not** decrypted with their session key.
  We authorize against the current_person in the connection.
  """
  def download_encrypted_letter_data(conn, %{
        "current_person_id" => current_person_id,
        "email" => email
      })
      when is_binary(conn.assigns.current_person.id) do
    if conn.assigns.current_person.id === current_person_id do
      current_person = Accounts.get_person_by_id_and_email(current_person_id, email)
      data = Letters.safe_download_list_letters(current_person)

      if is_nil(data) || Enum.empty?(data) || data == [nil] do
        conn
        |> send_download(
          {:binary, "No data or unauthorized."},
          content_type: "text/json",
          filename: "no-data.txt"
        )
      else
        conn
        |> send_download(
          {
            :binary,
            Builder.letter_data_to_csv([:id, :person_id, :body], data)
          },
          content_type: "application/csv",
          filename: "metamorphic-encrypted-letter-data.csv"
        )
      end
    else
      conn
      |> send_download(
        {:binary, "No data or unauthorized."},
        content_type: "text/json",
        filename: "no-data.txt"
      )
    end
  end
end
