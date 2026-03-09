defmodule GettextSigils.DomainContextTest do
  use ExUnit.Case

  defmodule NoDomainNoContext do
    use GettextSigils, backend: GettextSigils.TestGettext

    def msg, do: ~t"Not found"
    def dashboard, do: ~t"Dashboard"
  end

  defmodule WithDomain do
    use GettextSigils,
      backend: GettextSigils.TestGettext,
      sigils: [default_domain: "errors"]

    def msg, do: ~t"Not found"
    def msg(path), do: ~t"File #{path} not found"
  end

  defmodule WithContext do
    use GettextSigils,
      backend: GettextSigils.TestGettext,
      sigils: [default_context: "admin"]

    def msg, do: ~t"Dashboard"
    def not_found, do: ~t"Not found"
  end

  defmodule WithDomainAndContext do
    use GettextSigils,
      backend: GettextSigils.TestGettext,
      sigils: [
        default_domain: "errors",
        default_context: "admin"
      ]

    def msg, do: ~t"Not found"
    def msg(path), do: ~t"File #{path} not found"
  end

  describe "no domain, no context (default)" do
    test "uses default domain, no context" do
      assert NoDomainNoContext.msg() == "default: Not found"
      assert NoDomainNoContext.dashboard() == "default: Dashboard"
    end
  end

  describe "domain option" do
    test "uses errors domain" do
      assert WithDomain.msg() == "errors: Not found"
    end

    test "with interpolation" do
      assert WithDomain.msg("/tmp") == "errors: File /tmp not found"
    end
  end

  describe "context option" do
    test "uses admin context in default domain" do
      assert WithContext.msg() == "default+admin: Dashboard"
      assert WithContext.not_found() == "default+admin: Not found"
    end
  end

  describe "domain and context options" do
    test "uses errors domain with admin context" do
      assert WithDomainAndContext.msg() == "errors+admin: Not found"
    end

    test "with interpolation" do
      assert WithDomainAndContext.msg("/tmp") == "errors+admin: File /tmp not found"
    end
  end
end
