defmodule Metamorphic.Workers.MemoryDeleteWorker do
  @moduledoc """
  Oban worker for deleting person memories (currently
  only deleteing memory from S3).
  """
  use Oban.Worker, queue: :memories

  # alias Metamorphic.Accounts
  alias MetamorphicWeb.Extensions.MemoryProcessor

  @s3_memories_bucket System.fetch_env!("STORJ_MEMORIES_BUCKET")
  @s3_host System.fetch_env!("STORJ_HOST")

  def perform(%Oban.Job{
        args: %{"current_person_id" => current_person_id, "memory_id" => memory_id, "url" => url}
      }) do
    key =
      url
      |> String.split(@s3_host)
      |> List.last()
      |> String.split(@s3_memories_bucket)
      |> List.last()

    ExAws.S3.delete_object(@s3_memories_bucket, key) |> ExAws.request()
    MemoryProcessor.delete_ets_memory(current_person_id, memory_id)

    :ok
  end
end
