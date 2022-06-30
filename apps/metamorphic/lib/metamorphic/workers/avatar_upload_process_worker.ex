defmodule Metamorphic.Workers.AvatarUploadProcessWorker do
  @moduledoc """
  Oban worker for saving temporary decrypted
  file binary to :ets storage.
  """
  use Oban.Worker, queue: :avatars

  alias MetamorphicWeb.Extensions.AvatarProcessor

  def perform(%Oban.Job{
        args: %{"temp_file" => temp_file, "avatar_processor_key" => avatar_processor_key}
      }) do
    {:ok, temp_file} = Base.decode64(temp_file)
    AvatarProcessor.put_ets_avatar(avatar_processor_key, temp_file)

    :ok
  end
end
