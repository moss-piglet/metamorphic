defmodule Metamorphic.Encrypted.Utils do
  @moduledoc """
  Encryption utility functions for implementing
  asymmetric encryption for people's accounts.

  Special thanks to [@badubizzle](https://github.com/badubizzle).
  """
  @spec generate_key :: binary
  def generate_key() do
    key = :enacl.randombytes(:enacl.secretbox_KEYBYTES())
    encode(key)
  end

  @doc """
  Takes in a key and payload and encrypt payload with the key
  map: %{key: key, payload: payload}
  """
  @spec encrypt(%{key: binary, payload: binary}) :: binary
  def encrypt(%{key: key, payload: payload}) do
    key_size = :enacl.secretbox_KEYBYTES()
    {:ok, <<d_key::binary-size(key_size)>>} = decode(key)
    nonce = :enacl.randombytes(:enacl.secretbox_NONCEBYTES())
    ciphertext = :enacl.secretbox(payload, nonce, d_key)
    encode(nonce <> ciphertext)
  end

  @spec decrypt(%{key: binary, payload: binary}) :: {:error, :failed_verification} | {:ok, binary}
  def decrypt(%{key: key, payload: payload}) do
    key = decode_key(key, :enacl.secretbox_KEYBYTES())
    nonce_size = :enacl.secretbox_NONCEBYTES()
    {:ok, <<nonce::binary-size(nonce_size), ciphertext::binary>>} = decode(payload)
    :enacl.secretbox_open(ciphertext, nonce, key)
  end

  @spec decrypt_key_hash(
          binary,
          binary
        ) :: {:error, :failed_verification} | {:ok, binary}
  def decrypt_key_hash(pwd, key_hash) do
    [salt, uk] = key_hash |> String.split("$")
    key = derive_pwd_key(pwd, salt_string_to_bin(salt))

    case decrypt(%{key: key, payload: uk}) do
      {:ok, d_key} -> {:ok, d_key}
      {:error, e} -> {:error, e}
    end
  end

  @doc """
  Takes a password and a key and generate encrypted unique user key.
  This key can only be decrypted with the same password
  """
  @spec generate_key_hash(binary, binary) :: %{key_hash: binary}
  def generate_key_hash(pwd, key) do
    # derive a key from the password
    %{key: gen_key, salt: salt} = derive_pwd_key(pwd)

    # encrypt unique key with password derived key

    key_hash = encrypt(%{key: gen_key, payload: key})

    # return encrypted key with the salt
    %{key_hash: salt <> "$" <> key_hash}
  end

  @spec generate_key_pairs :: %{private: binary, public: binary}
  def generate_key_pairs() do
    %{secret: secret, public: public} = :enacl.box_keypair()
    %{private: encode(secret), public: encode(public)}
  end

  @spec decrypt_message_for_user(binary, %{private: binary, public: binary}) ::
          {:error, :failed_verification} | {:ok, binary}
  def decrypt_message_for_user(encrypted_message, %{public: public_key, private: private_key}) do
    :enacl.box_seal_open(decode!(encrypted_message), decode!(public_key), decode!(private_key))
  end

  @spec encrypt_message_for_user_with_pk(
          binary,
          %{public: binary}
        ) :: binary
  def encrypt_message_for_user_with_pk(message, %{public: public_key}) do
    result = :enacl.box_seal(message, decode!(public_key))
    encode(result)
  end

  # PRIVATE FUNCTIONS

  defp encode(d) do
    d
    |> Base.encode64()
  end

  defp decode(d) do
    d
    |> Base.decode64()
  end

  defp decode!(d) do
    d
    |> Base.decode64!()
  end

  defp decode_key(key, key_size) do
    {:ok, <<secret_key::binary-size(key_size)>>} = decode(key)
    secret_key
  end

  defp derive_pwd_key(pwd, salt) do
    p = :enacl.pwhash(pwd, salt)
    encode(p)
  end

  defp derive_pwd_key(pwd) do
    salt = generate_salt_bin()
    %{salt: encode(salt), key: derive_pwd_key(pwd, salt)}
  end

  defp generate_salt_bin() do
    :enacl.randombytes(16)
  end

  defp salt_string_to_bin(salt) do
    {:ok, data} = decode(salt)
    data
  end
end
