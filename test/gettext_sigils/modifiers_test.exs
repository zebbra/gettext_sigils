defmodule GettextSigils.ModifiersTest do
  use ExUnit.Case

  describe "single modifier" do
    use GettextSigils,
      backend: GettextSigils.DummyGettext,
      sigils: [
        domain: "frontend",
        modifiers: [
          e: [domain: "errors"],
          m: [context: "MyModule"]
        ]
      ]

    test "no modifier uses defaults" do
      assert ~t"hello" == "frontend: hello"
    end

    test "domain modifier overrides domain" do
      assert ~t"hello"e == "errors: hello"
    end

    test "context modifier adds context" do
      assert ~t"hello"m == "frontend/MyModule: hello"
    end
  end

  describe "multiple modifiers" do
    use GettextSigils,
      backend: GettextSigils.DummyGettext,
      sigils: [
        domain: "frontend",
        modifiers: [
          e: [domain: "errors"],
          m: [context: "MyModule"],
          g: [domain: "default", context: nil]
        ]
      ]

    test "domain + context modifiers combine" do
      assert ~t"hello"em == "errors/MyModule: hello"
    end

    test "modifier order matters — last domain wins" do
      assert ~t"hello"eg == "default: hello"
      assert ~t"hello"ge == "errors: hello"
    end

    test "nil context removes context" do
      assert ~t"hello"mg == "default: hello"
    end

    test "modifiers work with interpolation" do
      name = "world"
      assert ~t"hello #{name}"e == "errors: hello world"
    end
  end

  describe "unknown modifier" do
    test "raises on undefined modifier" do
      assert_raise ArgumentError, ~r/unknown sigil modifier/, fn ->
        defmodule UnknownModifier do
          @moduledoc false
          use GettextSigils,
            backend: GettextSigils.DummyGettext,
            sigils: [modifiers: [e: [domain: "errors"]]]

          def test_it, do: ~t"hello"x
        end
      end
    end
  end
end
