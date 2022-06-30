defmodule MetamorphicWeb.RealTime.Person.Letter do
  @moduledoc """
  Letter PubSub module to broadcast and subscribe
  to updates for letters.
  """

  @topic "person:letters:*"

  def subscribe(current_person) do
    Phoenix.PubSub.subscribe(MetamorphicWeb.PubSub, @topic <> "#{current_person.id}")
  end

  def broadcast_save_letter(letter) do
    {:ok, letter} = letter

    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> letter.person_id,
      {:save_letter, letter}
    )

    {:ok, letter}
  end

  def broadcast_delete_letter(letter) do
    {:ok, letter} = letter

    Phoenix.PubSub.broadcast!(
      MetamorphicWeb.PubSub,
      @topic <> letter.person_id,
      {:delete_letter, letter}
    )

    {:ok, letter}
  end
end
