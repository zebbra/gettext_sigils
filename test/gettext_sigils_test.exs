defmodule GettextSigilsTest do
  use ExUnit.Case

  defmodule Example do
    use GettextSigils, backend: GettextSigils.TestGettext

    def hello, do: ~t"Hello, World!"

    def hello(name), do: ~t"Hello, #{name}!"

    def hello_gettext, do: gettext("Hello, World!")
  end

  describe "~t sigil with Gettext backend" do
    test "simple string returns the translated string" do
      assert Example.hello() == "default: Hello, World!"
    end

    test "string with interpolation returns interpolated string" do
      assert Example.hello("Alice") == "default: Hello, Alice!"
    end

    test "default gettext macros are still available" do
      assert Example.hello_gettext() == "default: Hello, World!"
    end
  end
end
