defmodule Metamorphic.Encrypted.Letters.Sharing do
  @moduledoc """
  Encryption functions for sharing letters.
  """
  alias Metamorphic.Accounts.Person
  alias Metamorphic.Encrypted
  alias Metamorphic.Relationships

  @doc """
  Prepare the encrypted attributes for sharing. This
  pattern matches on a single `Person{}`.
  """
  def prepare_encrypted_attributes_for_sharing(
        letter,
        %Person{} = person,
        current_person,
        current_person_key
      ) do
    # 1. Generate a person_key for the letter.
    letter_person_key = Encrypted.Utils.generate_key()

    # 2. Bind the person-to-share-with's public key.
    person_public_key = person.key_pair["public"]

    # In this case the letter data is created then
    # sent to the recipient. There is never a copy of
    # the letter to encrypt that is not shared.
    #
    # This means that people create letters to send
    # to other recipients but never have a copy or access
    # to the letter once sent. (The recipient could always
    # share the letter back with them.) So, there is not
    # an original encrypted letter to first decrypt.
    #
    # 3. Encrypt the letter data with the person_key (from Step 1).
    encrypted_shared_letter_body =
      Encrypted.Utils.encrypt(%{key: letter_person_key, payload: letter["body"]})

    # 4. Encrypt the person_key (from Step 1) with the "shared with" person's public key.
    encrypted_person_key =
      Encrypted.Utils.encrypt_message_for_user_with_pk(letter_person_key, %{
        public: person_public_key
      })

    # 5. Build attributes map for saving to the db.
    shared_with_attrs = %{
      "person_id" => person.id,
      "person_key" => encrypted_person_key,
      "body" => encrypted_shared_letter_body,
      "letter_origin_id" => current_person.id,
      "relationship_id" =>
        Relationships.get_people_relationship_with_person_id(current_person, person.id).id,
      "recipients" => letter["recipients"]
    }

    shared_with_attrs
  end

  # defp decrypt_letter_data_for_sharing(payload, payload_person_key, current_person, current_person_key) do
  #  #1. Bind the current_person_key from the session.
  #  {:ok, current_person_key} = current_person_key

  # 2. Decrypt the current_person's private key with their session key (from Step 1).
  # {:ok, private_key} = Encrypted.Utils.decrypt(%{key: current_person_key, payload: current_person.key_pair["private"]})

  # 3. Decrypt the payload's person_key using the current_person's public and private keys.
  # {:ok, person_key} = Encrypted.Utils.decrypt_message_for_user(payload_person_key, %{public: current_person.key_pair["public"], private: private_key})

  # 4. Decrypt the payload using the payload's person_key (from Step 3).
  # {:ok, decrypted_payload} = Encrypted.Utils.decrypt(%{key: person_key, payload: payload})

  # decrypted_payload
  # end
end
