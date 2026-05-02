defmodule ExOdata4.Ecto.BuilderTest do
  use ExUnit.Case

  alias ExOdata4.Ecto.Builder
  alias ExOdata4.Query
  alias ExOdata4.Test.Trade

  defp build(params) do
    Builder.build(Trade, struct(Query, params))
  end

  describe "orderby" do
    test "single field ascending (default)" do
      query = build(orderby: ["Name"])
      assert inspect(query) =~ "order_by"
      assert inspect(query) =~ "asc"
    end

    test "single field with explicit direction" do
      query = build(orderby: ["Amount", :desc])
      assert inspect(query) =~ "order_by"
      assert inspect(query) =~ "desc"
    end

    test "multiple fields" do
      query = build(orderby: ["Amount", :desc, "Name", :asc])
      assert inspect(query) =~ "order_by"
    end

    test "nil orderby does not apply order_by" do
      query = build(orderby: nil)
      refute inspect(query) =~ "order_by"
    end
  end

  describe "filter - comparison operators" do
    test "eq builds a where clause" do
      query = build(filter: [%ExOdata4.AST.BinaryOp{
        op: :eq,
        left: %ExOdata4.AST.Field{name: "Name"},
        right: %ExOdata4.AST.Literal{value: "foo"}
      }])

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "where"
    end

    test "gt builds a where clause" do
      query = build(filter: [%ExOdata4.AST.BinaryOp{
        op: :gt,
        left: %ExOdata4.AST.Field{name: "Amount"},
        right: %ExOdata4.AST.Literal{value: 100.0}
      }])

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "where"
    end

    test "lt builds a where clause" do
      query = build(filter: [%ExOdata4.AST.BinaryOp{
        op: :lt,
        left: %ExOdata4.AST.Field{name: "Amount"},
        right: %ExOdata4.AST.Literal{value: 50.0}
      }])

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "where"
    end

    test "ne builds a where clause" do
      query = build(filter: [%ExOdata4.AST.BinaryOp{
        op: :ne,
        left: %ExOdata4.AST.Field{name: "Status"},
        right: %ExOdata4.AST.Literal{value: "closed"}
      }])

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "where"
    end

    test "ge builds a where clause" do
      query = build(filter: [%ExOdata4.AST.BinaryOp{
        op: :ge,
        left: %ExOdata4.AST.Field{name: "Amount"},
        right: %ExOdata4.AST.Literal{value: 100.0}
      }])

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "where"
    end

    test "le builds a where clause" do
      query = build(filter: [%ExOdata4.AST.BinaryOp{
        op: :le,
        left: %ExOdata4.AST.Field{name: "Amount"},
        right: %ExOdata4.AST.Literal{value: 100.0}
      }])

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "where"
    end
  end

  describe "filter - logical operators" do
    test "and combines two expressions" do
      query = build(filter: [%ExOdata4.AST.BinaryOp{
        op: :and,
        left: %ExOdata4.AST.BinaryOp{
          op: :eq,
          left: %ExOdata4.AST.Field{name: "Status"},
          right: %ExOdata4.AST.Literal{value: "active"}
        },
        right: %ExOdata4.AST.BinaryOp{
          op: :gt,
          left: %ExOdata4.AST.Field{name: "Amount"},
          right: %ExOdata4.AST.Literal{value: 0.0}
        }
      }])

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "where"
    end

    test "or combines two expressions" do
      query = build(filter: [%ExOdata4.AST.BinaryOp{
        op: :or,
        left: %ExOdata4.AST.BinaryOp{
          op: :eq,
          left: %ExOdata4.AST.Field{name: "Status"},
          right: %ExOdata4.AST.Literal{value: "open"}
        },
        right: %ExOdata4.AST.BinaryOp{
          op: :eq,
          left: %ExOdata4.AST.Field{name: "Status"},
          right: %ExOdata4.AST.Literal{value: "pending"}
        }
      }])

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "where"
    end
  end

  describe "filter - unary functions" do
    test "tolower wraps field in lower()" do
      query = build(filter: [%ExOdata4.AST.BinaryOp{
        op: :eq,
        left: %ExOdata4.AST.FunctionCall{name: :tolower, args: [%ExOdata4.AST.Field{name: "Name"}]},
        right: %ExOdata4.AST.Literal{value: "foo"}
      }])
      assert inspect(query) =~ "lower"
    end

    test "toupper wraps field in upper()" do
      query = build(filter: [%ExOdata4.AST.BinaryOp{
        op: :eq,
        left: %ExOdata4.AST.FunctionCall{name: :toupper, args: [%ExOdata4.AST.Field{name: "Name"}]},
        right: %ExOdata4.AST.Literal{value: "FOO"}
      }])
      assert inspect(query) =~ "upper"
    end

    test "year extracts year from field" do
      query = build(filter: [%ExOdata4.AST.BinaryOp{
        op: :eq,
        left: %ExOdata4.AST.FunctionCall{name: :year, args: [%ExOdata4.AST.Field{name: "Date"}]},
        right: %ExOdata4.AST.Literal{value: 2024}
      }])
      assert inspect(query) =~ "year"
    end

    test "month extracts month from field" do
      query = build(filter: [%ExOdata4.AST.BinaryOp{
        op: :eq,
        left: %ExOdata4.AST.FunctionCall{name: :month, args: [%ExOdata4.AST.Field{name: "Date"}]},
        right: %ExOdata4.AST.Literal{value: 1}
      }])
      assert inspect(query) =~ "month"
    end

    test "day extracts day from field" do
      query = build(filter: [%ExOdata4.AST.BinaryOp{
        op: :eq,
        left: %ExOdata4.AST.FunctionCall{name: :day, args: [%ExOdata4.AST.Field{name: "Date"}]},
        right: %ExOdata4.AST.Literal{value: 15}
      }])
      assert inspect(query) =~ "day"
    end

    test "unary functions support non-eq comparison ops" do
      query = build(filter: [%ExOdata4.AST.BinaryOp{
        op: :gt,
        left: %ExOdata4.AST.FunctionCall{name: :year, args: [%ExOdata4.AST.Field{name: "Date"}]},
        right: %ExOdata4.AST.Literal{value: 2020}
      }])
      assert %Ecto.Query{} = query
    end

    test "raises for unknown field in unary function" do
      assert_raise ArgumentError, ~r/unknown field: nonexistent/, fn ->
        build(filter: [%ExOdata4.AST.BinaryOp{
          op: :eq,
          left: %ExOdata4.AST.FunctionCall{name: :tolower, args: [%ExOdata4.AST.Field{name: "nonexistent"}]},
          right: %ExOdata4.AST.Literal{value: "foo"}
        }])
      end
    end
  end

  describe "filter - string functions" do
    test "contains builds a LIKE %value% clause" do
      query = build(filter: [%ExOdata4.AST.FunctionCall{
        name: :contains,
        args: [%ExOdata4.AST.Field{name: "Name"}, %ExOdata4.AST.Literal{value: "foo"}]
      }])

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "%foo%"
    end

    test "startswith builds a LIKE value% clause" do
      query = build(filter: [%ExOdata4.AST.FunctionCall{
        name: :startswith,
        args: [%ExOdata4.AST.Field{name: "Name"}, %ExOdata4.AST.Literal{value: "foo"}]
      }])

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "foo%"
      refute inspect(query) =~ "%foo%"
    end

    test "endswith builds a LIKE %value clause" do
      query = build(filter: [%ExOdata4.AST.FunctionCall{
        name: :endswith,
        args: [%ExOdata4.AST.Field{name: "Name"}, %ExOdata4.AST.Literal{value: "foo"}]
      }])

      assert %Ecto.Query{} = query
      assert inspect(query) =~ "%foo"
      refute inspect(query) =~ "%foo%"
    end
  end

  describe "safe_atom / unknown fields" do
    test "raises ArgumentError for a field not in the schema" do
      assert_raise ArgumentError, ~r/unknown field: nonexistent/, fn ->
        build(filter: [%ExOdata4.AST.BinaryOp{
          op: :eq,
          left: %ExOdata4.AST.Field{name: "nonexistent"},
          right: %ExOdata4.AST.Literal{value: "x"}
        }])
      end
    end

    test "raises for unknown field in a function call" do
      assert_raise ArgumentError, ~r/unknown field: nonexistent/, fn ->
        build(filter: [%ExOdata4.AST.FunctionCall{
          name: :contains,
          args: [%ExOdata4.AST.Field{name: "nonexistent"}, %ExOdata4.AST.Literal{value: "x"}]
        }])
      end
    end

    test "raises for unknown field nested in and" do
      assert_raise ArgumentError, ~r/unknown field: nonexistent/, fn ->
        build(filter: [%ExOdata4.AST.BinaryOp{
          op: :and,
          left: %ExOdata4.AST.BinaryOp{
            op: :eq,
            left: %ExOdata4.AST.Field{name: "Name"},
            right: %ExOdata4.AST.Literal{value: "foo"}
          },
          right: %ExOdata4.AST.BinaryOp{
            op: :eq,
            left: %ExOdata4.AST.Field{name: "nonexistent"},
            right: %ExOdata4.AST.Literal{value: "bar"}
          }
        }])
      end
    end
  end

  describe "top / skip" do
    test "top applies a limit" do
      query = build(top: 10)
      assert inspect(query) =~ "limit"
    end

    test "skip applies an offset" do
      query = build(skip: 5)
      assert inspect(query) =~ "offset"
    end

    test "nil top does not apply a limit" do
      query = build(top: nil)
      refute inspect(query) =~ "limit"
    end

    test "nil skip does not apply an offset" do
      query = build(skip: nil)
      refute inspect(query) =~ "offset"
    end
  end

  describe "no filter" do
    test "nil filter returns base schema without where clause" do
      query = build(filter: nil)
      refute inspect(query) =~ "where"
    end
  end
end
