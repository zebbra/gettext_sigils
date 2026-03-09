defmodule GettextSigils.ModifiersTest do
  use ExUnit.Case

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
