defmodule GettextSigils.PluralizationTest do
  use ExUnit.Case, async: true

  alias GettextSigils.Interpolation
  alias GettextSigils.Pluralization

  @separator "‖"

  defmacrop maybe_split_parsed!(ast, separator \\ @separator) do
    parsed = Interpolation.parse!(ast)

    quote do
      Pluralization.maybe_split!(unquote(parsed), unquote(separator))
    end
  end

  describe "singular (no separator)" do
    test "returns msgid and bindings unchanged" do
      assert maybe_split_parsed!("Hello") == {"Hello", []}
    end

    test "preserves bindings" do
      name = "Alice"
      assert maybe_split_parsed!("Hello #{name}") == {"Hello %{name}", [name: "Alice"]}
    end
  end

  describe "plural" do
    test "splits on separator and extracts count" do
      count = 3
      assert maybe_split_parsed!("One error‖#{count} errors") == {"One error", "%{count} errors", 3, []}
    end

    test "removes count from bindings, keeps others" do
      count = 2
      name = "validation"

      {_msgid, _msgid_plural, _count, bindings} =
        maybe_split_parsed!("One #{name} error‖#{count} #{name} errors")

      assert bindings == [name: "validation"]
    end

    test "count in singular part only" do
      count = 1
      assert maybe_split_parsed!("#{count} error‖many errors") == {"%{count} error", "many errors", 1, []}
    end

    test "count via explicit key syntax" do
      users = [1, 2, 3]

      assert maybe_split_parsed!("One user‖#{count :: length(users)} users") ==
               {"One user", "%{count} users", 3, []}
    end
  end

  describe "custom separator" do
    test "splits on custom separator" do
      count = 3

      assert maybe_split_parsed!("One error||#{count} errors", "||") ==
               {"One error", "%{count} errors", 3, []}
    end
  end

  describe "errors" do
    test "raises on multiple separators" do
      assert_raise ArgumentError, ~r/more than one separator/, fn ->
        Pluralization.maybe_split!({"a‖b‖c", [count: quote(do: count)]}, @separator)
      end
    end

    test "raises when count binding is missing" do
      assert_raise ArgumentError, ~r/requires a "count" binding/, fn ->
        Pluralization.maybe_split!({"One error‖many errors", []}, @separator)
      end
    end
  end
end
