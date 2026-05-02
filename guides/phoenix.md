# Phoenix Integration

This guide shows how to wire ExOdata4 into a Phoenix application to expose an OData endpoint that Power BI and Excel can connect to directly.

## Router

Add a scope for your OData routes. The `$metadata` route must come before the `/:entity` catch-all.

```elixir
# lib/my_app_web/router.ex
scope "/odata", MyAppWeb do
  pipe_through :api

  get "/$metadata", ODataController, :metadata
  get "/:entity",   ODataController, :query
end
```

> The `$` in `/$metadata` is a literal path match. Phoenix handles it correctly.

## Controller

```elixir
# lib/my_app_web/controllers/odata_controller.ex
defmodule MyAppWeb.ODataController do
  use MyAppWeb, :controller

  @schemas Application.compile_env(:ex_odata4, :schemas, %{})

  def metadata(conn, _params) do
    xml = ExOdata4.Metadata.generate_service(@schemas, namespace: "MyApp")

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml)
  end

  def query(conn, %{"entity" => entity} = params) do
    query_string = URI.encode_query(Map.drop(params, ["entity"]))

    case ExOdata4.get(entity, query_string) do
      query ->
        results = MyApp.Repo.all(query)
        json(conn, %{value: results})
    end
  rescue
    e in RuntimeError ->
      conn
      |> put_status(:not_found)
      |> json(%{error: e.message})

    e in ArgumentError ->
      conn
      |> put_status(:bad_request)
      |> json(%{error: e.message})
  end
end
```

## Configuration

Register your schemas in `config/config.exs`:

```elixir
config :ex_odata4, schemas: %{
  "Orders"   => MyApp.Orders,
  "Products" => MyApp.Products
}
```

## How it works

With this setup your service handles:

| Request | What happens |
| --- | --- |
| `GET /odata/$metadata` | Returns XML describing all entity types and fields |
| `GET /odata/Orders` | Returns all orders |
| `GET /odata/Orders?$filter=Amount gt 1000` | Returns filtered orders |
| `GET /odata/Orders?$filter=Status eq 'active'&$orderby=Amount desc&$top=25` | Filtered, sorted, paginated |

## Connecting Power BI

1. Open Power BI Desktop and choose **Get Data → OData feed**
2. Enter your service URL: `https://myapp.example.com/odata`
3. Power BI fetches `/$metadata` automatically and lists your entities
4. Select the entities you want and click **Load**

From there you can build reports directly against your Elixir service with no custom connector required.
