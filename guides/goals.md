# Goals

ExOdata4 is designed to make it easy for internal Elixir services to expose data to BI tools like Power BI and Excel — without building custom connectors or writing boilerplate.

## Who this is for

Teams that have an Elixir/Ecto-backed service and need to give other teams access to that data through familiar tools. The primary use case is Power BI and Excel, which speak OData natively and can connect directly to an OData endpoint with no custom client code.

## Design principles

**Convention over configuration.** OData field names are derived automatically from your Ecto schema — `:first_name` becomes `FirstName`, `:amount` becomes `Amount`. You don't need to define a separate mapping to get started.

**Bring your own repo.** ExOdata4 returns `%Ecto.Query{}` structs. You pipe them into your own repo, which means the library has no opinion about your database, connection pool, or repo configuration.

**$metadata first.** Power BI and Excel hit `/$metadata` on connection to discover entity types and field names. ExOdata4 generates this document automatically from your Ecto schema so connecting a new data source is frictionless.

## Roadmap

The goal is near-parity with the OData v4 spec — not perfect compliance, but broad enough coverage that teams can use it for real work without hitting walls.

Features are shipped in order of practical value rather than spec completeness. Navigation properties and `$expand` are planned but take time to get right. In the meantime the focus is on getting the high-value query features out — filtering, sorting, pagination, functions, and metadata — which cover the vast majority of what BI tools actually need.
