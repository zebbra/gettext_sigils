defmodule GettextSigils.HEExTest do
  use ExUnit.Case, async: true

  # This test module investigates the compilation order when `~t` sigils
  # are nested inside `~H` HEEx templates.
  #
  # Key finding: The LiveView engine's `analyze` function handles
  # `{:"::", meta, [left, right]}` by only recursing into `left`, not `right`.
  #
  # This means:
  #   - `@name` directly in interpolation (`~t"#{@name}"`) IS transformed
  #     to `assigns.name` by `analyze`, and works correctly.
  #   - `@name` on the right side of `::` (`~t"#{key :: @name}"`) is NOT
  #     transformed, and is instead read as a module attribute (nil).

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

    @tag :skip
    test "explicit key with @assign does NOT work - @assign is treated as module attribute" do
      # Known limitation: LiveView's `analyze` skips the right side of `::`,
      # so `@name` in `#{name :: @name}` is not transformed to `assigns.name`.
      # Workaround: extract the assign to a local variable first.
      assigns = %{name: "World"}

      html =
        rendered_to_string(~H"""
        <h1>{~t"Hello, #{name :: @name}!"}</h1>
        """)

      assert html =~ "Hello, World!"
    end

    @tag :skip
    test "pluralization with explicit key raises because @assign is nil" do
      # Known limitation: same as above — `@todos` in `#{count :: length(@todos)}`
      # is not transformed by the LiveView engine.
      assigns = %{todos: ["a", "b", "c"]}

      html =
        rendered_to_string(~H"""
        <h1>{~t"#{count :: length(@todos)} todos(s)"N}</h1>
        """)

      assert html =~ "3 todos(s)"
    end
  end
end
