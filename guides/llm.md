# LLM Agents

GettextSigils ships with a `usage-rules.md` and optional skills that LLM agents (Claude Code, Cursor, Codex, etc.) can use to generate translatable code. The [`usage_rules`](https://hexdocs.pm/usage_rules) library distributes these to your agent automatically.

## Setup

[Install `usage_rules`](https://hexdocs.pm/usage_rules/readme.html), then add GettextSigils to your `usage_rules` config in `mix.exs`:

```elixir
defp usage_rules do
  [
    file: "AGENTS.md",
    usage_rules: [
      :gettext_sigils
    ]
  ]
end
```

Run `mix usage_rules.sync` to generate or update your `AGENTS.md` file. This inlines the GettextSigils usage rules so your agent knows to use `~t` instead of fixed strings.

## Skills

GettextSigils ships optional skills that agents can discover and use. To install them, add a `skills` section:

```elixir
defp usage_rules do
  [
    file: "AGENTS.md",
    usage_rules: [
      :gettext_sigils
    ],
    skills: [
      package_skills: [:gettext_sigils]
    ]
  ]
end
```

Run `mix usage_rules.sync` again. This copies skills into your configured skills directory (`.claude/skills/` by default), where your agent can discover and use them.

### `gettext-sigils-localization`

Teaches agents how to systematically localize an application with `~t`. Covers replacing user-facing strings, using modifiers, and optionally extracting and translating `.po` files. ([source](https://github.com/zebbra/gettext_sigils/blob/main/usage-rules/skills/gettext-sigils-localization/SKILL.md))
