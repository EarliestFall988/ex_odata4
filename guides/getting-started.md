# Getting Started

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
  "Orders"   => MyApp.Orders,
  "Products" => MyApp.Products
}
```

The key is the entity name as it will appear in OData URIs. The value is your Ecto schema module.

OData field names are derived automatically from the schema — `:first_name` is exposed as `FirstName`, `:amount` as `Amount`, and so on.

## Querying data

### From a full OData URI

```elixir
ExOdata4.parse_uri("/Orders?$filter=Amount gt 1000&$top=25&$skip=0")
|> MyApp.Repo.all()
```

### From a query string

```elixir
ExOdata4.get("Orders", "$filter=Status eq 'active'&$orderby=Amount desc&$top=10")
|> MyApp.Repo.all()
```

Both return an `%Ecto.Query{}` ready to execute against your repo.

## Serving $metadata for Power BI

Power BI and Excel hit `/$metadata` when connecting to an OData source to discover entity types and field names. Serve it from your router:

```elixir
# Phoenix example
get "/$metadata", MetadataController, :index
```

```elixir
defmodule MyAppWeb.MetadataController do
  use MyAppWeb, :controller

  def index(conn, _params) do
    xml = ExOdata4.Metadata.generate(MyApp.Orders, namespace: "MyApp")
    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml)
  end
end
```

The namespace option is optional and defaults to `"Default"`.

## Connecting Power BI

1. In Power BI Desktop, choose **Get Data → OData feed**
2. Enter your service URL, e.g. `https://myapp.example.com/odata`
3. Power BI will fetch `/$metadata` automatically and show your entities in the navigator
4. Select the entities you want and load them

From there you can build reports and dashboards directly against your Elixir service with no custom connector required.
