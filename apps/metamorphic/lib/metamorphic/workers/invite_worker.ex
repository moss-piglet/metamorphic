defmodule Metamorphic.Workers.InviteWorker do
  @moduledoc """
  Oban worker for sending early access invites.
  """
  use Oban.Worker, queue: :mailers

  alias Metamorphic.Invitations
  alias Metamorphic.Invitations.InviteNotifier

  def perform(%Oban.Job{
        args: %{
          "email" => email,
          "invite_codes" => invite_codes,
          "invite_id" => invite_id,
          "url" => url
        }
      }) do
    InviteNotifier.deliver_invite_codes_for_early_access(email, invite_codes, url)

    invite = Invitations.get_invite!(invite_id)
    Invitations.update_invite(invite, %{sent_codes: true})

    :ok
  end
end
