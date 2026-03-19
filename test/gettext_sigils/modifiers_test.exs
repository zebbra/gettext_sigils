defmodule GettextSigils.ModifiersTest do
  use ExUnit.Case

  alias GettextSigils.Modifiers

  describe "resolve!/2" do
    test "with no modifiers uses :default domain without context" do
      assert Modifiers.resolve!(~c"", []) == {:default, nil, false}
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

      assert Modifiers.resolve!(~c"", opts) == {"domain", "context", false}
      assert Modifiers.resolve!(~c"a", opts) == {"A", "a", false}
      assert Modifiers.resolve!(~c"ab", opts) == {"A", "b", false}
      assert Modifiers.resolve!(~c"ba", opts) == {"A", "a", false}
      assert Modifiers.resolve!(~c"abx", opts) == {:default, "b", false}
    end

    test "N modifier enables pluralization" do
      assert Modifiers.resolve!(~c"N", []) == {:default, nil, true}
    end

    test "N modifier combines with other modifiers" do
      opts = [modifiers: [e: [domain: "errors"]]]

      assert Modifiers.resolve!(~c"eN", opts) == {"errors", nil, true}
      assert Modifiers.resolve!(~c"Ne", opts) == {"errors", nil, true}
    end

    test "with unknown modifier raises exception" do
      assert_raise ArgumentError, ~r/unknown sigil modifier :x/, fn ->
        Modifiers.resolve!(~c"x", [])
      end
    end
  end
end
