---
name: gettext-sigils-localization
description: Use when generating or modifying user-facing strings in an Elixir app that has GettextSigils installed. Triggered when writing code with user-visible text (flash messages, HEEx templates, CLI output, error messages) or when user asks to localize, translate, or add i18n.
---

# Localizing Applications with GettextSigils

## Overview

When GettextSigils is installed, all user-facing strings should use the `~t` sigil to make them translatable. This is a two-phase process:

1. **Write translatable code** (always) — use `~t` instead of fixed strings
2. **Generate translations** (optional, on request) — extract and fill `.po` files

## When to Use

- Writing or modifying code that contains user-facing strings
- User asks to translate, localize, or internationalize the app
- Replacing hardcoded strings with gettext calls

**Not for:** locale routing setup or language switcher components.

## Phase 1: Write Translatable Code

### Explore the Gettext Setup

1. Find where `use GettextSigils` is called — in Phoenix apps check `<app>_web.ex` shared helpers, otherwise search `lib/` modules
2. Note the configured `sigils:` options — especially `:domain`, `:context`, and `:modifiers`

### Replace Strings with `~t`

| Location | Pattern |
|----------|---------|
| HEEx text | `Listing Posts` → `{~t"Listing Posts"}` |
| HEEx attribute | `label="Title"` → `label={~t"Title"}` |
| Elixir string | `"Post saved"` → `~t"Post saved"` |
| Interpolation | `"Hello, #{name}"` → `~t"Hello, #{name}"` |

Use modifiers where configured (e.g. `~t"Not found"e` for the errors domain). Check the `sigils:` options for available modifiers. If unsure, ask the user what modifiers to use.

**Skip:** module names, struct keys, protocol/behaviour identifiers, programmatic strings (config keys, etc.), Logger output, and mix task terminal output. In Phoenix apps also skip: routes, CSS classes, `id`/`name`/`phx-*` attributes. Only translate CLI output if the CLI is the app's main user interface.

### Localizing Dates, Numbers and other Data

When writing code that formats dates, times, numbers, or currencies for display, do NOT use hardcoded format strings (e.g., `Calendar.strftime/2`, `NaiveDateTime.to_string/1`, fixed format patterns). These are locale-sensitive and must be treated like translatable strings.

Instead: check for existing project helpers (`format_date/1`, etc.) or a CLDR backend. If neither exists, **ask the user** how they want locale-sensitive data formatted before proceeding — suggest adding `ex_cldr` and relevant plugins (`ex_cldr_dates_times`, `ex_cldr_numbers`, etc.).

### After Writing Translatable Code

After completing Phase 1, ask the user: "Would you like me to extract and generate translations for any locales?" Do not silently skip Phase 2.

## Phase 2: Generate Translations

Only proceed when the user confirms they want translations generated.

1. Identify configured locales in `config/config.exs` and existing translations in `priv/gettext/`
2. Run `mix gettext.extract --merge --sync` to extract new strings and merge with existing translations
3. **Before filling in translations**, ask the user: "Should I mark the generated translations as fuzzy?" Wait for their answer before proceeding.
4. Fill empty `msgstr` values in `priv/gettext/<locale>/LC_MESSAGES/<domain>.po`, applying the user's fuzzy preference
5. Run `mix gettext.extract --check-up-to-date` to confirm everything is up to date

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Using `gettext()` instead of `~t` | GettextSigils replaces verbose gettext calls — use `~t` consistently |
| Ignoring configured modifiers | Check `sigils: [modifiers: [...]]` in the `use GettextSigils` call and apply where appropriate |
| Translating programmatic strings | Only translate user-visible text, not config keys, identifiers, or log messages |
| Generating `.po` files without being asked | Phase 2 is opt-in — ask the user first, then proceed if confirmed |
| Forgetting `--sync` flag | Without `--sync`, removed strings stay in .po files |
| Using hardcoded date/time/number formats | These are locale-sensitive — ask the user about formatting strategy before using fixed format strings |
| Silently skipping Phase 2 | Always ask the user if they want translations generated after writing translatable code |
| Filling translations without asking about fuzzy | Always ask the user whether to mark generated translations as fuzzy **before** writing `msgstr` values |
