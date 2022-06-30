defmodule MetamorphicWeb.EmailView do
  use MetamorphicWeb, :view
  alias MetamorphicWeb.Components.EmailComponents

  def first_name(name) do
    name
    |> String.split(" ")
    |> Enum.at(0)
  end
end
