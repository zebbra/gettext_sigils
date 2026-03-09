defmodule GettextSigils.ModifiersTest do
  use ExUnit.Case

  describe "single modifier" do
    use GettextSigils,
      backend: GettextSigils.DummyGettext,
      sigils: [
        default_domain: "frontend",
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

  describe "modifier validation" do
    test "raises on non-lowercase modifier key" do
      assert_raise ArgumentError, ~r/must be lowercase letters/, fn ->
        defmodule InvalidModifierKey do
          use GettextSigils,
            backend: GettextSigils.DummyGettext,
            sigils: [modifiers: [A: [domain: "errors"]]]
        end
      end
    end

    test "raises on nil domain in modifier" do
      assert_raise ArgumentError, ~r/domain.*nil/, fn ->
        defmodule NilDomainModifier do
          use GettextSigils,
            backend: GettextSigils.DummyGettext,
            sigils: [modifiers: [e: [domain: nil]]]
        end
      end
    end
  end
end
