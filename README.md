# ExOdata4

An OData v4 query parser and Ecto query builder for Elixir. Parse OData query strings or full URIs and get back Ecto queries ready to execute against your own repo.

## Installation

Add `ex_odata4` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_odata4, "~> 0.1.0"}
  ]
end
```

## Configuration

Tell the library which OData entity names map to your Ecto schemas in `config/config.exs`:

```elixir
config :ex_odata4, schemas: %{
  "Orders" => MyApp.Orders,
  "Products" => MyApp.Products
}
```

The key is the entity name as it appears in the OData URI. The value is the Ecto schema module.

## Usage

### Parsing a full OData URI

```elixir
ExOdata4.parse_uri("/Orders?$filter=Amount gt 1000&$top=25&$skip=0")
|> MyApp.Repo.all()
```

### Parsing a query string directly

```elixir
ExOdata4.get("Orders", "$filter=Status eq 'active'&$orderby=CreatedAt desc&$top=10")
|> MyApp.Repo.all()
```

Both functions return an `%Ecto.Query{}`, so you pipe it into your own repo. This means the library has no opinion about your database, connection pool, or repo configuration.

## Supported OData query options

| Option | Example |
| --- | --- |
| `$filter` | `$filter=Name eq 'John'` |
| `$top` | `$top=25` |
| `$skip` | `$skip=50` |
| `$orderby` | `$orderby=Amount desc` |

### Supported filter operators

| Operator | Meaning |
| --- | --- |
| `eq` | Equal |
| `ne` | Not equal |
| `gt` | Greater than |
| `ge` | Greater than or equal |
| `lt` | Less than |
| `le` | Less than or equal |
| `and` | Logical and |
| `or` | Logical or |

### Supported literal types

- Strings: `'hello'`
- Integers: `42`, `-7`
- Decimals: `3.14`
- Booleans: `true`, `false`
- Null: `null`
- Dates: `2024-01-01`
- GUIDs: `00000000-0000-0000-0000-000000000000`

## Error handling

If a schema name is not found in your config, a descriptive error is raised:

```text
No schema configured for "Orders".

Add it to your config.exs:

    config :ex_odata4, schemas: %{
      "Orders" => MyApp.Orders
    }
```

## License

MIT
