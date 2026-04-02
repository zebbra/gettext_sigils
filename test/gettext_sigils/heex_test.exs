defmodule GettextSigils.HEExTest do
  use ExUnit.Case, async: true

  # This test module investigates the compilation order when `~t` sigils
  # are nested inside `~H` HEEx templates.

  use GettextSigils,
    backend: GettextSigilsTest.DummyGettext,
    sigils: [domain: "default"]

  import Phoenix.Component, only: [sigil_H: 2]
  import Phoenix.LiveViewTest

  describe "~t inside ~H" do
    test "implicit key with assign works" do
      assigns = %{name: "World"}

      html =
        rendered_to_string(~H"""
        <h1>{~t"Hello, #{@name}!"}</h1>
        """)

      assert html =~ "Hello, World!"
    end

    test "pluralization with @count works" do
      assigns = %{count: 42}

      html =
        rendered_to_string(~H"""
        <h1>{~t"#{@count} user(s)"N}</h1>
        """)

      assert html =~ "42 user(s)"
    end

    test "explicit key with @assign works" do
      assigns = %{name: "World"}

      html =
        rendered_to_string(~H"""
        <h1>{~t"Hello, #{name = @name}!"}</h1>
        """)

      assert html =~ "Hello, World!"
    end

    test "pluralization with explicit key and @assign works" do
      assigns = %{todos: ["a", "b", "c"]}

      html =
        rendered_to_string(~H"""
        <h1>{~t"#{count = length(@todos)} todo(s)"N}</h1>
        """)

      assert html =~ "3 todo(s)"
    end
  end
end
