defmodule Metamorphic.Encrypted.Orgs.New do
  @moduledoc """
  Encryption functions for creating new orgs
  for a person.
  """
  alias Metamorphic.Encrypted

  def prepare_encrypted_org_fields(org_params, current_person) do
    # 1. Generate the org_key.
    org_key = Encrypted.Utils.generate_key()

    # 2. Bind the current_person's public key.
    person_public_key = current_person.key_pair["public"]

    # 3. Bind the org name and slug.
    org_name = org_params.name
    org_slug = org_params.slug

    # 7. Encrypt nam and slug with org_key.
    encrypted_org_name =
      Encrypted.Utils.encrypt(%{key: org_key, payload: org_name})

    encrypted_org_slug =
      Encrypted.Utils.encrypt(%{key: org_key, payload: org_slug})

    # 8. Encrypt the org_key with the current_person's public key (from Step 2).
    encrypted_org_key =
      Encrypted.Utils.encrypt_message_for_user_with_pk(org_key, %{
        public: person_public_key
      })

    # 9. Update the org_params map with the encrypted fields.
    org_params =
      org_params
      |> Map.put(:name, encrypted_org_name)
      |> Map.put(:slug, encrypted_org_slug)
      |> Map.put(:org_key, encrypted_org_key)

    org_params
  end
end
