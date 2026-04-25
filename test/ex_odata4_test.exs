defmodule ExOdata4Test do
  use ExUnit.Case
  doctest ExOdata4

  test "greets the world" do
    assert ExOdata4.hello() == :world
  end


  test "parses a simple query" do
    query = "Name eq 'John'"
    assert ExOdata4.parse(query) == query
  end

end
