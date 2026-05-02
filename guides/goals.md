# Goals

ExOdata4 is designed to make it easy for internal Elixir services to expose data to BI tools like Power BI and Excel — without building custom connectors or writing boilerplate.

## Who this is for

Teams that have an Elixir/Ecto-backed service and need to give other teams access to that data through familiar tools. The primary use case is Power BI and Excel, which speak OData natively and can connect directly to an OData endpoint with no custom client code.

## Design principles

**Convention over configuration.** OData field names are derived automatically from your Ecto schema — `:first_name` becomes `FirstName`, `:amount` becomes `Amount`. You don't need to define a separate mapping to get started.

**Bring your own repo.** ExOdata4 returns `%Ecto.Query{}` structs. You pipe them into your own repo, which means the library has no opinion about your database, connection pool, or repo configuration.

**$metadata first.** Power BI and Excel hit `/$metadata` on connection to discover entity types and field names. ExOdata4 generates this document automatically from your Ecto schema so connecting a new data source is frictionless.

## What's out of scope

ExOdata4 does not aim for full OData v4 compliance. Features like `$expand`, navigation properties, and lambda operators are not planned. The focus is on the query capabilities that BI tools actually use day to day.
