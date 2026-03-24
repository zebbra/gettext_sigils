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
end
