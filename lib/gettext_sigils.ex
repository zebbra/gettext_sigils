defmodule GettextSigils do
  @moduledoc ~S"""
  A `~t` sigil for Gettext translations, with automatic interpolation and per-call modifiers:

      ~t"Hello, #{user.name}!"
      # => gettext("Hello, %{user_name}!", user_name: user.name)

  `use GettextSigils` replaces `use Gettext` in your module and imports the `~t` sigil:

      use GettextSigils,
        backend: MyApp.Gettext,
        sigils: [
          # ...
        ]

  See the [README](readme.html) for an overview, and the
  [Interpolation](interpolation.html), [Modifiers](modifiers.html), and
  [Pluralization](pluralization.html) guides for details.

  ## Options

  - `:sigils` - a keyword list of options for the sigil. See `GettextSigils.Options` for the available options.
  - All other options are passed to `use Gettext` (eg. `:backend`).
  """

  defmacro __using__(opts) do
    {sigils_opts, gettext_opts} = Keyword.pop(opts, :sigils, [])

    expand_early(sigils_opts, __CALLER__)

    quote do
      use Gettext, unquote(gettext_opts)

      import GettextSigils.Sigil

      @__gettext_sigils__ GettextSigils.Options.validate!(unquote(sigils_opts))
    end
  end

  # `~t` may expand before the module body sets `@__gettext_sigils__`, so options that need
  # only the caller's env are also stored now; attributes and variables stay runtime-only.
  defp expand_early(_opts, %{module: nil}), do: :ok

  defp expand_early(opts, env) do
    if early?(opts) do
      {value, _binding} = Code.eval_quoted(opts, [], env)
      Module.put_attribute(env.module, :__gettext_sigils_expanded__, GettextSigils.Options.validate!(value))
    end

    :ok
  end

  defp early?(opts) do
    {_ast, early?} =
      Macro.prewalk(opts, true, fn
        {:@, _, _} = ast, _acc -> {ast, false}
        {name, _, ctx} = ast, acc when is_atom(name) and is_atom(ctx) -> {ast, acc and name == :__MODULE__}
        ast, acc -> {ast, acc}
      end)

    early?
  end
end
