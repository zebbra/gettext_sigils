defmodule GettextSigils.PluralizationTest do
  use ExUnit.Case, async: true

  alias GettextSigils.Interpolation
  alias GettextSigils.Pluralization

  defmacrop pluralize_parsed!(ast) do
    parsed = Interpolation.parse!(ast)

    quote do
      Pluralization.pluralize!(unquote(parsed))
    end
  end

  test "uses msgid as both singular and plural" do
    count = 3
    assert pluralize_parsed!("#{count} error(s)") == {"%{count} error(s)", "%{count} error(s)", 3, []}
  end

  test "preserves other bindings" do
    count = 2
    name = "validation"

    assert pluralize_parsed!("#{count} #{name} error(s)") ==
             {"%{count} %{name} error(s)", "%{count} %{name} error(s)", 2, [name: "validation"]}
  end

  test "count via explicit key syntax" do
    users = [1, 2, 3]

    assert pluralize_parsed!("#{count = length(users)} user(s)") ==
             {"%{count} user(s)", "%{count} user(s)", 3, []}
  end

  test "raises when no bindings are present" do
    assert_raise ArgumentError, ~r/requires at least one binding/, fn ->
      Pluralization.pluralize!({"no count here", []})
    end
  end

  test "single binding with any name is used as count" do
    assert Pluralization.pluralize!({"%{num} error(s)", [num: 5]}) ==
             {"%{num} error(s)", "%{num} error(s)", 5, []}
  end

  test "multiple bindings require count key" do
    assert_raise ArgumentError, ~r/requires a "count" binding/, fn ->
      Pluralization.pluralize!({"%{num} %{name} error(s)", [num: 5, name: "validation"]})
    end
  end
end
