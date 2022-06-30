defmodule Metamorphic.Extensions.PasswordGenerator.WordGeneratorTest do
  use ExUnit.Case
  require Logger

  alias Metamorphic.Extensions.PasswordGenerator.WordGenerator

  @moduletag :capture_log

  doctest Metamorphic.Extensions.PasswordGenerator.WordGenerator

  test "generates a number" do
    generated_number = WordGenerator.generate_number()
    assert generated_number > 11_110 && generated_number < 66_667
  end

  test "gets a new word" do
    word = WordGenerator.generate()
    assert word != ""
  end
end
