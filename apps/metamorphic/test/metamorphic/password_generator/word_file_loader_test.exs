defmodule Metamorphic.PasswordGenerator.WordFileLoaderTest do
  use ExUnit.Case
  require Logger

  alias Metamorphic.Extensions.PasswordGenerator.WordFileLoader

  @moduletag :capture_log

  doctest Metamorphic.Extensions.PasswordGenerator.WordFileLoader

  test "loads words in memory" do
    words = WordFileLoader.load_words()
    assert words != []
  end

  test "get first word" do
    word =
      WordFileLoader.load_words()
      |> Enum.take(1)

    assert word == [%{number: 11_111, word: "abacus"}]
  end
end
