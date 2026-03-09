defmodule GettextSigilsTest do
  use ExUnit.Case

  describe "~t sigil with Gettext backend" do
    use GettextSigils, backend: GettextSigils.DummyGettext

    test "simple string returns the translated string" do
      assert ~t"Hello, World!" == "default: Hello, World!"
    end

    test "string with interpolation returns interpolated string" do
      name = "Alice"
      assert ~t"Hello, #{name}!" == "default: Hello, Alice!"
    end

    test "default gettext macros are still available" do
      assert gettext("Hello, World!") == "default: Hello, World!"
    end
  end
end
