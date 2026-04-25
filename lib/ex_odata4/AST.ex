# lib/ex_odata4/ast.ex
defmodule ExOdata4.AST do
  defmodule Literal do
    defstruct [:type, :value]
    # %Literal{type: :string, value: "John"}
    # %Literal{type: :integer, value: 1000}
    # %Literal{type: :boolean, value: true}
    # %Literal{type: :date, value: ~D[2024-01-01]}
    # %Literal{type: :null, value: nil}
  end

  defmodule Field do
    defstruct [:name]
    # %Field{name: "Amount"}
  end

  defmodule BinaryOp do
    defstruct [:op, :left, :right]
    # %BinaryOp{op: :gt, left: %Field{name: "Amount"}, right: %Literal{type: :integer, value: 1000}}
    # %BinaryOp{op: :and, left: %BinaryOp{...}, right: %BinaryOp{...}}
  end

  defmodule OrderbyItem do
    defstruct [:field, :direction]
    # %OrderbyItem{field: "Amount", direction: :desc}
  end
end
