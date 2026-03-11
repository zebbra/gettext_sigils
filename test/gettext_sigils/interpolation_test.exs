defmodule GettextSigils.InterpolationTest do
  use ExUnit.Case

  defmacrop parse(ast) do
    {msgid, bindings} = GettextSigils.Interpolation.parse(ast)
    quote do: {unquote(msgid), unquote(bindings)}
  end

  describe "simple variables" do
    test "simple string without interpolation" do
      assert parse("Hello, World!") == {"Hello, World!", []}
    end

    test "single variable" do
      name = "Alice"
      assert parse("Hello, #{name}!") == {"Hello, %{name}!", [name: "Alice"]}
    end

    test "multiple variables" do
      greeting = "Hello"
      name = "Alice"

      assert parse("#{greeting}, #{name}!") == {
               "%{greeting}, %{name}!",
               [greeting: "Hello", name: "Alice"]
             }
    end

    test "empty string" do
      assert parse("") == {"", []}
    end

    test "only interpolation" do
      x = "val"
      assert parse("#{x}") == {"%{x}", [x: "val"]}
    end
  end

  describe "nested field access" do
    test "single dot access" do
      fruit = %{name: "apple"}
      assert parse("The #{fruit.name}") == {"The %{fruit_name}", [fruit_name: "apple"]}
    end

    test "deep dot access" do
      fruit = %{color: %{name: "red"}}

      assert parse("Color: #{fruit.color.name}") ==
               {"Color: %{fruit_color_name}", [fruit_color_name: "red"]}
    end
  end

  describe "function calls" do
    test "module function call derives key from module and function" do
      assert parse("Status: #{String.upcase("ok")}") ==
               {"Status: %{string_upcase}", [string_upcase: "OK"]}
    end

    test "multiple module function calls derive distinct keys" do
      assert parse("#{String.upcase("a")} and #{String.downcase("B")}") ==
               {"%{string_upcase} and %{string_downcase}", [string_upcase: "A", string_downcase: "b"]}
    end

    def double(x), do: x * 2

    test "local function calls" do
      assert parse("local function: #{double(2)}") ==
               {"local function: %{double}", [double: 4]}
    end

    test "anonymous function calls" do
      double = fn x -> x * 2 end

      assert parse("anonymous function: #{double.(2)}") ==
               {"anonymous function: %{var}", [var: 4]}
    end
  end

  describe "literal values" do
    test "single literal value" do
      assert parse("single: #{1}") ==
               {"single: %{var}", [var: 1]}
    end

    test "multiple literal values" do
      assert parse("one: #{1} two: #{:foo}") ==
               {"one: %{var1} two: %{var2}", [var1: 1, var2: :foo]}
    end
  end

  describe "arithmetic" do
    test "single arithmetic expression" do
      assert parse("sum: #{1 + 2}") == {"sum: %{var}", [var: 3]}
    end
  end

  describe "explicit key syntax" do
    test "explicit key with :: operator" do
      assert parse("Status: #{status :: String.upcase("ok")}") ==
               {"Status: %{status}", [status: "OK"]}
    end
  end

  describe "duplicate keys" do
    test "duplicate keys are suffixed" do
      {foo, bar} = {:foo, :bar}
      assert parse("#{foo} #{foo} #{foo :: bar}") == {"%{foo1} %{foo2} %{foo3}", [foo1: foo, foo2: foo, foo3: bar]}
    end
  end
end
