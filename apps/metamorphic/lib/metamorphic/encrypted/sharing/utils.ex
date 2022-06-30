defmodule Metamorphic.Encrypted.Sharing.Utils do
  @moduledoc """
  Utility functions for sharing encrypted data
  between people.
  """
  alias Metamorphic.Encrypted

  @doc """
  Decrypts the shared person_key for the data to be shared.
  For example, decrypts the %Portal{}, %Memory{}, or %Letter{}
  person_key.
  """
  def decrypt_shared_person_key(encrypted_payload_person_key, current_person, current_person_key) do
    # 1. Bind the current_person_key from the session.
    case current_person_key do
      {:ok, current_person_key} ->
        # 2. Decrypt the current_person's private key with their session key (from Step 1).
        case Encrypted.Utils.decrypt(%{
               key: current_person_key,
               payload: current_person.key_pair["private"]
             }) do
          {:ok, private_key} ->
            # 3. Decrypt the payload's shared person_key using the current_person's public and private keys.
            case Encrypted.Utils.decrypt_message_for_user(encrypted_payload_person_key, %{
                   public: current_person.key_pair["public"],
                   private: private_key
                 }) do
              {:ok, shared_person_key} ->
                shared_person_key

              {:error, error_message} ->
                error_message
            end

          {:error, error_message} ->
            error_message
        end

      _ ->
        "Invalid authentication"
    end
  end
end
