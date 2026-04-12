defmodule GettextSigils.Modifiers.PluralModifierTest do
  use ExUnit.Case, async: true

  alias GettextSigils.Interpolation
  alias GettextSigils.Modifiers.PluralModifier

  defmacrop pluralize_parsed(ast) do
    parsed = Interpolation.parse!(ast)

    quote do
      PluralModifier.pluralize(unquote(parsed), [])
    end
  end

  describe "pluralize/2" do
    test "extracts the count binding and reuses msgid as msgid_plural" do
      count = 3

      assert pluralize_parsed("#{count} error(s)") ==
               {:ok, {"%{count} error(s)", "%{count} error(s)", 3, []}}
    end

    test "preserves other bindings" do
      count = 2
      name = "validation"

      assert pluralize_parsed("#{count} #{name} error(s)") ==
               {:ok, {"%{count} %{name} error(s)", "%{count} %{name} error(s)", 2, [name: "validation"]}}
    end

    test "supports count via explicit key syntax" do
      users = [1, 2, 3]

      assert pluralize_parsed("#{count = length(users)} user(s)") ==
               {:ok, {"%{count} user(s)", "%{count} user(s)", 3, []}}
    end

    test "returns {:error, reason} when count binding is missing" do
      assert PluralModifier.pluralize({"no count here", []}, []) ==
               {:error, ~s|plural message requires a "count" binding, but none was found|}
    end
  end
end
