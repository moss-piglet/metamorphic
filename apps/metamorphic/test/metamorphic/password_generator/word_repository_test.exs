defmodule Metamorphic.Extensions.PasswordGenerator.WordRepositoryTest do
  use ExUnit.Case
  require Logger

  alias Metamorphic.Extensions.PasswordGenerator.WordRepository

  @moduletag :capture_log

  doctest Metamorphic.Extensions.PasswordGenerator.WordRepository

  test "loads words in memory" do
    WordRepository.start_link()
    assert WordRepository.get_words() != []
  end

  test "get first word" do
    WordRepository.start_link()
    number = 11_111
    word = WordRepository.get_word_by_number(number)
    assert word == [%{number: number, word: "abacus"}]
  end
end
