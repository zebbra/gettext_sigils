defmodule GettextSigilsTest do
  @moduledoc false
  use ExUnit.Case, async: true

  use GettextSigils,
    backend: GettextSigilsTest.DummyGettext,
    sigils: [
      domain: "frontend",
      modifiers: [
        e: [domain: "errors"],
        m: [context: "MyModule"]
      ]
    ]

  alias GettextSigilsTest.GettextTest

  describe "using the module" do
    test "modifiers are applied" do
      assert ~t"without modifiers" == "frontend: without modifiers"
      assert ~t"with modifiers"em == "errors/MyModule: with modifiers"
      assert ~t[with #{"interpolation"}]em == "errors/MyModule: with interpolation"
    end

    test "imports Gettext marcros" do
      assert gettext("Hello, Gettext!") == "default: Hello, Gettext!"
    end
  end

  test "using the module with invalid options" do
    assert_raise ArgumentError, ~r/unknown options \[:dummy\]/, fn ->
      defmodule Example do
        @moduledoc false
        use GettextSigils,
          backend: GettextSigilsTest.DummyGettext,
          sigils: [dummy: :foo]
      end
    end
  end

  test "translations use Gettext backend" do
    assert GettextTest.without_modifiers() == "translated without modifiers"
    assert GettextTest.with_modifiers() == "translated with modifiers"
    assert GettextTest.with_interpolation("interpolation") == "translated with interpolation"
  end
end
