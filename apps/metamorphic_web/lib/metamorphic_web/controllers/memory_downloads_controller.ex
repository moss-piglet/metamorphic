defmodule MetamorphicWeb.MemoryDownloadsController do
  use MetamorphicWeb, :controller

  alias Metamorphic.Accounts
  alias Metamorphic.Memories
  alias Metamorphic.Relationships

  alias MetamorphicWeb.Extensions.{MemoryProcessor, SharedMemoryProcessor}
  alias MetamorphicWeb.{LiveMemoryHelpers, LiveRelationshipHelpers}
  alias MetamorphicWeb.Router.Helpers, as: Routes

  def download_memory(conn, %{
        "current_person_id" => current_person_id,
        "memory_id" => memory_id,
        "memory_name" => memory_name,
        "memory_file_type" => memory_file_type,
        "memory_person_id" => memory_person_id
      }) do
    memory_origin_person = Accounts.get_person!(memory_person_id)
    current_person = Accounts.get_person!(current_person_id)
    memory = Memories.safe_get_memory(memory_id, current_person)

    if memory_origin_person != nil && current_person != nil do
      case LiveMemoryHelpers.check_if_current_person_can_download_memory(
             memory_origin_person,
             current_person
           ) do
        true ->
          memory_processor_key = current_person_id
          memory_binary = MemoryProcessor.get_ets_memory(memory_processor_key, memory.id)

          conn
          |> send_download({:binary, memory_binary},
            filename: memory_name,
            content_type: memory_file_type
          )

        _ ->
          conn
          |> redirect(to: Routes.memories_path(conn, :index))
          |> halt()
      end
    else
      conn
      |> redirect(to: Routes.memories_path(conn, :index))
      |> halt()
    end
  end

  def download_memory(conn, _params) do
    conn
    |> redirect(to: Routes.memories_path(conn, :index))
    |> halt()
  end

  def download_shared_memory(conn, %{
        "current_person_id" => current_person_id,
        "memory_id" => memory_id,
        "memory_name" => memory_name,
        "memory_file_type" => memory_file_type,
        "relationship_id" => relationship_id
      }) do
    relationship = Relationships.get_relationship!(relationship_id)
    current_person = Accounts.get_person!(current_person_id)

    if relationship != nil && current_person != nil do
      case LiveRelationshipHelpers.check_if_current_person_can_download_shared_memory(
             relationship,
             current_person
           ) do
        true ->
          memory_processor_key = current_person_id

          shared_memory_binary =
            SharedMemoryProcessor.get_ets_memory(memory_processor_key, memory_id)

          conn
          |> send_download({:binary, shared_memory_binary},
            filename: memory_name,
            content_type: memory_file_type
          )

        _ ->
          conn
          |> redirect(to: Routes.memories_path(conn, :index))
          |> halt()
      end
    else
      conn
      |> redirect(to: Routes.memories_path(conn, :index))
      |> halt()
    end
  end

  def download_shared_memory(conn, _params) do
    conn
    |> redirect(to: Routes.memories_path(conn, :index))
    |> halt()
  end
end
