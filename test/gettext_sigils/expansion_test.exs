defmodule GettextSigilsTest.Expansion.Wrapper do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      use GettextSigils,
        backend: GettextSigilsTest.DummyGettext,
        sigils: [domain: "wrapped", modifiers: [m: [context: inspect(__MODULE__)]]]

      @label ~t"label"m
    end
  end
end

defmodule GettextSigilsTest.Expansion.FromAttribute do
  @moduledoc false
  @dom "attr"
  use GettextSigils, backend: GettextSigilsTest.DummyGettext, sigils: [domain: @dom]

  def label, do: ~t"label"
end

defmodule GettextSigilsTest.Expansion do
  @moduledoc false
  use ExUnit.Case, async: true
  use GettextSigilsTest.Expansion.Wrapper

  alias GettextSigilsTest.Expansion.FromAttribute

  test "the sigil resolves its options when used in the block that sets them up" do
    assert @label == "wrapped/GettextSigilsTest.Expansion: label"
  end

  test "options built from an attribute resolve at runtime" do
    assert FromAttribute.label() == "attr: label"
  end

  test "options built from a variable resolve at runtime" do
    # A string, so the formatter cannot hoist the `use` above the assignment.
    [{module, _}] =
      Code.compile_string("""
      defmodule GettextSigilsTest.Expansion.FromVariable do
        dom = "var"
        use GettextSigils, backend: GettextSigilsTest.DummyGettext, sigils: [domain: dom]
        def label, do: ~t"label"
      end
      """)

    assert module.label() == "var: label"
  end
end
