defmodule Metamorphic.Workers.AvatarDeleteWorker do
  @moduledoc """
  Oban worker for deleting person avatars.
  """
  use Oban.Worker, queue: :avatars

  # alias Metamorphic.Accounts
  alias MetamorphicWeb.Extensions.AvatarProcessor

  @s3_avatars_bucket System.fetch_env!("STORJ_AVATARS_BUCKET")
  @s3_host System.fetch_env!("STORJ_HOST")

  def perform(%Oban.Job{
        args: %{
          "current_person_id" => current_person_id,
          "url" => url,
          "update_avatar" => _update_avatar
        }
      }) do
    key =
      url
      |> String.split(@s3_host)
      |> List.last()
      |> String.split(@s3_avatars_bucket)
      |> List.last()

    ExAws.S3.delete_object(@s3_avatars_bucket, key) |> ExAws.request()
    AvatarProcessor.delete_ets_avatar(current_person_id)

    :ok
  end
end
