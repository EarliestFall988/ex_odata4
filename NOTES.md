# Development Notes

## Target use case

Internal Elixir services accessed by Power BI, Excel, and similar BI tools. Teams need OData query support without building custom connectors.

## Architecture: convention-first

Auto-derive OData field names from Ecto schema atoms — no config or entity module required. Snake_case atoms become PascalCase OData names automatically (`:first_name` → `"FirstName"`). The field map is built at query time via `build_field_map/1`.

Explicit entity modules are a potential future escape hatch for teams that need to hide or rename fields.

## What's built

- `$filter` — comparison ops (`eq`, `ne`, `gt`, `ge`, `lt`, `le`), logical ops (`and`, `or`), parenthesized expressions
- String functions — `contains`, `startswith`, `endswith`
- Unary functions — `tolower`, `toupper`, `year`, `month`, `day`, `hour`
- `$top`, `$skip`, `$orderby`
- `$metadata` — auto-generated from Ecto schema, covers all common EDM types

## Roadmap

- `$select` — maps to Ecto `select`
- `not` operator
- Math functions: `round`, `floor`, `ceiling`
- Explicit entity module DSL — opt-in for field-level access control
- `$expand` — navigation properties (longer term)
