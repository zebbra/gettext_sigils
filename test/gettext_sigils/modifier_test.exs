defmodule GettextSigils.ModifierTest do
  use ExUnit.Case, async: true

  defmodule NoopModifier do
    @moduledoc false
    use GettextSigils.Modifier
  end

  defmodule OverrideModifier do
    @moduledoc false
    use GettextSigils.Modifier

    @impl true
    def domain_context(_input, opts, {_domain, _context}) do
      {:ok, {Keyword.get(opts, :domain, "errors"), "admin"}}
    end

    @impl true
    def preprocess({msgid, bindings}, _opts) do
      {:ok, {"prefix " <> msgid, bindings}}
    end

    @impl true
    def postprocess(string, opts) do
      suffix = Keyword.get(opts, :suffix, "!")
      {:ok, string <> suffix}
    end
  end

  describe "use GettextSigils.Modifier" do
    test "domain_context/3 default returns the accumulator unchanged" do
      assert NoopModifier.domain_context({"hi", []}, [], {"frontend", "main"}) ==
               {:ok, {"frontend", "main"}}

      assert NoopModifier.domain_context({"hi", []}, [], {:default, nil}) ==
               {:ok, {:default, nil}}
    end

    test "init/1 default passes opts through unchanged" do
      assert NoopModifier.init([]) == {:ok, []}
      assert NoopModifier.init(foo: "bar") == {:ok, [foo: "bar"]}
    end

    test "preprocess/2, postprocess/2, pluralize/2 defaults are identity" do
      assert NoopModifier.preprocess({"hi", [a: 1]}, []) == {:ok, {"hi", [a: 1]}}
      assert NoopModifier.postprocess("hi", []) == {:ok, "hi"}
      assert NoopModifier.pluralize({"hi", []}, []) == {:ok, {"hi", []}}
    end

    test "module implements GettextSigils.Modifier behaviour" do
      behaviours = NoopModifier.module_info(:attributes)[:behaviour] || []
      assert GettextSigils.Modifier in behaviours
    end

    test "callbacks are overridable" do
      assert OverrideModifier.domain_context({"hi", []}, [], {:default, nil}) ==
               {:ok, {"errors", "admin"}}

      assert OverrideModifier.domain_context({"hi", []}, [domain: "frontend"], {:default, nil}) ==
               {:ok, {"frontend", "admin"}}

      assert OverrideModifier.preprocess({"hi", [a: 1]}, []) == {:ok, {"prefix hi", [a: 1]}}
      assert OverrideModifier.postprocess("hi", []) == {:ok, "hi!"}
      assert OverrideModifier.postprocess("hi", suffix: "?") == {:ok, "hi?"}
    end
  end
end
