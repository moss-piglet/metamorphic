defmodule MetamorphicWeb.PersonEncryption do
  @moduledoc """
  This controller facilitates the person encryption.
  """
  import Plug.Conn

  def get_person_from_session(conn) do
    person = get_session(conn, :person)
    person_key = get_session(conn, :key)

    %{person: person, person_key: person_key}
  end
end
