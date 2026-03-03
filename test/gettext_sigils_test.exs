defmodule GettextSigilsTest do
  use ExUnit.Case
  doctest GettextSigils

  test "greets the world" do
    assert GettextSigils.hello() == :world
  end
end
