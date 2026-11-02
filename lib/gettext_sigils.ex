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
    sigils_opts = Macro.expand_literals(sigils_opts, __CALLER__)

    put_literal_options(sigils_opts, __CALLER__)

    quote do
      use Gettext, unquote(gettext_opts)

      import GettextSigils.Sigil

      @__gettext_sigils__ GettextSigils.Options.validate!(unquote(sigils_opts))
    end
  end

  # The module body expands before it runs, so literal options are also stored now for `~t` outside
  # functions; other options clear what an earlier `use` stored.
  defp put_literal_options(opts, %{module: module}) when not is_nil(module) do
    if Macro.quoted_literal?(opts) do
      {value, _binding} = Code.eval_quoted(opts)
      Module.put_attribute(module, :__gettext_sigils__, GettextSigils.Options.validate!(value))
    else
      Module.delete_attribute(module, :__gettext_sigils__)
    end
  end

  defp put_literal_options(_opts, _env), do: :ok
end
