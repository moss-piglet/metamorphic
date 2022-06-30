defmodule Metamorphic.Billing.WebhookProcessorTest do
  use Metamorphic.DataCase

  @stripe_service Application.compile_env(:metamorphic, :stripe_service)

  alias Metamorphic.Billing.WebhookProcessor
  alias MetamorphicWeb.StripeWebhookController

  def event_fixture(attrs \\ %{}) do
    @stripe_service.Event.generate(attrs)
  end

  describe "listen for and processing a stripe event" do
    test "processes incoming events after broadcasting it" do
      start_supervised(WebhookProcessor, [])
      WebhookProcessor.subscribe()

      event = event_fixture()
      StripeWebhookController.notify_subscribers(event)

      assert_receive {:event, _}
    end
  end
end
