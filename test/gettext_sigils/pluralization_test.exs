defmodule GettextSigils.PluralizationTest do
  use ExUnit.Case, async: true

  alias GettextSigils.Interpolation
  alias GettextSigils.Pluralization

  @separator "||"

  defmacrop split_parsed!(ast, separator \\ @separator) do
    parsed = Interpolation.parse!(ast)

    quote do
      Pluralization.split!(unquote(parsed), unquote(separator))
    end
  end

  describe "split!" do
    test "splits on separator and extracts count" do
      count = 3
      assert split_parsed!("One error||#{count} errors") == {"One error", "%{count} errors", 3, []}
    end

    test "removes count from bindings, keeps others" do
      count = 2
      name = "validation"

      {_msgid, _msgid_plural, _count, bindings} =
        split_parsed!("One #{name} error||#{count} #{name} errors")

      assert bindings == [name: "validation"]
    end

    test "count in singular part only" do
      count = 1
      assert split_parsed!("#{count} error||many errors") == {"%{count} error", "many errors", 1, []}
    end

    test "count via explicit key syntax" do
      users = [1, 2, 3]

      assert split_parsed!("One user||#{count :: length(users)} users") ==
               {"One user", "%{count} users", 3, []}
    end
  end

  describe "custom separator" do
    test "splits on custom separator" do
      count = 3

      assert split_parsed!("One error‖#{count} errors", "‖") ==
               {"One error", "%{count} errors", 3, []}
    end
  end

  describe "errors" do
    test "raises when separator is missing" do
      assert_raise ArgumentError, ~r/the N modifier requires a separator/, fn ->
        Pluralization.split!({"No separator here", [count: quote(do: count)]}, @separator)
      end
    end

    test "raises on multiple separators" do
      assert_raise ArgumentError, ~r/more than one separator/, fn ->
        Pluralization.split!({"a||b||c", [count: quote(do: count)]}, @separator)
      end
    end

    test "raises when count binding is missing" do
      assert_raise ArgumentError, ~r/requires a "count" binding/, fn ->
        Pluralization.split!({"One error||many errors", []}, @separator)
      end
    end
  end
end
