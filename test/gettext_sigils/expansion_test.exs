defmodule GettextSigilsTest.Expansion.Wrapper do
  @moduledoc false
  defmacro __using__(_opts) do
    quote do
      use GettextSigils,
        backend: GettextSigilsTest.DummyGettext,
        sigils: [domain: "wrapped", modifiers: [m: [context: "wrapped"]]]

      @label ~t"label"mX
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
    assert @label == "label"
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

  test "a noop message outside a function resolves its options" do
    [{module, _}] =
      Code.compile_string("""
      defmodule GettextSigilsTest.Expansion.Attribute do
        use GettextSigils, backend: GettextSigilsTest.DummyGettext, sigils: [modifiers: [e: [domain: "errors"]]]
        @labels [a: ~t"A"X, b: ~t"B"eX]
        def labels, do: @labels
      end
      """)

    assert module.labels() == [a: "A", b: "B"]
  end

  test "outside a function, a translation raises a clear error" do
    assert_raise CompileError, ~r/needs the X modifier/, fn ->
      Code.compile_string("""
      defmodule GettextSigilsTest.Expansion.Translated do
        use GettextSigils, backend: GettextSigilsTest.DummyGettext
        @label ~t"label"
      end
      """)
    end
  end

  test "outside a function, non-literal options raise a clear error" do
    assert_raise CompileError, ~r/needs literal :sigils options/, fn ->
      Code.compile_string("""
      defmodule GettextSigilsTest.Expansion.AttributeAtBody do
        @dom "attr"
        use GettextSigils, backend: GettextSigilsTest.DummyGettext, sigils: [domain: @dom]
        @label ~t"label"X
      end
      """)
    end
  end

  test "a later use with non-literal options discards the options stored by an earlier use" do
    assert_raise CompileError, ~r/needs literal :sigils options/, fn ->
      Code.compile_string("""
      defmodule GettextSigilsTest.Expansion.StaleOptions do
        use GettextSigils, backend: GettextSigilsTest.DummyGettext, sigils: [domain: "first"]
        @dom "second"
        use GettextSigils, backend: GettextSigilsTest.DummyGettext, sigils: [domain: @dom]
        @label ~t"label"X
      end
      """)
    end
  end
end
