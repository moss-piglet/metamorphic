defmodule Metamorphic.Mailer do
  @moduledoc """
  `Mailer` module to specify the mailing
  application to use for Metamorphic.

  Currently configured to use [Bamboo](https://hexdocs.pm/bamboo).
  """
  use Bamboo.Mailer, otp_app: :metamorphic
end
