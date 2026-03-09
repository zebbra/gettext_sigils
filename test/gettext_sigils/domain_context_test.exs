defmodule GettextSigils.DomainContextTest do
  use ExUnit.Case

  describe "no domain, no context (default)" do
    use GettextSigils, backend: GettextSigils.DummyGettext

    test "uses default domain, no context" do
      assert ~t"example" == "default: example"
    end
  end

  describe "domain option" do
    use GettextSigils,
      backend: GettextSigils.DummyGettext,
      sigils: [default_domain: "errors"]

    test "uses errors domain" do
      assert ~t"example" == "errors: example"
    end
  end

  describe "context option" do
    use GettextSigils,
      backend: GettextSigils.DummyGettext,
      sigils: [default_context: "admin"]

    test "uses admin context in default domain" do
      assert ~t"example" == "default/admin: example"
    end
  end

  describe "domain and context options" do
    use GettextSigils,
      backend: GettextSigils.DummyGettext,
      sigils: [
        default_domain: "errors",
        default_context: "admin"
      ]

    test "uses errors domain with admin context" do
      assert ~t"example" == "errors/admin: example"
    end
  end
end
