Stricter evaluation of duplicate docs blocks
In older versions of dbt Core, it was possible to create scenarios with duplicate docs blocks. For example, you can have two packages with identical docs blocks referenced by an unqualified name in your dbt project. In this case, dbt Core would use whichever docs block is referenced without any warnings or errors.

Fusion adds stricter evaluation of names of docs blocks to prevent such ambiguity. It will present an error if it detects duplicate names:

dbt found two docs with the same name: 'docs_block_title in files: 'models/crm/_crm.md' and 'docs/crm/business_class_marketing.md'


To resolve this error, rename any duplicate docs blocks.