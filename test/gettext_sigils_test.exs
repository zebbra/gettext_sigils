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
    assert GettextTest.with_pluralization(5) == "High 5!"
  end

  describe "pluralization" do
    test "plural message with count" do
      assert ~t"One error||#{count :: 1} errors"N == "frontend: One error"
      assert ~t"One error||#{count :: 3} errors"N == "frontend: 3 errors"
    end

    test "plural with interpolations in both parts" do
      count = 2
      name = "validation"
      assert ~t"One #{name} error||#{count} #{name} errors"N == "frontend: 2 validation errors"
    end

    test "plural with count via explicit key" do
      users = [1, 2, 3]
      assert ~t"One user||#{count :: length(users)} users"N == "frontend: 3 users"
    end

    test "plural with modifiers" do
      count = 5
      assert ~t"One error||#{count} errors"eN == "errors: 5 errors"
    end

    test "separator is treated as literal without N modifier" do
      assert ~t"literal || pipe" == "frontend: literal || pipe"
    end
  end
end

defmodule GettextSigilsTest.CustomSeparatorTest do
  @moduledoc false
  use ExUnit.Case, async: false

  describe "per-use custom separator" do
    use GettextSigils,
      backend: GettextSigilsTest.DummyGettext,
      sigils: [pluralization: [separator: "✂️"]]

    test "splits on custom separator" do
      count = 3
      assert ~t"One error✂️#{count} errors"N == "default: 3 errors"
    end

    test "does not split on default separator when custom is set" do
      assert ~t"literal || pipe" == "default: literal || pipe"
    end
  end
end
