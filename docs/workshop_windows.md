# Upgrading to Fusion Workshop

## Prerequisites

Before the workshop, make sure you have the following installed:

- [VS Code](https://code.visualstudio.com/) (or another editor of your choice)
- [Git](https://git-scm.com/)
- [dbt extension for VS Code](https://marketplace.visualstudio.com/items?itemName=dbtLabsInc.dbt&ssr=false#overview) (or if using Cursor use the [Open VSX registry](https://open-vsx.org/extension/dbtLabsInc/dbt))
- [uv](https://docs.astral.sh/uv/) — install with:
  ```powershell
  powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
  ```

## 1. Clone the starter repo

## 2. Set up a Snowflake demo account

1. Go to [signup.snowflake.com](https://signup.snowflake.com/) (no credit card required, access for 30 days, with $400 of credit)
2. Enter your name, email, company, and job title
3. Check your email for "Activate your Snowflake account" and click the activation link
4. Set your username and password
5. Skip the data load prompt — we'll use dbt seeds instead
6. In the bottom-left profile menu, click **Connect a tool to Snowflake** and note your:
   - Account identifier
   - Username
   - Password

## 3. Configure your connection

Open `profiles.yml` and fill in the values from your Snowflake account:

- `account` — your account identifier
- `user` — your username
- `password` — your password
- `schema` — use your name or a unique identifier (e.g., `dbt_yourname`)

## 4. Install dbt Core and load seed data

```powershell
uv venv --python 3.12 .venv
.venv\Scripts\activate
uv pip install dbt-snowflake==1.11.2
dbt --version
dbt deps
dbt build --vars "load_source_data: true"
Copy-Item -Recurse .\target artifacts
```

> **Note**: Use double quotes around the `--vars` value in PowerShell. Single quotes behave differently than in bash.

## 5. Install the Fusion CLI

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://public.cdn.getdbt.com/fs/install/install.ps1 | iex"
dbtf system update --version 2.0.0-preview.126
```

If the PowerShell installer isn't available, you can download the binary manually from the [Fusion releases](https://public.cdn.getdbt.com/fs/install/) and add it to your `PATH`.

Verify the installation:

```powershell
dbtf debug
```

## 6. Install packages and parse

```powershell
dbtf clean
dbtf deps
uvx dbt-autofix packages
dbtf init --fusion-upgrade
dbtf parse
```

Parsing will produce **2 warnings and 36 errors**. This is expected — the project was written for dbt Core, and Fusion enforces stricter validation on YAML schema and config keys that Core silently ignored.

Most fixes are straightforward: correct typos, move keys to the right nesting level, and adopt the new `arguments:` format for generic tests.

| Category | Error code | Count | Summary |
| --- | --- | --- | --- |
| Missing `+` prefix in `dbt_project.yml` | dbt1013 | 2 | Config keys need explicit `+` prefix |
| Root-level YAML anchors | dbt1060 | 3 | Move anchors under `anchors:` key |
| Typos/misspellings | dbt1060 | 4 | Fusion catches what Core ignored |
| Governance props at wrong level | dbt1060 | 5 | `access`/`contract`/`group` need `config:` wrapper |
| Custom/non-standard config keys | dbt1060 | 10 | Use `meta:` or remove dead config |
| Config on wrong resource type | dbt1060 | 1 | `materialized` on an analysis |
| `deprecation_date` in SQL config | dbt1060 | 1 | Use YAML property instead |
| Deprecated test argument format | dbt0102 | 8 | Nest args under `arguments:` |
| Warnings | dbt0102/1065 | 2 | Empty source + past deprecation date |

## 7. Run autofix

Use [dbt-autofix](https://github.com/dbt-labs/dbt-autofix) to resolve deprecations and upgrade packages to their latest Fusion-compatible versions.

After autofix, `dbtf parse` should pass cleanly.

## 7b. Use agents and agent skills!
You can use the `migrating-dbt-core-to-fusion` skill from the official [dbt-agent-skills repo](https://github.com/dbt-labs/dbt-agent-skills/tree/main). Open your IDE's chat window and run:
```
npx skills add dbt-labs/dbt-agent-skills --list
npx skills add dbt-labs/dbt-agent-skills --skill migrating-dbt-core-to-fusion
```

## 8. Compile and fix remaining issues

Run `dbtf compile`. You may hit the following:

- **`order_line_items_legacy`** — the `dbt_utils` upgrade renamed `surrogate_key` to `generate_surrogate_key`. Update the macro call in the model.
- **`monthly_payment_analysis_pivot_any`** — Fusion's static analysis requires deterministic column definitions. Refactor the `PIVOT` to use explicit `CASE` statements, or opt out with `static_analysis='off'` in the model config.
- dbt Labs is releasing updates to how static analysis works!
- **Remaining warnings in logs** — address any additional warnings surfaced during compilation.

Once resolved, `dbtf compile` should succeed.

## 9. Clone to a new target

Copy the compiled artifacts and run `dbt clone` to materialize into a new schema:

```powershell
dbt clone --state .\artifacts\target --target fusion_dev
```

## 10. Validate the run

```powershell
dbtf build --target fusion_dev
```
You may hit an error on **check constraints** in `financial_reporting_protected` — these silently failed in dbt Core but are now enforced. Remove the failing constraints from the model, and consider using [dbt_assertions](https://github.com/calogica/dbt-assertions) for runtime data quality checks instead.

After that, the run should complete successfully.

## 11. Resources
- [New Concepts in Fusion (Static Analysis)](https://docs.getdbt.com/docs/fusion/new-concepts)
