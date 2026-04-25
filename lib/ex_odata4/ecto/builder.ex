defmodule ExOdata4.Ecto.Builder do
  import Ecto.Query
  alias ExOdata4.AST

  def build(schema, %ExOdata4.Query{} = query) do
    schema
    |> apply_filter(query.filter)
    |> apply_top(query.top)
    |> apply_skip(query.skip)
    # |> apply_orderby(query.orderby)
  end

  defp apply_filter(query, nil), do: query
  defp apply_filter(query, [expr]) do
    where(query, ^build_expr(expr))
  end

  defp build_expr(%AST.BinaryOp{op: :eq, left: %AST.Field{name: f}, right: %AST.Literal{value: v}}) do
    dynamic([q], field(q, ^String.to_atom(f)) == ^v)
  end

  defp build_expr(%AST.BinaryOp{op: :gt, left: %AST.Field{name: f}, right: %AST.Literal{value: v}}) do
    dynamic([q], field(q, ^String.to_atom(f)) > ^v)
  end

  defp build_expr(%AST.BinaryOp{op: :lt, left: %AST.Field{name: f}, right: %AST.Literal{value: v}}) do
    dynamic([q], field(q, ^String.to_atom(f)) < ^v)
  end

  defp build_expr(%AST.BinaryOp{op: :and, left: left, right: right}) do
    dynamic([q], ^build_expr(left) and ^build_expr(right))
  end

  defp build_expr(%AST.BinaryOp{op: :or, left: left, right: right}) do
    dynamic([q], ^build_expr(left) or ^build_expr(right))
  end

  # ... rest of operators

  defp apply_top(query, nil), do: query
  defp apply_top(query, n), do: limit(query, ^n)

  defp apply_skip(query, nil), do: query
  defp apply_skip(query, n), do: offset(query, ^n)
end
