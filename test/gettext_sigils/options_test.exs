defmodule GettextSigils.OptionsTest do
  use ExUnit.Case, async: true

  alias GettextSigils.Options

  describe "validate!/1 top-level options" do
    test "accepts valid options" do
      Options.validate!(domain: "errors", context: "admin", modifiers: [e: [domain: "errors"]])
    end

    test "accepts empty options" do
      Options.validate!([])
    end

    test "raises on unknown top-level option" do
      assert_raise NimbleOptions.ValidationError, ~r/unknown options.*doman/, fn ->
        Options.validate!(doman: "errors")
      end
    end

    test "accepts nil context" do
      Options.validate!(context: nil)
    end

    test "raises when modifiers is not a keyword list" do
      assert_raise NimbleOptions.ValidationError, ~r/:modifiers option/, fn ->
        Options.validate!(modifiers: "bad")
      end
    end
  end

  describe "validate!/1 modifier options" do
    test "raises on non-lowercase modifier key" do
      assert_raise NimbleOptions.ValidationError, ~r/must be lowercase letters/, fn ->
        Options.validate!(modifiers: [A: [domain: "errors"]])
      end
    end

    test "raises on non-keyword-list modifier options" do
      assert_raise NimbleOptions.ValidationError, ~r/must be a keyword list/, fn ->
        Options.validate!(modifiers: [e: "errors"])
      end
    end

    test "raises on unknown modifier options" do
      assert_raise NimbleOptions.ValidationError, ~r/unknown options.*domainn/, fn ->
        Options.validate!(modifiers: [e: [domainn: "errors"]])
      end
    end
  end

  describe "validate!/1 pluralization options" do
    test "accepts valid pluralization options" do
      Options.validate!(pluralization: [separator: "||"])
    end

    test "accepts empty pluralization options" do
      Options.validate!(pluralization: [])
    end

    test "raises when separator is not a binary" do
      assert_raise NimbleOptions.ValidationError, ~r/separator must be a non-empty string/, fn ->
        Options.validate!(pluralization: [separator: 123])
      end
    end

    test "raises when separator is an empty string" do
      assert_raise NimbleOptions.ValidationError, ~r/separator must be a non-empty string/, fn ->
        Options.validate!(pluralization: [separator: ""])
      end
    end

    test "raises on unknown pluralization keys" do
      assert_raise NimbleOptions.ValidationError, ~r/unknown options.*foo/, fn ->
        Options.validate!(pluralization: [foo: "bar"])
      end
    end

    test "raises when pluralization is not a keyword list" do
      assert_raise NimbleOptions.ValidationError, ~r/:pluralization option/, fn ->
        Options.validate!(pluralization: "bad")
      end
    end
  end
end
