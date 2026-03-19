defmodule Mix.Tasks.GettextSigils.Install.Docs do
  @moduledoc false

  @spec short_doc() :: String.t()
  def short_doc do
    "Replaces `use Gettext` with `use GettextSigils` in modules that use a Gettext backend"
  end

  @spec example() :: String.t()
  def example do
    "mix gettext_sigils.install"
  end

  @spec long_doc() :: String.t()
  def long_doc do
    """
    #{short_doc()}

    Finds all modules containing `use Gettext, backend: MyApp.Gettext` and replaces
    them with `use GettextSigils, backend: MyApp.Gettext`

    ## Example

    ```sh
    #{example()}
    ```
    """
  end
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.GettextSigils.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()}"

    @moduledoc __MODULE__.Docs.long_doc()

    use Igniter.Mix.Task

    alias Igniter.Code.Common
    alias Igniter.Code.Function
    alias Igniter.Code.Keyword, as: CodeKeyword

    @sigils_value Sourceror.parse_string!("""
                  [
                    # set default domain and context:
                    # domain: "example",
                    # context: inspect(__MODULE__),
                    #
                    # modifiers to override domain and/or context per translation:
                    modifiers: [
                      # e: [domain: "errors"],
                      # m: [context: inspect(__MODULE__)]
                      #
                      # if you use a context by default, but want to opt-out using it:
                      # g: [context: nil]
                    ]
                  ]
                  """)

    @impl Igniter.Mix.Task
    def supports_umbrella?, do: true

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :gettext_sigils,
        adds_deps: [],
        installs: [],
        example: __MODULE__.Docs.example(),
        only: nil,
        positional: [],
        composes: [],
        schema: [],
        defaults: [],
        aliases: [],
        required: []
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      {igniter, modules} = find_modules_with_use_gettext_backend(igniter)

      Enum.reduce(modules, igniter, fn module, igniter ->
        replace_all_use_gettext(igniter, module)
      end)
    end

    defp find_modules_with_use_gettext_backend(igniter) do
      Igniter.Project.Module.find_all_matching_modules(igniter, fn _module, zipper ->
        match?({:ok, _}, Common.move_to(zipper, &use_gettext_with_backend?/1))
      end)
    end

    defp replace_all_use_gettext(igniter, module) do
      Igniter.Project.Module.find_and_update_module!(igniter, module, fn zipper ->
        Common.update_all_matches(zipper, &use_gettext_with_backend?/1, &replace_use_node/1)
      end)
    end

    defp replace_use_node(zipper) do
      with {:ok, zipper} <- replace_module_name(zipper) do
        add_sigils_option(zipper)
      end
    end

    defp use_gettext_with_backend?(zipper) do
      Function.function_call?(zipper, :use, [2]) &&
        Function.argument_matches_predicate?(zipper, 0, &Common.nodes_equal?(&1, Gettext)) &&
        Function.argument_matches_predicate?(zipper, 1, fn opts_zipper ->
          match?({:ok, _}, CodeKeyword.get_key(opts_zipper, :backend))
        end)
    end

    defp replace_module_name(zipper) do
      Function.update_nth_argument(zipper, 0, fn zipper ->
        {:ok, Common.replace_code(zipper, GettextSigils)}
      end)
    end

    defp add_sigils_option(zipper) do
      Function.update_nth_argument(zipper, 1, fn zipper ->
        CodeKeyword.set_keyword_key(zipper, :sigils, @sigils_value)
      end)
    end
  end
else
  IO.puts("TETEST")

  defmodule Mix.Tasks.GettextSigils.Install do
    @shortdoc "#{__MODULE__.Docs.short_doc()} | Install `igniter` to use"

    @moduledoc __MODULE__.Docs.long_doc()

    use Mix.Task

    @impl Mix.Task
    def run(_argv) do
      Mix.shell().error("""
      The task 'gettext_sigils.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
