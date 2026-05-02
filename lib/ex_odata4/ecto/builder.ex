defmodule ExOdata4.Ecto.Builder do
  import Ecto.Query
  alias ExOdata4.AST

  def build(schema, %ExOdata4.Query{} = query) do
    field_map = build_field_map(schema)

    schema
    |> apply_filter(query.filter, field_map)
    |> apply_top(query.top)
    |> apply_skip(query.skip)
    |> apply_orderby(query.orderby, field_map)
  end

  defp build_field_map(schema) do
    schema.__schema__(:fields)
    |> Map.new(fn atom ->
      odata_name =
        atom
        |> Atom.to_string()
        |> String.split("_")
        |> Enum.map_join(&String.capitalize/1)
      {odata_name, atom}
    end)
  end

  defp apply_filter(query, nil, _valid_fields), do: query
  defp apply_filter(query, [expr], valid_fields) do
    where(query, ^build_expr(expr, valid_fields))
  end

  defp build_expr(%AST.FunctionCall{name: :contains, args: [%AST.Field{name: f}, %AST.Literal{value: v}]}, valid_fields) do
    dynamic([q], like(field(q, ^safe_atom(f, valid_fields)), ^"%#{v}%"))
  end

  defp build_expr(%AST.FunctionCall{name: :startswith, args: [%AST.Field{name: f}, %AST.Literal{value: v}]}, valid_fields) do
    dynamic([q], like(field(q, ^safe_atom(f, valid_fields)), ^"#{v}%"))
  end

  defp build_expr(%AST.FunctionCall{name: :endswith, args: [%AST.Field{name: f}, %AST.Literal{value: v}]}, valid_fields) do
    dynamic([q], like(field(q, ^safe_atom(f, valid_fields)), ^"%#{v}"))
  end

  @unary_functions [:tolower, :toupper, :year, :month, :day, :hour]

  defp build_expr(%AST.BinaryOp{op: op, left: %AST.FunctionCall{name: func, args: [%AST.Field{name: f}]}, right: %AST.Literal{value: v}}, valid_fields)
       when func in @unary_functions do
    field_dyn = unary_field_expr(func, f, valid_fields)
    apply_comparison(op, field_dyn, v)
  end

  defp build_expr(%AST.BinaryOp{op: :eq, left: %AST.Field{name: f}, right: %AST.Literal{value: v}}, valid_fields) do
    dynamic([q], field(q, ^safe_atom(f, valid_fields)) == ^v)
  end

  defp build_expr(%AST.BinaryOp{op: :ne, left: %AST.Field{name: f}, right: %AST.Literal{value: v}}, valid_fields) do
    dynamic([q], field(q, ^safe_atom(f, valid_fields)) != ^v)
  end

  defp build_expr(%AST.BinaryOp{op: :gt, left: %AST.Field{name: f}, right: %AST.Literal{value: v}}, valid_fields) do
    dynamic([q], field(q, ^safe_atom(f, valid_fields)) > ^v)
  end

  defp build_expr(%AST.BinaryOp{op: :ge, left: %AST.Field{name: f}, right: %AST.Literal{value: v}}, valid_fields) do
    dynamic([q], field(q, ^safe_atom(f, valid_fields)) >= ^v)
  end

  defp build_expr(%AST.BinaryOp{op: :lt, left: %AST.Field{name: f}, right: %AST.Literal{value: v}}, valid_fields) do
    dynamic([q], field(q, ^safe_atom(f, valid_fields)) < ^v)
  end

  defp build_expr(%AST.BinaryOp{op: :le, left: %AST.Field{name: f}, right: %AST.Literal{value: v}}, valid_fields) do
    dynamic([q], field(q, ^safe_atom(f, valid_fields)) <= ^v)
  end

  defp build_expr(%AST.BinaryOp{op: :and, left: left, right: right}, valid_fields) do
    dynamic([q], ^build_expr(left, valid_fields) and ^build_expr(right, valid_fields))
  end

  defp build_expr(%AST.BinaryOp{op: :or, left: left, right: right}, valid_fields) do
    dynamic([q], ^build_expr(left, valid_fields) or ^build_expr(right, valid_fields))
  end

  defp unary_field_expr(:tolower, f, vf), do: dynamic([q], fragment("lower(?)", field(q, ^safe_atom(f, vf))))
  defp unary_field_expr(:toupper, f, vf), do: dynamic([q], fragment("upper(?)", field(q, ^safe_atom(f, vf))))
  defp unary_field_expr(:year,    f, vf), do: dynamic([q], fragment("extract(year from ?)",  field(q, ^safe_atom(f, vf))))
  defp unary_field_expr(:month,   f, vf), do: dynamic([q], fragment("extract(month from ?)", field(q, ^safe_atom(f, vf))))
  defp unary_field_expr(:day,     f, vf), do: dynamic([q], fragment("extract(day from ?)",   field(q, ^safe_atom(f, vf))))
  defp unary_field_expr(:hour,    f, vf), do: dynamic([q], fragment("extract(hour from ?)",  field(q, ^safe_atom(f, vf))))

  defp apply_comparison(:eq, dyn, v), do: dynamic([q], ^dyn == ^v)
  defp apply_comparison(:ne, dyn, v), do: dynamic([q], ^dyn != ^v)
  defp apply_comparison(:gt, dyn, v), do: dynamic([q], ^dyn > ^v)
  defp apply_comparison(:ge, dyn, v), do: dynamic([q], ^dyn >= ^v)
  defp apply_comparison(:lt, dyn, v), do: dynamic([q], ^dyn < ^v)
  defp apply_comparison(:le, dyn, v), do: dynamic([q], ^dyn <= ^v)

  defp safe_atom(field_name, field_map) do
    case Map.fetch(field_map, field_name) do
      {:ok, atom} -> atom
      :error -> raise ArgumentError, "unknown field: #{field_name}"
    end
  end

  # ... rest of operators

  defp apply_top(query, nil), do: query
  defp apply_top(query, n), do: limit(query, ^n)

  defp apply_skip(query, nil), do: query
  defp apply_skip(query, n), do: offset(query, ^n)

  defp apply_orderby(query, nil, _valid_fields), do: query
  defp apply_orderby(query, items, valid_fields) do
    clauses = parse_orderby_items(items, valid_fields)
    order_by(query, ^clauses)
  end

  defp parse_orderby_items([], _valid_fields), do: []
  defp parse_orderby_items([field | rest], valid_fields) when is_binary(field) do
    {dir, remaining} = case rest do
      [d | tail] when d in [:asc, :desc] -> {d, tail}
      _ -> {:asc, rest}
    end
    [{dir, dynamic([q], field(q, ^safe_atom(field, valid_fields)))} | parse_orderby_items(remaining, valid_fields)]
  end
end
