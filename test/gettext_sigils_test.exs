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

  import ExUnit.CaptureIO

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
    assert_raise NimbleOptions.ValidationError, ~r/unknown options \[:dummy\]/, fn ->
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
    assert GettextTest.with_pluralization(1) == "One item"
    assert GettextTest.with_pluralization(5) == "5 items"
  end

  describe "pluralization" do
    test "plural message with count" do
      assert ~t"#{count :: 1} error(s)"N == "frontend: 1 error(s)"
      assert ~t"#{count :: 3} error(s)"N == "frontend: 3 error(s)"
    end

    test "plural with additional bindings" do
      count = 2
      name = "validation"
      assert ~t"#{count} #{name} error(s)"N == "frontend: 2 validation error(s)"
    end

    test "plural with count via explicit key" do
      users = [1, 2, 3]
      assert ~t"#{count :: length(users)} user(s)"N == "frontend: 3 user(s)"
    end

    test "plural with modifiers" do
      count = 5
      assert ~t"#{count} error(s)"eN == "errors: 5 error(s)"
    end

    test "separator is treated as literal without N modifier" do
      assert ~t"literal || pipe" == "frontend: literal || pipe"
    end

    test "deprecated separator emits warning at runtime" do
      warning =
        capture_io(:stderr, fn ->
          assert GettextSigils.Pluralization.split!(
                   {"One error||%{count} errors", [count: 3]},
                   "||"
                 ) == {"One error", "%{count} errors", 3, []}
        end)

      assert warning =~ "is deprecated, use a shared message instead"
    end
  end
end
