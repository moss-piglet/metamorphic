defmodule Metamorphic.Encrypted.Relationships.Utils do
  @moduledoc """
  Encryption utilities for implementing asymmetric
  encrytion for Relationships' data.
  """
  alias Metamorphic.Encrypted

  @doc """
  Decrypts the current_person's data for re-encrypting
  for the other person when requesting a relationship
  request of said person.
  """
  def decrypt_current_person_requesting_relationship(
        payload,
        encrypted_payload_person_key,
        current_person,
        current_person_key
      ) do
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
  Decrypts the current_person's data for re-encrypting
  for the other person when accepting a relationship
  request from said person.
  """
  def decrypt_current_person_accepting_relationship(
        payload,
        encrypted_payload_person_key,
        current_person,
        current_person_key
      ) do
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
end
