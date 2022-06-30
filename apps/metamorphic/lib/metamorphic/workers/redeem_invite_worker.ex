defmodule Metamorphic.Workers.RedeemInviteWorker do
  @moduledoc """
  Oban worker for redeeming invite codes.

  This adds the invite code hash to the
  `:redeemed_codes_hash` upon successful
  registration.
  """
  use Oban.Worker, queue: :events

  alias Metamorphic.Invitations

  def perform(%Oban.Job{args: %{"invite_code" => invite_code}}) do
    invite = Invitations.get_invite_by_redeemed_code(invite_code)
    Invitations.redeem_invite(invite, %{redeemed_code: [invite_code]})

    :ok
  end
end
