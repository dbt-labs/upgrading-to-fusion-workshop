**Prompt Instruction:**

For each Python model in the project, do one of the following based on the provided guidance:
- Refactor the Python model into a dbt SQL model if possible.
- If the model should no longer be used, set it to be disabled by adding `enabled: false` in the dbt config.
- If the model should be retained but not tracked by dbt, move the Python file to a non-dbt folder outside of dbt's project structure.

Additionally, for all SQL models that reference any of these Python models, refactor their logic to remove the dependency on the Python models, ensuring they reference only valid dbt SQL models.