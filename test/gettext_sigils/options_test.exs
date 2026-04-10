defmodule GettextSigils.OptionsTest do
  use ExUnit.Case, async: true

  alias GettextSigils.Modifiers.KeywordModifier
  alias GettextSigils.Options

  defmodule DummyMod do
    @moduledoc false
    use GettextSigils.Modifier
  end

  defmodule InitErrorMod do
    @moduledoc false
    use GettextSigils.Modifier

    @impl true
    def init(opts) do
      case Keyword.fetch(opts, :allowed) do
        {:ok, true} -> {:ok, opts}
        _ -> {:error, "opts must contain allowed: true"}
      end
    end
  end

  defmodule InitTransformMod do
    @moduledoc false
    use GettextSigils.Modifier

    @impl true
    def init(opts) do
      # Set a default and record that init ran
      {:ok, Keyword.put_new(opts, :initialized, true)}
    end
  end

  describe "validate!/1 top-level options" do
    test "accepts valid options and normalizes the static modifier shape into a char-keyed map" do
      opts =
        Options.validate!(
          domain: "errors",
          context: "admin",
          modifiers: [e: [domain: "errors"]]
        )

      assert opts[:modifiers] == %{?e => {KeywordModifier, [domain: "errors"]}}
    end

    test "accepts empty options" do
      Options.validate!([])
    end

    test "raises on unknown top-level option" do
      assert_raise NimbleOptions.ValidationError, ~r/unknown options.*doman/, fn ->
        Options.validate!(doman: "errors")
      end
    end

    test "accepts nil context" do
      Options.validate!(context: nil)
    end

    test "accepts :default domain" do
      Options.validate!(domain: :default)
    end

    test "warns and rewrites `domain: nil` to `domain: :default` (soft deprecation)" do
      stderr =
        ExUnit.CaptureIO.capture_io(:stderr, fn ->
          opts = Options.validate!(domain: nil)
          send(self(), {:validated, opts})
        end)

      assert stderr =~ "setting :domain to nil is deprecated, use :default instead"

      assert_received {:validated, opts}
      assert Keyword.fetch(opts, :domain) == {:ok, :default}
    end

    test "raises when modifiers is not a keyword list" do
      assert_raise NimbleOptions.ValidationError, ~r/:modifiers option/, fn ->
        Options.validate!(modifiers: "bad")
      end
    end
  end

  describe "validate!/1 modifier options" do
    test "raises on non-lowercase modifier key" do
      assert_raise NimbleOptions.ValidationError, ~r/must be lowercase letters/, fn ->
        Options.validate!(modifiers: [A: [domain: "errors"]])
      end
    end

    test "raises on a modifier value that is neither a keyword list, module, nor tuple" do
      assert_raise NimbleOptions.ValidationError,
                   ~r/expected a keyword list, module, or \{module, keyword\} tuple/,
                   fn ->
                     Options.validate!(modifiers: [e: "errors"])
                   end
    end

    test "raises on unknown modifier options" do
      assert_raise NimbleOptions.ValidationError, ~r/unknown options.*domainn/, fn ->
        Options.validate!(modifiers: [e: [domainn: "errors"]])
      end
    end

    test "normalizes static keyword-list modifier to %{char => {KeywordModifier, opts}}" do
      opts = Options.validate!(modifiers: [e: [domain: "errors"]])
      assert opts[:modifiers] == %{?e => {KeywordModifier, [domain: "errors"]}}
    end

    test "accepts bare module atom modifier and normalizes to %{char => {module, []}}" do
      opts = Options.validate!(modifiers: [u: DummyMod])
      assert opts[:modifiers] == %{?u => {DummyMod, []}}
    end

    test "accepts {module, opts} tuple modifier" do
      opts = Options.validate!(modifiers: [s: {DummyMod, intensity: 3}])
      assert opts[:modifiers] == %{?s => {DummyMod, [intensity: 3]}}
    end

    test "raises on {module, not_a_keyword}" do
      assert_raise NimbleOptions.ValidationError, ~r/must be a keyword list/, fn ->
        Options.validate!(modifiers: [s: {DummyMod, "bad"}])
      end
    end

    test "raises when module does not implement GettextSigils.Modifier" do
      assert_raise NimbleOptions.ValidationError,
                   ~r/does not implement GettextSigils.Modifier/,
                   fn ->
                     Options.validate!(modifiers: [u: Enum])
                   end
    end

    test "raises ArgumentError when module atom does not exist" do
      # Code.ensure_compiled!/1 raises directly with a clear message pointing
      # at the missing module. We let the raise propagate instead of wrapping
      # it in a NimbleOptions validation error so the user sees the exact
      # module name and reason from the compiler.
      assert_raise ArgumentError,
                   ~r/could not load module NotARealModule/,
                   fn ->
                     Options.validate!(modifiers: [u: NotARealModule])
                   end
    end

    test "module-based modifier's init/1 transforms opts, result stored in the map" do
      opts = Options.validate!(modifiers: [t: {InitTransformMod, foo: "bar"}])

      assert opts[:modifiers] == %{
               ?t => {InitTransformMod, [initialized: true, foo: "bar"]}
             }
    end

    test "module-based modifier's init/1 {:error, reason} becomes a validation error" do
      assert_raise NimbleOptions.ValidationError,
                   ~r/modifier :e: opts must contain allowed: true/,
                   fn ->
                     Options.validate!(modifiers: [e: {InitErrorMod, foo: "bar"}])
                   end
    end

    test "module-based modifier's init/1 {:ok, _} passes through unchanged opts" do
      opts = Options.validate!(modifiers: [e: {InitErrorMod, allowed: true}])

      assert opts[:modifiers] == %{?e => {InitErrorMod, [allowed: true]}}
    end
  end
end
