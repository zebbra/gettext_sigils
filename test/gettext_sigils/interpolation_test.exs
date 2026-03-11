defmodule GettextSigils.InterpolationTest do
  use ExUnit.Case

  alias GettextSigils.Errors.AmbiguousInterpolationKeys

  defmacrop parse!(ast) do
    {msgid, bindings} = GettextSigils.Interpolation.parse!(ast)
    quote do: {unquote(msgid), unquote(bindings)}
  end

  defmacrop parse_quoted!(ast) do
    quote do: GettextSigils.Interpolation.parse!(unquote(Macro.escape(ast)))
  end

  describe "simple variables" do
    test "simple string without interpolation" do
      assert parse!("Hello, World!") == {"Hello, World!", []}
    end

    test "single variable" do
      name = "Alice"
      assert parse!("Hello, #{name}!") == {"Hello, %{name}!", [name: "Alice"]}
    end

    test "multiple variables" do
      greeting = "Hello"
      name = "Alice"

      assert parse!("#{greeting}, #{name}!") == {
               "%{greeting}, %{name}!",
               [greeting: "Hello", name: "Alice"]
             }
    end

    test "empty string" do
      assert parse!("") == {"", []}
    end

    test "only interpolation" do
      x = "val"
      assert parse!("#{x}") == {"%{x}", [x: "val"]}
    end
  end

  describe "nested field access" do
    test "single dot access" do
      fruit = %{name: "apple"}
      assert parse!("The #{fruit.name}") == {"The %{fruit_name}", [fruit_name: "apple"]}
    end

    test "deep dot access" do
      fruit = %{color: %{name: "red"}}

      assert parse!("Color: #{fruit.color.name}") ==
               {"Color: %{fruit_color_name}", [fruit_color_name: "red"]}
    end
  end

  describe "function calls" do
    test "module function call derives key from module and function" do
      assert parse!("Status: #{String.upcase("ok")}") ==
               {"Status: %{string_upcase}", [string_upcase: "OK"]}
    end

    test "multiple module function calls derive distinct keys" do
      assert parse!("#{String.upcase("a")} and #{String.downcase("B")}") ==
               {"%{string_upcase} and %{string_downcase}", [string_upcase: "A", string_downcase: "b"]}
    end

    def double(x), do: x * 2

    test "local function calls" do
      assert parse!("local function: #{double(2)}") ==
               {"local function: %{double}", [double: 4]}
    end

    test "anonymous function calls" do
      double = fn x -> x * 2 end

      assert parse!("anonymous function: #{double.(2)}") ==
               {"anonymous function: %{var}", [var: 4]}
    end
  end

  describe "literal values" do
    test "single literal value" do
      assert parse!("single: #{1}") ==
               {"single: %{var}", [var: 1]}
    end

    test "multiple literal values raises due to ambiguous keys" do
      assert_raise AmbiguousInterpolationKeys, ~r/ambiguous.*interpolation keys/i, fn ->
        parse_quoted!("one: #{1} two: #{:foo}")
      end
    end
  end

  describe "arithmetic" do
    test "single arithmetic expression" do
      assert parse!("sum: #{1 + 2}") == {"sum: %{var}", [var: 3]}
    end
  end

  describe "explicit key syntax" do
    test "explicit key with :: operator" do
      assert parse!("Status: #{status :: String.upcase("ok")}") ==
               {"Status: %{status}", [status: "OK"]}
    end
  end

  describe "ambiguous keys" do
    test "same key with same variable is allowed and deduplicated in bindings" do
      foo = "hello"
      assert parse!("#{foo} #{foo}") == {"%{foo} %{foo}", [foo: "hello"]}
    end

    test "same explicit key with same value is allowed" do
      assert parse!("#{x :: :foo} #{x :: :foo}") == {"%{x} %{x}", [x: :foo]}
    end

    test "same key with different values raises" do
      assert_raise AmbiguousInterpolationKeys, ~r/ambiguous.*interpolation keys/i, fn ->
        parse_quoted!("#{foo :: :a} #{foo :: :b}")
      end
    end
  end
end
