defmodule GettextSigils.ModifiersTest do
  use ExUnit.Case, async: true

  alias GettextSigils.Modifiers
  alias GettextSigils.Modifiers.KeywordModifier
  alias GettextSigils.Modifiers.PluralModifier

  defmodule DomainOverrideMod do
    @moduledoc false
    use GettextSigils.Modifier

    @impl true
    def domain_context(_input, opts, {_domain, context}) do
      {:ok, {Keyword.get(opts, :domain, "custom"), context}}
    end
  end

  defmodule ContextOverrideMod do
    @moduledoc false
    use GettextSigils.Modifier

    @impl true
    def domain_context(_input, _opts, {domain, _context}), do: {:ok, {domain, "custom_ctx"}}
  end

  defmodule NoopDomainContextMod do
    @moduledoc false
    use GettextSigils.Modifier

    # default domain_context/3 returns the accumulator unchanged
  end

  defmodule PreprocessMod do
    @moduledoc false
    use GettextSigils.Modifier

    @impl true
    def preprocess({msgid, bindings}, opts) do
      prefix = Keyword.get(opts, :prefix, ">> ")
      {:ok, {prefix <> msgid, bindings}}
    end
  end

  defmodule PostprocessMod do
    @moduledoc false
    use GettextSigils.Modifier

    @impl true
    def postprocess(string, opts), do: {:ok, string <> Keyword.get(opts, :suffix, "!")}
  end

  defmodule ErrorMod do
    @moduledoc false
    use GettextSigils.Modifier

    @impl true
    def domain_context(_input, opts, _acc), do: {:error, Keyword.fetch!(opts, :reason)}

    @impl true
    def preprocess(_input, opts), do: {:error, Keyword.fetch!(opts, :reason)}

    @impl true
    def postprocess(_string, opts), do: {:error, Keyword.fetch!(opts, :reason)}
  end

  describe "lookup_modifiers!/2" do
    test "returns an empty chain when the sigil has no modifier letters" do
      assert Modifiers.lookup_modifiers!(~c"", %{}) == []
    end

    test "looks each modifier letter up in the user-provided map" do
      modifier_map = %{
        ?a => {KeywordModifier, [domain: "A"]},
        ?b => {PreprocessMod, [prefix: "B: "]}
      }

      assert Modifiers.lookup_modifiers!(~c"ab", modifier_map) == [
               {KeywordModifier, [domain: "A"]},
               {PreprocessMod, [prefix: "B: "]}
             ]
    end

    test "preserves sigil order regardless of map ordering" do
      modifier_map = %{
        ?a => {KeywordModifier, [domain: "A"]},
        ?b => {PreprocessMod, [prefix: "B: "]}
      }

      assert Modifiers.lookup_modifiers!(~c"ba", modifier_map) == [
               {PreprocessMod, [prefix: "B: "]},
               {KeywordModifier, [domain: "A"]}
             ]
    end

    test "raises ArgumentError on unknown modifier" do
      assert_raise ArgumentError, ~r/unknown sigil modifier :x/, fn ->
        Modifiers.lookup_modifiers!(~c"x", %{})
      end
    end

    test "the N modifier resolves to PluralModifier from the built-in default map" do
      assert Modifiers.lookup_modifiers!(~c"N", %{}) == [{PluralModifier, []}]
    end

    test "N can be combined with user modifiers in any position" do
      modifier_map = %{?a => {KeywordModifier, [domain: "A"]}}

      assert Modifiers.lookup_modifiers!(~c"aN", modifier_map) == [
               {KeywordModifier, [domain: "A"]},
               {PluralModifier, []}
             ]

      assert Modifiers.lookup_modifiers!(~c"Na", modifier_map) == [
               {PluralModifier, []},
               {KeywordModifier, [domain: "A"]}
             ]
    end
  end

  describe "resolve_domain_context!/3" do
    test "returns the defaults when the chain is empty" do
      assert Modifiers.resolve_domain_context!([], {"hi", []}, {"frontend", "main"}) ==
               {"frontend", "main"}
    end

    test "KeywordModifier with :domain key overrides the default" do
      resolved = [{KeywordModifier, [domain: "errors"]}]

      assert Modifiers.resolve_domain_context!(resolved, {"hi", []}, {"frontend", nil}) ==
               {"errors", nil}
    end

    test "KeywordModifier with :context key overrides the default" do
      resolved = [{KeywordModifier, [context: "admin"]}]

      assert Modifiers.resolve_domain_context!(resolved, {"hi", []}, {"frontend", "main"}) ==
               {"frontend", "admin"}
    end

    test "KeywordModifier with both keys overrides both" do
      resolved = [{KeywordModifier, [domain: "errors", context: "admin"]}]

      assert Modifiers.resolve_domain_context!(resolved, {"hi", []}, {"frontend", "main"}) ==
               {"errors", "admin"}
    end

    test "KeywordModifier with :domain :default resets the domain to the backend default" do
      resolved = [{KeywordModifier, [domain: :default]}]

      assert Modifiers.resolve_domain_context!(resolved, {"hi", []}, {"frontend", "main"}) ==
               {:default, "main"}
    end

    test "KeywordModifier with :context nil clears the context" do
      # Regression: previously `[context: nil]` was a silent no-op because
      # `Keyword.get(opts, :context)` returned nil for both "absent" and
      # "present with nil", and the resolver treated nil as "don't touch".
      resolved = [{KeywordModifier, [context: nil]}]

      assert Modifiers.resolve_domain_context!(resolved, {"hi", []}, {"frontend", "main"}) ==
               {"frontend", nil}
    end

    test "KeywordModifier without :domain leaves the domain in place" do
      resolved = [{KeywordModifier, [context: "admin"]}]

      assert Modifiers.resolve_domain_context!(resolved, {"hi", []}, {"frontend", "main"}) ==
               {"frontend", "admin"}
    end

    test "KeywordModifier without :context leaves the context in place" do
      resolved = [{KeywordModifier, [domain: "errors"]}]

      assert Modifiers.resolve_domain_context!(resolved, {"hi", []}, {"frontend", "main"}) ==
               {"errors", "main"}
    end

    test "modifier returning the accumulator unchanged is a no-op" do
      resolved = [{NoopDomainContextMod, []}]

      assert Modifiers.resolve_domain_context!(resolved, {"hi", []}, {"keep-me", "also-keep"}) ==
               {"keep-me", "also-keep"}
    end

    test "modifier overrides the accumulator (last-wins)" do
      resolved = [
        {KeywordModifier, [domain: "static-domain"]},
        {DomainOverrideMod, [domain: "custom-domain"]}
      ]

      assert {"custom-domain", _} =
               Modifiers.resolve_domain_context!(resolved, {"hi", []}, {:default, nil})

      assert {"static-domain", _} =
               Modifiers.resolve_domain_context!(Enum.reverse(resolved), {"hi", []}, {:default, nil})
    end

    test "context-only override modifier leaves domain untouched" do
      resolved = [{ContextOverrideMod, []}]

      assert Modifiers.resolve_domain_context!(resolved, {"hi", []}, {"frontend", nil}) ==
               {"frontend", "custom_ctx"}
    end

    test "raises ArgumentError when a callback returns {:error, reason}" do
      resolved = [{ErrorMod, [reason: "boom"]}]

      assert_raise ArgumentError, "boom", fn ->
        Modifiers.resolve_domain_context!(resolved, {"hi", []}, {:default, nil})
      end
    end
  end

  describe "KeywordModifier.init/1" do
    test "passes valid opts through unchanged" do
      assert KeywordModifier.init(domain: "errors", context: "admin") ==
               {:ok, [domain: "errors", context: "admin"]}
    end

    test "accepts :domain :default" do
      assert KeywordModifier.init(domain: :default) == {:ok, [domain: :default]}
    end

    test "warns and rewrites :domain nil to :default (soft deprecation)" do
      stderr =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          assert {:ok, opts} = KeywordModifier.init(domain: nil)
          send(self(), {:validated, opts})
        end)

      assert stderr =~ "setting :domain to nil is deprecated, use :default instead"

      assert_received {:validated, opts}
      assert Keyword.fetch(opts, :domain) == {:ok, :default}
    end

    test "rejects :domain with non-string, non-:default value" do
      assert {:error, _} = KeywordModifier.init(domain: 42)
      assert {:error, _} = KeywordModifier.init(domain: :foo)
    end

    test "leaves :context nil alone (context can legitimately be nil)" do
      assert {:ok, opts} = KeywordModifier.init(context: nil)
      assert Keyword.fetch(opts, :context) == {:ok, nil}
    end

    test "returns {:error, %NimbleOptions.ValidationError{}} for unknown keys" do
      assert {:error, %NimbleOptions.ValidationError{} = error} =
               KeywordModifier.init(domianN: "errors")

      assert Exception.message(error) =~ "unknown options"
    end
  end

  describe "preprocess!/2" do
    test "returns the parsed tuple unchanged when the chain is empty" do
      assert Modifiers.preprocess!([], {"hi", []}) == {"hi", []}
    end

    test "returns unchanged when only KeywordModifier is in the chain" do
      assert Modifiers.preprocess!([{KeywordModifier, [domain: "errors"]}], {"hi", []}) ==
               {"hi", []}
    end

    test "rewrites the msgid via a single preprocess modifier" do
      resolved = [{PreprocessMod, [prefix: "[!] "]}]

      assert Modifiers.preprocess!(resolved, {"hi", []}) == {"[!] hi", []}
    end

    test "chains preprocess left-to-right across multiple modifiers" do
      resolved = [
        {PreprocessMod, [prefix: "A: "]},
        {PreprocessMod, [prefix: "B: "]}
      ]

      assert Modifiers.preprocess!(resolved, {"hi", []}) == {"B: A: hi", []}
      assert Modifiers.preprocess!(Enum.reverse(resolved), {"hi", []}) == {"A: B: hi", []}
    end

    test "raises ArgumentError when a callback returns {:error, reason}" do
      resolved = [{ErrorMod, [reason: "boom"]}]

      assert_raise ArgumentError, "boom", fn ->
        Modifiers.preprocess!(resolved, {"hi", []})
      end
    end
  end

  describe "postprocess!/2" do
    test "returns the string unchanged when the chain is empty" do
      assert Modifiers.postprocess!([], "hi") == "hi"
    end

    test "no-op modifiers (KeywordModifier defaults) leave the string alone" do
      resolved = [{KeywordModifier, [domain: "errors"]}]

      assert Modifiers.postprocess!(resolved, "hi") == "hi"
    end

    test "applies postprocess callbacks left-to-right across multiple modifiers" do
      resolved = [
        {PostprocessMod, [suffix: "!"]},
        {PostprocessMod, [suffix: "?"]}
      ]

      assert Modifiers.postprocess!(resolved, "hi") == "hi!?"
      assert Modifiers.postprocess!(Enum.reverse(resolved), "hi") == "hi?!"
    end

    test "raises ArgumentError when a callback returns {:error, reason}" do
      resolved = [{ErrorMod, [reason: "boom"]}]

      assert_raise ArgumentError, "boom", fn ->
        Modifiers.postprocess!(resolved, "hi")
      end
    end
  end

  describe "pluralize!/2" do
    test "returns the original parsed tuple when the chain has no PluralModifier" do
      resolved = [{KeywordModifier, []}, {PreprocessMod, [prefix: ">> "]}]

      assert Modifiers.pluralize!(resolved, {"hi", []}) == {"hi", []}
    end

    test "returns the plural tuple when PluralModifier is in the chain and count is present" do
      resolved = [{KeywordModifier, []}, {PluralModifier, []}]

      assert Modifiers.pluralize!(resolved, {"%{count} item(s)", [count: 3]}) ==
               {"%{count} item(s)", "%{count} item(s)", 3, []}
    end

    test "raises ArgumentError when PluralModifier is in the chain but count is missing" do
      resolved = [{PluralModifier, []}]

      assert_raise ArgumentError, ~r/requires a "count" binding/, fn ->
        Modifiers.pluralize!(resolved, {"no count", []})
      end
    end
  end
end
