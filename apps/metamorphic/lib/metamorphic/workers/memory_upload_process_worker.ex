defmodule Metamorphic.Workers.MemoryUploadProcessWorker do
  @moduledoc """
  Oban worker for saving temporary decrypted
  file binary to :ets storage.
  """
  use Oban.Worker, queue: :memories

  alias MetamorphicWeb.Extensions.MemoryProcessor

  def perform(%Oban.Job{
        args: %{
          "temp_file" => temp_file,
          "memory_processor_key" => memory_processor_key,
          "memory_id" => memory_id
        }
      }) do
    {:ok, temp_file} = Base.decode64(temp_file)
    MemoryProcessor.put_ets_memory(memory_processor_key, temp_file, memory_id)

    :ok
  end
end
