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

    quote do
      use Gettext, unquote(gettext_opts)

      import GettextSigils.Sigil

      @__gettext_sigils__ GettextSigils.Options.validate!(unquote(sigils_opts))
    end
  end
end
