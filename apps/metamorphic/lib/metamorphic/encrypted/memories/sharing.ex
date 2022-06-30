defmodule Metamorphic.Encrypted.Memories.Sharing do
  @moduledoc """
  Encryption functions for sharing
  memories.
  """
  alias Metamorphic.Encrypted

  def prepare_encrypted_attributes_for_sharing(memory, person, current_person, current_person_key) do
    # 1. Decrypt  person_key for the shared_memory_urls.
    person_key =
      Encrypted.Sharing.Utils.decrypt_shared_person_key(
        memory.person_key,
        current_person,
        current_person_key
      )

    # 2. Bind the person-to-share-with's public key.
    person_public_key = person.key_pair["public"]

    # 3. Decrypt the memory_urls to re-encrypt with shared-with person's public key.
    decrypted_memory_urls =
      decrypt_memory_urls_for_sharing(memory, current_person, current_person_key)

    # 3.5 Decrypt the memory name, file_size, file_type, and description to re-encrypt with shared-with person's public key.
    [
      decrypted_memory_name,
      decrypted_memory_file_size,
      decrypted_memory_file_type,
      decrypted_memory_description
    ] = decrypt_memory_attrs_for_sharing(memory, current_person, current_person_key)

    # 4. Encrypt the memory_urls with the person_key (from Step 1) and store in a list.
    encrypted_shared_memory_urls =
      Encrypted.Utils.encrypt(%{key: person_key, payload: decrypted_memory_urls})

    encrypted_shared_memory_urls = [encrypted_shared_memory_urls]

    # 4.5 Encrypt the memory name, file_size, file_type, and description with the person_key (from Step 1).
    encrypted_memory_name =
      Encrypted.Utils.encrypt(%{key: person_key, payload: decrypted_memory_name})

    encrypted_memory_file_size =
      Encrypted.Utils.encrypt(%{key: person_key, payload: decrypted_memory_file_size})

    encrypted_memory_file_type =
      Encrypted.Utils.encrypt(%{key: person_key, payload: decrypted_memory_file_type})

    encrypted_memory_description =
      Encrypted.Utils.encrypt(%{key: person_key, payload: decrypted_memory_description})

    # 5. Encrypt the person_key (from Step 1) with the "shared with" person's public key.
    encrypted_person_key =
      Encrypted.Utils.encrypt_message_for_user_with_pk(person_key, %{public: person_public_key})

    # 6. Build attributes map for saving to the db.
    shared_with_attrs = %{
      "memory_id" => memory.id,
      "person_id" => person.id,
      "person_key" => encrypted_person_key,
      "memory_urls" => encrypted_shared_memory_urls,
      "name" => encrypted_memory_name,
      "file_size" => encrypted_memory_file_size,
      "file_type" => encrypted_memory_file_type,
      "description" => encrypted_memory_description
    }

    shared_with_attrs
  end

  defp decrypt_memory_urls_for_sharing(memory, current_person, current_person_key) do
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
      Encrypted.Utils.decrypt_message_for_user(memory.person_key, %{
        public: current_person.key_pair["public"],
        private: private_key
      })

    # 4. Bind the memory_urls from the list. (This won't work for more than one url.)
    [memory_urls] = memory.memory_urls

    # 4. Decrypt the payload using the person_key (from Step 3).
    {:ok, decrypted_payload} = Encrypted.Utils.decrypt(%{key: person_key, payload: memory_urls})

    decrypted_payload
  end

  defp decrypt_memory_attrs_for_sharing(memory, current_person, current_person_key) do
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
      Encrypted.Utils.decrypt_message_for_user(memory.person_key, %{
        public: current_person.key_pair["public"],
        private: private_key
      })

    # 4. Decrypt the memory name, file_size, file_type, and description using the person_key (from Step 3).
    # Since the description might be nil, we run a check for it and return an empty string if nil.
    {:ok, decrypted_memory_name} =
      Encrypted.Utils.decrypt(%{key: person_key, payload: memory.name})

    {:ok, decrypted_memory_file_size} =
      Encrypted.Utils.decrypt(%{key: person_key, payload: memory.file_size})

    {:ok, decrypted_memory_file_type} =
      Encrypted.Utils.decrypt(%{key: person_key, payload: memory.file_type})

    {:ok, decrypted_memory_description} =
      if is_nil(memory.description),
        do: {:ok, ""},
        else: Encrypted.Utils.decrypt(%{key: person_key, payload: memory.description})

    # 5. Return list
    [
      decrypted_memory_name,
      decrypted_memory_file_size,
      decrypted_memory_file_type,
      decrypted_memory_description
    ]
  end
end
