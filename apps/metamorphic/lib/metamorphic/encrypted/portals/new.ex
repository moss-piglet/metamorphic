defmodule Metamorphic.Encrypted.Portals.New do
  @moduledoc """
  Encryption functions for creating new portals
  for a person.
  """
  alias Metamorphic.Encrypted
  alias Metamorphic.Extensions.PasswordGenerator.PassphraseGenerator

  @words 6
  @separator "-"

  def prepare_encrypted_portal_fields(portal_params, current_person) do
    # 1. Generate the portal person_key.
    portal_person_key = Encrypted.Utils.generate_key()

    # 2. Bind the current_person's public key.
    person_public_key = current_person.key_pair["public"]

    # 3. Bind the portal name and slug.
    portal_name = portal_params["name"]
    portal_slug = portal_params["slug"]
    temp_slug = portal_params["slug"]

    # 4. Generate a portal_pass.
    portal_pass = PassphraseGenerator.generate_passphrase(%{words: @words, separator: @separator})

    # 5. Salt portal_pass
    salted_portal_pass = portal_pass <> "#{:enacl.randombytes(16) |> Base.encode64()}"

    # 6. Hash portal_pass
    hashed_portal_pass = Argon2.hash_pwd_salt(salted_portal_pass, salt_len: 128)

    # 7. Encrypt name, slug, and portal_pass with portal_person_key.
    encrypted_portal_name =
      Encrypted.Utils.encrypt(%{key: portal_person_key, payload: portal_name})

    encrypted_portal_slug =
      Encrypted.Utils.encrypt(%{key: portal_person_key, payload: portal_slug})

    encrypted_portal_pass =
      Encrypted.Utils.encrypt(%{key: portal_person_key, payload: salted_portal_pass})

    # 8. Encrypt the portal person_key with the current_person's public key (from Step 2).
    encrypted_person_key =
      Encrypted.Utils.encrypt_message_for_user_with_pk(portal_person_key, %{
        public: person_public_key
      })

    # 9. Update the portal_params map with the encrypted fields.
    portal_params =
      portal_params
      |> Map.put("name", encrypted_portal_name)
      |> Map.put("slug", encrypted_portal_slug)
      |> Map.put("temp_slug", temp_slug)
      |> Map.put("portal_pass", encrypted_portal_pass)
      |> Map.put("person_key", encrypted_person_key)
      |> Map.put("hashed_portal_pass", hashed_portal_pass)

    portal_params
  end
end
