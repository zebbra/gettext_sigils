defmodule Mix.Tasks.GettextSigils.InstallTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  defp assert_gettext_sigils_patch(igniter, file, backend \\ MyApp.Gettext) do
    igniter
    |> assert_has_patch(file, """
    - |  use Gettext, backend: #{inspect(backend)}
    """)
    |> assert_has_patch(file, """
    + |  use GettextSigils,
    + |    backend: #{inspect(backend)},
    + |    sigils: [
    + |      # set default domain and context:
    + |      # domain: "example",
    + |      # context: inspect(__MODULE__),
    + |      #
    + |      # modifiers to override domain and/or context per translation:
    + |      modifiers: [
    + |        # e: [domain: "errors"],
    + |        # m: [context: inspect(__MODULE__)]
    + |        #
    + |        # if you use a context by default, but want to opt-out using it:
    + |        # g: [context: nil]
    + |      ]
    + |    ]
    """)
  end

  test "replaces `use Gettext, backend: ...` with `use GettextSigils`" do
    [
      files: %{
        "lib/my_app/live/page_live.ex" => """
        defmodule MyApp.PageLive do
          @moduledoc false
          use Gettext, backend: MyApp.Gettext
        end
        """
      }
    ]
    |> test_project()
    |> Igniter.compose_task("gettext_sigils.install", [])
    |> assert_gettext_sigils_patch("lib/my_app/live/page_live.ex")
  end

  test "does not modify modules without `use Gettext`" do
    [
      files: %{
        "lib/my_app/other.ex" => """
        defmodule MyApp.Other do
          @moduledoc false
          use GenServer
        end
        """
      }
    ]
    |> test_project()
    |> Igniter.compose_task("gettext_sigils.install", [])
    |> assert_unchanged()
  end

  test "does not modify `use Gettext` without backend option" do
    [
      files: %{
        "lib/my_app/gettext.ex" => """
        defmodule MyApp.Gettext do
          @moduledoc false
          use Gettext, otp_app: :my_app
        end
        """
      }
    ]
    |> test_project()
    |> Igniter.compose_task("gettext_sigils.install", [])
    |> assert_unchanged()
  end

  test "handles multiple modules" do
    [
      files: %{
        "lib/my_app/live/page_live.ex" => """
        defmodule MyApp.PageLive do
          @moduledoc false
          use Gettext, backend: MyApp.Gettext
        end
        """,
        "lib/my_app/live/other_live.ex" => """
        defmodule MyApp.OtherLive do
          @moduledoc false
          use Gettext, backend: MyApp.Gettext
        end
        """
      }
    ]
    |> test_project()
    |> Igniter.compose_task("gettext_sigils.install", [])
    |> assert_gettext_sigils_patch("lib/my_app/live/page_live.ex")
    |> assert_gettext_sigils_patch("lib/my_app/live/other_live.ex")
  end

  test "replaces `use Gettext` inside quote blocks in a Phoenix project" do
    phx_test_project()
    |> Igniter.compose_task("gettext_sigils.install", [])
    |> assert_gettext_sigils_patch("lib/test_web.ex", TestWeb.Gettext)
    |> assert_gettext_sigils_patch("lib/test_web/components/core_components.ex", TestWeb.Gettext)
  end
end
