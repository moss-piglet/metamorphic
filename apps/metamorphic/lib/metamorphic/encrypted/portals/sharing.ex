defmodule Metamorphic.Encrypted.Portals.Sharing do
  @moduledoc """
  Encryption functions for sharing
  portals.
  """
  alias Metamorphic.Encrypted

  def prepare_encrypted_attributes_for_sharing(portal, person, current_person, current_person_key) do
    # 1. Decrypt person_key for the portal to be shared.
    person_key =
      Encrypted.Sharing.Utils.decrypt_shared_person_key(
        portal.person_key,
        current_person,
        current_person_key
      )

    # 2. Bind the person-to-share-with's public key.
    person_public_key = person.key_pair["public"]

    # 3. Decrypt the portal data to re-encrypt with shared-with person's public key.
    decrypted_portal_name =
      decrypt_portal_data_for_sharing(
        portal.name,
        portal.person_key,
        current_person,
        current_person_key
      )

    decrypted_portal_slug =
      decrypt_portal_data_for_sharing(
        portal.slug,
        portal.person_key,
        current_person,
        current_person_key
      )

    decrypted_portal_portal_pass =
      decrypt_portal_data_for_sharing(
        portal.portal_pass,
        portal.person_key,
        current_person,
        current_person_key
      )

    # 4. Hash the portal_pass (from Step 3).
    hashed_portal_pass = Argon2.hash_pwd_salt(decrypted_portal_portal_pass, salt_len: 128)

    # 3. Encrypt the portal data with the person_key (from Step 1).
    encrypted_shared_portal_name =
      Encrypted.Utils.encrypt(%{key: person_key, payload: decrypted_portal_name})

    encrypted_shared_portal_slug =
      Encrypted.Utils.encrypt(%{key: person_key, payload: decrypted_portal_slug})

    encrypted_shared_portal_portal_pass =
      Encrypted.Utils.encrypt(%{key: person_key, payload: decrypted_portal_portal_pass})

    # 4. Encrypt the person_key (from Step 1) with the "shared with" person's public key.
    encrypted_person_key =
      Encrypted.Utils.encrypt_message_for_user_with_pk(person_key, %{public: person_public_key})

    # 5. Build attributes map for saving to the db.
    shared_with_attrs = %{
      "portal_id" => portal.id,
      "person_id" => person.id,
      "person_key" => encrypted_person_key,
      "name" => encrypted_shared_portal_name,
      "slug" => encrypted_shared_portal_slug,
      "portal_pass" => encrypted_shared_portal_portal_pass,
      "hashed_portal_pass" => hashed_portal_pass,
      "temp_slug" => decrypted_portal_slug,
      "portal_origin_id" => current_person.id
    }

    shared_with_attrs
  end

  defp decrypt_portal_data_for_sharing(
         payload,
         payload_person_key,
         current_person,
         current_person_key
       ) do
    # 1. Bind the current_person_key from the session.
    {:ok, current_person_key} = current_person_key

    # 2. Decrypt the current_person's private key with their session key (from Step 1).
    {:ok, private_key} =
      Encrypted.Utils.decrypt(%{
        key: current_person_key,
        payload: current_person.key_pair["private"]
      })

    # 3. Decrypt the payload's person_key using the current_person's public and private keys.
    {:ok, person_key} =
      Encrypted.Utils.decrypt_message_for_user(payload_person_key, %{
        public: current_person.key_pair["public"],
        private: private_key
      })

    # 4. Decrypt the payload using the payload's person_key (from Step 3).
    {:ok, decrypted_payload} = Encrypted.Utils.decrypt(%{key: person_key, payload: payload})

    decrypted_payload
  end
end
