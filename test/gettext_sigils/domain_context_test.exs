defmodule GettextSigils.DomainContextTest do
  use ExUnit.Case, async: true

  describe "no domain, no context (default)" do
    use GettextSigils, backend: GettextSigilsTest.DummyGettext

    test "uses default domain, no context" do
      assert ~t"example" == "default: example"
    end

    test "plural uses default domain" do
      count = 2
      assert ~t"#{count} item(s)"N == "default: 2 item(s)"
    end
  end

  describe "domain option" do
    use GettextSigils,
      backend: GettextSigilsTest.DummyGettext,
      sigils: [domain: "errors"]

    test "uses errors domain" do
      assert ~t"example" == "errors: example"
    end
  end

  describe "context option" do
    use GettextSigils,
      backend: GettextSigilsTest.DummyGettext,
      sigils: [context: "admin"]

    test "uses admin context in default domain" do
      assert ~t"example" == "default/admin: example"
    end
  end

  describe "domain and context options" do
    use GettextSigils,
      backend: GettextSigilsTest.DummyGettext,
      sigils: [
        domain: "errors",
        context: "admin"
      ]

    test "uses errors domain with admin context" do
      assert ~t"example" == "errors/admin: example"
    end
  end
end
