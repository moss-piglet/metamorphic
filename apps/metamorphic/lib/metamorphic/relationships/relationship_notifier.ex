defmodule Metamorphic.Relationships.RelationshipNotifier do
  @moduledoc """
  Relationship email notification module that logs messages
  to the terminal in a local environment, and uses
  [Bamboo](https://hexdocs.pm/bamboo) to send email
  notifications in a production environment.
  """
  # For simplicity, this module simply logs messages to the terminal.
  # You should replace it by a proper email or notification tool, such as:
  #
  #   * Swoosh - https://hexdocs.pm/swoosh
  #   * Bamboo - https://hexdocs.pm/bamboo
  #
  use Bamboo.Phoenix, view: MetamorphicWeb.EmailView

  alias Metamorphic.Mailer

  @from_address "hello@metamorphic.app"
  @reply_to_address "support@metamorphic.app"

  @doc """
  Deliver instructions to confirm relationship.
  """
  def deliver_relationship_confirmation_instructions(person, relationship, requester, url) do
    new_email()
    |> put_layout({MetamorphicWeb.LayoutView, :email})
    |> to(person.email)
    |> from(@from_address)
    |> put_header("Reply-To", @reply_to_address)
    |> subject("Please confirm your relationship")
    |> render(:relationship_confirmation_instructions, %{
      relation_name: person.name,
      relationship_name: relationship.relationship_type.name,
      relationship_type: relationship.relationship_type_id,
      url: url,
      requester_name: requester.name,
      requester_email: requester.email
    })
    |> Mailer.deliver_later()
  end
end
