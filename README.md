# ExOdata4

An OData v4 query parser and Ecto query builder for Elixir. Parse OData query strings or full URIs and get back Ecto queries ready to execute against your own repo. Designed for exposing internal Elixir services to BI tools like Power BI and Excel.

## Installation

Add `ex_odata4` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_odata4, "~> 0.2.0"}
  ]
end
```

## Configuration

Register your Ecto schemas in `config/config.exs`:

```elixir
config :ex_odata4, schemas: %{
  "Orders" => MyApp.Orders,
  "Products" => MyApp.Products
}
```

OData field names are automatically derived from your schema — Ecto's snake_case atoms become PascalCase OData names. So `:first_name` is exposed as `FirstName`, `:amount` as `Amount`, and so on. No additional mapping is required.

## Usage

### Parsing a full OData URI

```elixir
ExOdata4.parse_uri("/Orders?$filter=Amount gt 1000&$top=25&$skip=0")
|> MyApp.Repo.all()
```

### Parsing a query string directly

```elixir
ExOdata4.get("Orders", "$filter=Status eq 'active'&$orderby=Amount desc&$top=10")
|> MyApp.Repo.all()
```

Both functions return an `%Ecto.Query{}` ready to pipe into your repo.

### $metadata

For Power BI and Excel, serve the `$metadata` document from your router:

```elixir
# In your Phoenix router or Plug
get "/$metadata", fn conn, _ ->
  xml = ExOdata4.Metadata.generate(MyApp.Orders, namespace: "MyApp")
  conn
  |> put_resp_content_type("application/xml")
  |> send_resp(200, xml)
end
```

`generate/2` accepts an optional `:namespace` (defaults to `"Default"`).

## Supported OData query options

| Option | Example |
| --- | --- |
| `$filter` | `$filter=Name eq 'John'` |
| `$top` | `$top=25` |
| `$skip` | `$skip=50` |
| `$orderby` | `$orderby=Amount desc,Name asc` |
| `$metadata` | `GET /$metadata` |

### Filter operators

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

### Filter functions

| Function | Example | SQL |
| --- | --- | --- |
| `contains` | `contains(Name, 'Jo')` | `LIKE '%Jo%'` |
| `startswith` | `startswith(Name, 'Jo')` | `LIKE 'Jo%'` |
| `endswith` | `endswith(Email, '.com')` | `LIKE '%.com'` |
| `tolower` | `tolower(Name) eq 'john'` | `lower(name) = 'john'` |
| `toupper` | `toupper(Name) eq 'JOHN'` | `upper(name) = 'JOHN'` |
| `year` | `year(Date) eq 2024` | `extract(year from date) = 2024` |
| `month` | `month(Date) eq 1` | `extract(month from date) = 1` |
| `day` | `day(Date) eq 15` | `extract(day from date) = 15` |
| `hour` | `hour(Timestamp) gt 8` | `extract(hour from timestamp) > 8` |

Functions can be combined with logical operators:

```text
$filter=contains(Name, 'John') and Amount gt 100
$filter=tolower(Status) eq 'active' or year(Date) gt 2023
```

### Supported literal types

- Strings: `'hello'`
- Integers: `42`, `-7`
- Decimals: `3.14`
- Booleans: `true`, `false`
- Null: `null`
- Dates: `2024-01-01`
- DateTimeOffset: `2024-01-01T00:00:00Z`
- GUIDs: `00000000-0000-0000-0000-000000000000`

### EDM type mapping

`$metadata` automatically maps Ecto types to OData EDM types:

| Ecto type | EDM type |
| --- | --- |
| `:string` | `Edm.String` |
| `:integer` | `Edm.Int32` |
| `:float` | `Edm.Double` |
| `:decimal` | `Edm.Decimal` |
| `:boolean` | `Edm.Boolean` |
| `:date` | `Edm.Date` |
| `:utc_datetime` / `:naive_datetime` | `Edm.DateTimeOffset` |
| `:binary_id` | `Edm.Guid` |

## Not yet supported

- `$select` — field projection
- `$expand` — loading related entities
- `$count` — total result count
- `not` — logical negation
- Math functions: `round()`, `floor()`, `ceiling()`
- Lambda operators: `any()`, `all()`
- Navigation properties

Contributions are welcome. Open an issue or PR on [GitHub](https://github.com/EarliestFall988/ex_odata4).

## License

MIT
