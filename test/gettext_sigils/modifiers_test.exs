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

  describe "multiple modifiers" do
    use GettextSigils,
      backend: GettextSigils.DummyGettext,
      sigils: [
        default_domain: "frontend",
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
          use GettextSigils,
            backend: GettextSigils.DummyGettext,
            sigils: [modifiers: [e: [domain: "errors"]]]

          def test_it, do: ~t"hello"x
        end
      end
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

    test "raises on non-keyword-list modifier options" do
      assert_raise ArgumentError, ~r/must be a keyword list/, fn ->
        defmodule BadModifierOpts do
          use GettextSigils,
            backend: GettextSigils.DummyGettext,
            sigils: [modifiers: [e: "errors"]]
        end
      end
    end

    test "raises on unknown modifier options" do
      assert_raise ArgumentError, ~r/unknown options.*domainn/, fn ->
        defmodule TypoModifierOpts do
          use GettextSigils,
            backend: GettextSigils.DummyGettext,
            sigils: [modifiers: [e: [domainn: "errors"]]]
        end
      end
    end
  end
end
