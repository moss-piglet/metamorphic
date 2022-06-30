defmodule Metamorphic.Encrypted.People.Utils do
  @moduledoc """
  Encryption utilities for implementing asymmetric
  encrytion for People's account data.
  """
  alias Metamorphic.Encrypted

  @doc """
  Decrypts payload for the current person's data
  with their current_person_key.
  """
  def decrypt_person_data(
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
  Decrypts the `person_avatar_key` for a `%Person{}`.
  """
  def decrypt_person_avatar_key(encrypted_payload_person_key, current_person, current_person_key) do
    # 1. Bind the current_person_key from the session.
    case current_person_key do
      {:ok, current_person_key} ->
        # 2. Decrypt the current_person's private key with their session key (from Step 1).
        case Encrypted.Utils.decrypt(%{
               key: current_person_key,
               payload: current_person.key_pair["private"]
             }) do
          {:ok, private_key} ->
            # 3. Decrypt the payload's person_avatar_key using the current_person's public and private keys.
            case Encrypted.Utils.decrypt_message_for_user(encrypted_payload_person_key, %{
                   public: current_person.key_pair["public"],
                   private: private_key
                 }) do
              {:ok, person_avatar_key} ->
                person_avatar_key

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
  Decrypts the private key and returns the
  decrypted key pair for the current_person.
  This is used for updating a person's password.

  Returns a %{public: public, private: private}
  key_pair map.

  *** Never use this on the client-side.
  """
  def decrypt_key_pair(current_person, current_person_key) do
    # 1. Bind the current_person_key from the session.
    case current_person_key do
      {:ok, current_person_key} ->
        # 2. Decrypt the current_person's private key with their session key (from Step 1).
        case Encrypted.Utils.decrypt(%{
               key: current_person_key,
               payload: current_person.key_pair["private"]
             }) do
          {:ok, private_key} ->
            %{public: current_person.key_pair["public"], private: private_key}

          {:error, error_message} ->
            error_message
        end

      {:error, error_message} ->
        error_message
    end
  end

  @doc """
  Decrypts payload for the current person's email
  with their current_person_key.

  TODO: this can be replaced I believe with function
  above.
  """
  def decrypt_person_email(
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

  def encrypt_person_email(
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
                # 4. Encrypt the payload using the person_key (from Step 3).
                encrypted_email = Encrypted.Utils.encrypt(%{key: person_key, payload: payload})
                encrypted_email

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
  Encrypts the current person's data
  with their current_person_key and
  public key.
  """
  def encrypt_person_attributes(
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
                # 4. Encrypt the payload using the person_key (from Step 3).
                encrypted_email = Encrypted.Utils.encrypt(%{key: person_key, payload: payload})
                encrypted_email

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
