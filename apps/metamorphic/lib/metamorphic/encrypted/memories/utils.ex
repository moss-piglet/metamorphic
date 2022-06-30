defmodule Metamorphic.Encrypted.Memories.Utils do
  @moduledoc """
  Encryption utilities for implementing asymmetric
  encrytion for People's memory data.
  """
  alias Metamorphic.Encrypted

  @doc """
  Decrypts file payload for the current person's data
  with their current_person_key.
  """
  def decrypt_file(payload, encrypted_payload_person_key, current_person, current_person_key) do
    # 1. Bind the current_person_key from the session.
    case current_person_key do
      {:ok, current_person_key} ->
        # 2. Decrypt the current_person's private key with their session key (from Step 1).
        case Encrypted.Utils.decrypt(%{
               key: current_person_key,
               payload: current_person.key_pair["private"]
             }) do
          {:ok, private_key} ->
            # 3. Decrypt the payload's person_key using the current_person's public and private keys.
            case Encrypted.Utils.decrypt_message_for_user(encrypted_payload_person_key, %{
                   public: current_person.key_pair["public"],
                   private: private_key
                 }) do
              {:ok, person_key} ->
                # 4. Decrypt the payload using the person_key (from Step 3).
                case Encrypted.Utils.decrypt(%{key: person_key, payload: payload}) do
                  {:ok, decrypted_payload} ->
                    decrypted_payload

                  {:error, error_message} ->
                    error_message
                end

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

  @doc """
  Decrypts the `memory_person_key` for a `%Memory{}`.
  """
  def decrypt_memory_person_key(encrypted_payload_person_key, current_person, current_person_key) do
    # 1. Bind the current_person_key from the session.
    case current_person_key do
      {:ok, current_person_key} ->
        # 2. Decrypt the current_person's private key with their session key (from Step 1).
        case Encrypted.Utils.decrypt(%{
               key: current_person_key,
               payload: current_person.key_pair["private"]
             }) do
          {:ok, private_key} ->
            # 3. Decrypt the payload's memory_person_key using the current_person's public and private keys.
            case Encrypted.Utils.decrypt_message_for_user(encrypted_payload_person_key, %{
                   public: current_person.key_pair["public"],
                   private: private_key
                 }) do
              {:ok, memory_person_key} ->
                memory_person_key

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
