defmodule Util do
  @moduledoc """
  A set of utility functions for use all over the project.
  """

  @doc """
  Useful for printing maps onto the page during development. Or passing a map to a hook
  """
  def to_json(obj) do
    Jason.encode!(obj, pretty: true)
  end

  @doc """
  Get a random string of given length.
  Returns a random url safe encoded64 string of the given length.
  Used to generate tokens for the various modules that require unique tokens.
  """
  def random_string(length \\ 10) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  @doc """
  Get a random numeric string of given length.
  """
  def random_numeric_string(length \\ 10) do
    length
    |> :crypto.strong_rand_bytes()
    |> :crypto.bytes_to_integer()
    |> Integer.to_string()
    |> binary_part(0, length)
  end

  @doc """
  Immitates .compact in Ruby... removes nil values from an array https://ruby-doc.org/core-1.9.3/Array.html#method-i-compact
  """
  def compact(list), do: Enum.filter(list, &(!is_nil(&1)))

  def email_valid?(email) do
    EmailChecker.valid?(email)
  end

  @doc """
  Util.blank?(nil) => true
  Util.blank?("") => true
  Util.blank?([]) => true
  Util.blank?("Hello") => false
  """
  def blank?(term) do
    Blankable.blank?(term)
  end

  @doc "Opposite of blank?"
  def present?(term) do
    !Blankable.blank?(term)
  end

  @doc "Check if a map has atoms as keys"
  def map_has_atom_keys?(map) do
    Map.keys(map)
    |> List.first()
    |> is_atom()
  end

  @doc """
  iex> CurrencyFormatter.format(123456)
    "$1,234.56"
  """
  def format_money(cents, currency \\ "USD") do
    CurrencyFormatter.format(cents, currency)
  end

  @doc "Trim whitespace on either end of a string. Account for nil"
  def trim(str) when is_nil(str), do: str
  def trim(str) when is_binary(str), do: String.trim(str)

  @doc "Useful for when you have an array of strings coming in from a user form"
  def trim_strings_in_array(array) do
    Enum.map(array, &String.trim/1)
    |> Enum.filter(&present?/1)
  end

  @doc """
  Examples:

      pluralize("hat", 0) => hats
      pluralize("hat", 1) => hat
      pluralize("hat", 2) => hats
  """
  def pluralize(word, count), do: Inflex.inflect(word, count)

  @doc """
  Examples:

      Util.truncate("This is a very long string", 15) => "This is a very..."
  """
  def truncate(text, count \\ 10) do
    PetalFramework.Extensions.StringExt.truncate(text, length: count)
  end

  @doc """
  Examples:
      number_with_delimiter(1000) => "1,000"
      number_with_delimiter(1000000) => "1,000,000"
  """
  def number_with_delimiter(i) when is_binary(i), do: number_with_delimiter(String.to_integer(i))

  def number_with_delimiter(i) when is_integer(i) do
    i
    |> Integer.to_charlist()
    |> Enum.reverse()
    |> Enum.chunk_every(3, 3, [])
    |> Enum.join(",")
    |> String.reverse()
  end

  @doc """
  For updating a database object in a list of database objects.
  The object must have an ID and exist in the list
  eg. users = Util.replace_object_in_list(users, updated_user)
  """
  def replace_object_in_list(list, object) do
    put_in(
      list,
      [Access.filter(&(&1.id == object.id))],
      object
    )
  end
end
