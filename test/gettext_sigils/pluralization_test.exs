defmodule GettextSigils.PluralizationTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  alias GettextSigils.Interpolation
  alias GettextSigils.Pluralization

  @separator "||"

  defmacrop split_parsed!(ast, separator \\ @separator) do
    parsed = Interpolation.parse!(ast)

    quote do
      Pluralization.split!(unquote(parsed), unquote(separator))
    end
  end

  describe "split! (deprecated separator)" do
    test "splits on separator and extracts count" do
      count = 3

      capture_io(:stderr, fn ->
        assert split_parsed!("One error||#{count} errors") == {"One error", "%{count} errors", 3, []}
      end)
    end

    test "removes count from bindings, keeps others" do
      count = 2
      name = "validation"

      capture_io(:stderr, fn ->
        {_msgid, _msgid_plural, _count, bindings} =
          split_parsed!("One #{name} error||#{count} #{name} errors")

        assert bindings == [name: "validation"]
      end)
    end

    test "count in singular part only" do
      count = 1

      capture_io(:stderr, fn ->
        assert split_parsed!("#{count} error||many errors") ==
                 {"%{count} error", "many errors", 1, []}
      end)
    end

    test "count via explicit key syntax" do
      users = [1, 2, 3]

      capture_io(:stderr, fn ->
        assert split_parsed!("One user||#{count :: length(users)} users") ==
                 {"One user", "%{count} users", 3, []}
      end)
    end
  end

  describe "custom separator (deprecated)" do
    test "splits on custom separator" do
      count = 3

      capture_io(:stderr, fn ->
        assert split_parsed!("One error‖#{count} errors", "‖") ==
                 {"One error", "%{count} errors", 3, []}
      end)
    end
  end

  describe "errors" do
    test "uses shared message when separator is missing" do
      {msgid, msgid_plural, _count, bindings} =
        Pluralization.split!({"No separator here", [count: quote(do: count)]}, @separator)

      assert msgid == "No separator here"
      assert msgid_plural == "No separator here"
      assert bindings == []
    end

    test "raises on multiple separators" do
      assert_raise ArgumentError, ~r/more than one separator/, fn ->
        Pluralization.split!({"a||b||c", [count: quote(do: count)]}, @separator)
      end
    end

    test "raises when count binding is missing" do
      assert_raise ArgumentError, ~r/requires a "count" binding/, fn ->
        Pluralization.split!({"no count here", []}, @separator)
      end
    end
  end

  describe "deprecation warnings" do
    test "emits warning when using separator" do
      warning =
        capture_io(:stderr, fn ->
          assert Pluralization.split!({"One error||%{count} errors", [count: 3]}, "||") ==
                   {"One error", "%{count} errors", 3, []}
        end)

      assert warning =~ "using a separator"
      assert warning =~ "deprecated"
    end

    test "no warning for shared message" do
      warning =
        capture_io(:stderr, fn ->
          assert Pluralization.split!({"%{count} error(s)", [count: 3]}, "||") ==
                   {"%{count} error(s)", "%{count} error(s)", 3, []}
        end)

      assert warning == ""
    end
  end

  describe "shared message (no separator)" do
    test "uses msgid as both singular and plural" do
      count = 3
      assert split_parsed!("#{count} error(s)") == {"%{count} error(s)", "%{count} error(s)", 3, []}
    end

    test "preserves other bindings" do
      count = 2
      name = "validation"

      assert split_parsed!("#{count} #{name} error(s)") ==
               {"%{count} %{name} error(s)", "%{count} %{name} error(s)", 2, [name: "validation"]}
    end

    test "count via explicit key syntax" do
      users = [1, 2, 3]

      assert split_parsed!("#{count :: length(users)} user(s)") ==
               {"%{count} user(s)", "%{count} user(s)", 3, []}
    end

    test "raises when count binding is missing" do
      assert_raise ArgumentError, ~r/requires a "count" binding/, fn ->
        Pluralization.split!({"no count here", []}, "||")
      end
    end
  end
end
