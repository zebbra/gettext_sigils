defmodule GettextSigilsTest.Noop.Upcase do
  @moduledoc false
  use GettextSigils.Modifier

  @impl true
  def postprocess(string, _opts), do: {:ok, String.upcase(string)}
end

defmodule GettextSigilsTest.Noop.Prefix do
  @moduledoc false
  use GettextSigils.Modifier

  @impl true
  def preprocess({msgid, bindings}, _opts), do: {:ok, {"> " <> msgid, bindings}}
end

defmodule GettextSigils.NoopTest do
  use ExUnit.Case, async: true

  use GettextSigils,
    backend: GettextSigilsTest.DummyGettext,
    sigils: [
      modifiers: [
        e: [domain: "errors"],
        m: [context: "admin"],
        u: GettextSigilsTest.Noop.Upcase,
        p: GettextSigilsTest.Noop.Prefix
      ]
    ]

  alias GettextSigilsTest.DummyGettext

  test "returns the msgid without a lookup" do
    assert ~t"Archived"X == "Archived"
  end

  test "takes domain and context from the other modifiers for a later lookup" do
    msgid = ~t"Not found"emX

    assert msgid == "Not found"
    assert Gettext.dpgettext(DummyGettext, "errors", "admin", msgid) == "errors/admin: Not found"
  end

  test "keeps placeholders without evaluating the interpolated expressions" do
    assert ~t"Hello #{name}"X == "Hello %{name}"
  end

  test "returns msgid and msgid_plural together with N" do
    assert ~t"#{count} item(s)"NX == {"%{count} item(s)", "%{count} item(s)"}
  end

  test "still applies other preprocess modifiers on either side" do
    assert ~t"quiet"pX == "> quiet"
    assert ~t"quiet"Xp == "> quiet"
  end

  test "marks a plural message when N comes after X" do
    assert ~t"#{count} item(s)"XN == {"%{count} item(s)", "%{count} item(s)"}
  end

  test "skips postprocessing" do
    assert ~t"quiet"uX == "quiet"
  end
end
