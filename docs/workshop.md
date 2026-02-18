# Upgrading to Fusion Workshop

## Prerequisites

Before the workshop, make sure you have the following installed:

- [VS Code](https://code.visualstudio.com/) (or another editor of your choice)
- [Git](https://git-scm.com/)
- [dbt extension for VS Code](https://marketplace.visualstudio.com/items?itemName=dbtLabsInc.dbt&ssr=false#overview)
- [uv](https://docs.astral.sh/uv/) — install with `curl -LsSf https://astral.sh/uv/install.sh | sh`

## 1. Clone the starter repo

```bash
git clone https://github.com/dbt-labs/upgrading-to-fusion-workshop.git
cd upgrading-to-fusion-workshop
```

## 2. Set up a Snowflake demo account

1. Go to [signup.snowflake.com](https://signup.snowflake.com/) (no credit card required)
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

```bash
uv venv --python 3.12 .venv
source .venv/bin/activate
uv pip install dbt-snowflake
dbt seed --vars 'load_source_data: true'
```

## 5. Install the Fusion CLI

```bash
curl -fsSL https://public.cdn.getdbt.com/fs/install/install.sh | sh -s -- --update
```

Verify the installation:

```bash
dbtf debug
```

## 6. Install packages and parse

```bash
dbtf deps
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

## 8. Compile and fix remaining issues

Run `dbtf compile`. You may hit the following:

- **`order_line_items_legacy`** — the `dbt_utils` upgrade renamed `surrogate_key` to `generate_surrogate_key`. Update the macro call in the model.
- **`monthly_payment_analysis_pivot_any`** — Fusion's static analysis requires deterministic column definitions. Refactor the `PIVOT` to use explicit `CASE` statements, or opt out with `static_analysis='off'` in the model config.
- **Remaining warnings in logs** — address any additional warnings surfaced during compilation.

Once resolved, `dbtf compile` should succeed.

## 9. Clone to a new target

Copy the compiled artifacts and run `dbt clone` to materialize into a new schema:

```bash
cp -r ./target artifacts
dbt clone --state ./artifacts/target --full-refresh --target fusion_dev
```

## 10. Validate the run

You may hit an error on **check constraints** in `financial_reporting_protected` — these silently failed in dbt Core but are now enforced. Remove the failing constraints from the model, and consider using [dbt_assertions](https://github.com/calogica/dbt-assertions) for runtime data quality checks instead.

After that, the run should complete successfully.
