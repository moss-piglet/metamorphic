defmodule Metamorphic.Extensions.PasswordGenerator.PassphraseGeneratorTest do
  use ExUnit.Case
  require Logger

  alias Metamorphic.Extensions.PasswordGenerator.PassphraseGenerator

  @moduletag :capture_log

  doctest Metamorphic.Extensions.PasswordGenerator.PassphraseGenerator

  test "generates a passphrase with 5 words and spaces " do
    passphrase = PassphraseGenerator.generate_passphrase(%{words: 5, separator: " "})

    passphrase_count =
      passphrase
      |> String.split(" ")
      |> Enum.count()

    assert passphrase != ""
    assert String.contains?(passphrase, " ")
    assert passphrase_count == 5
  end

  test "generates a passphrase with 10 words and commas instead of spaces" do
    passphrase = PassphraseGenerator.generate_passphrase(%{words: 10, separator: ","})

    passphrase_count =
      passphrase
      |> String.split(",")
      |> Enum.count()

    assert passphrase != ""
    assert String.contains?(passphrase, ",")
    assert passphrase_count == 10
  end

  test "generates a passphrase with 7 words and dashes" do
    passphrase = PassphraseGenerator.generate_passphrase(%{words: 7, separator: "-"})

    passphrase_count =
      passphrase
      |> String.split("-")
      |> Enum.count()

    assert passphrase != ""
    assert String.contains?(passphrase, "-")
    assert passphrase_count == 7
  end
end
