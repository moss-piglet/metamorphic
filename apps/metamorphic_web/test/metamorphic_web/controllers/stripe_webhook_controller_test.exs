defmodule MetamorphicWeb.StripeWebhookControllerTest do
  use MetamorphicWeb.ConnCase, async: true

  def set_correct_signature_and_body(%{conn: conn}) do
    conn =
      conn
      |> assign(:raw_body, "")
      |> assign(:stripe_signature, "valid_signature")

    %{conn: conn}
  end

  def set_incorrect_signature_and_body(%{conn: conn}) do
    conn =
      conn
      |> assign(:raw_body, "")
      |> assign(:stripe_signature, "wrong_signature")

    %{conn: conn}
  end

  describe "receives webhooks from stripe without signature or raw_body" do
    test "renders response when data is valid", %{conn: conn} do
      conn = post(conn, Routes.stripe_webhook_path(conn, :create), customer_created())
      assert conn.status == 201
    end

    test "does not call the stripe service", %{conn: conn} do
      post(conn, Routes.stripe_webhook_path(conn, :create), customer_created())
      refute_received {:ok, _}
    end
  end

  describe "receives webhooks from stripe with correct signature and raw_body" do
    setup [:set_correct_signature_and_body]

    test "renders response when data is valid", %{conn: conn} do
      conn = post(conn, Routes.stripe_webhook_path(conn, :create), customer_created())
      assert conn.status == 201
    end

    test "calls the stripe service with a success response", %{conn: conn} do
      post(conn, Routes.stripe_webhook_path(conn, :create), customer_created())
      assert_received {:ok, "valid_webhook"}
    end
  end

  describe "receives webhooks from stripe with incorrect signature and raw_body" do
    setup [:set_incorrect_signature_and_body]

    test "renders response when data is valid", %{conn: conn} do
      conn = post(conn, Routes.stripe_webhook_path(conn, :create), customer_created())
      assert conn.status == 201
    end

    test "calls the stripe service with an invalid response", %{conn: conn} do
      post(conn, Routes.stripe_webhook_path(conn, :create), customer_created())
      assert_received {:ok, "invalid_webhook"}
    end
  end

  defp customer_created() do
    %{
      "api_version" => "2020-08-27",
      "created" => 1_602_082_941,
      "data" => %{
        "object" => %{
          "address" => nil,
          "balance" => 0,
          "created" => 1_602_082_941,
          "currency" => nil,
          "default_source" => nil,
          "delinquent" => false,
          "description" => nil,
          "discount" => nil,
          "email" => "dev@metamorphic.app",
          "id" => "cus_I9y6SpABXJLfki",
          "invoice_prefix" => "14F2730D",
          "invoice_settings" => %{
            "custom_fields" => nil,
            "default_payment_method" => nil,
            "footer" => nil
          },
          "livemode" => false,
          "metadata" => %{},
          "name" => "Dev Metamorphic",
          "next_invoice_sequence" => 1,
          "object" => "customer",
          "phone" => nil,
          "preferred_locales" => [],
          "shipping" => nil,
          "tax_exempt" => "none"
        }
      },
      "id" => "evt_1HZe9qJuBzfbzD5JJwyoizN2",
      "livemode" => false,
      "object" => "event",
      "pending_webhooks" => 2,
      "request" => %{
        "id" => "req_CdvV6QZy2ITNbs",
        "idempotency_key" => "2otrrsj7fdg4bkq2f00002k4"
      },
      "type" => "customer.created"
    }
  end
end
