defmodule GettextSigils.ModifiersTest do
  use ExUnit.Case

  alias GettextSigils.Modifiers

  describe "resolve!/2" do
    test "with no modifiers uses :default domain without context" do
      assert Modifiers.resolve!(~c"", []) == {:default, nil}
    end

    test "with modifiers" do
      opts = [
        domain: "domain",
        context: "context",
        modifiers: [
          a: [domain: "A", context: "a"],
          b: [context: "b"],
          x: [domain: nil]
        ]
      ]

      assert Modifiers.resolve!(~c"", opts) == {"domain", "context"}
      assert Modifiers.resolve!(~c"a", opts) == {"A", "a"}
      assert Modifiers.resolve!(~c"ab", opts) == {"A", "b"}
      assert Modifiers.resolve!(~c"ba", opts) == {"A", "a"}
      assert Modifiers.resolve!(~c"abx", opts) == {:default, "b"}
    end

    test "with unknown modifier raises exception" do
      assert_raise ArgumentError, ~r/unknown sigil modifier :x/, fn ->
        Modifiers.resolve!(~c"x", [])
      end
    end
  end
end
