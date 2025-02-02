defmodule EXLAHelpers do
  @doc """
  Returns the default EXLA client.
  """
  def client(), do: EXLA.Client.fetch!(String.to_atom(System.get_env("EXLA_TARGET", "host")))

  @doc """
  Compiles the given function.

  It expects a list of shapes which will be given as parameters.
  """
  def compile(shapes, opts \\ [], fun) do
    builder = EXLA.Builder.new("test")

    {params, _} =
      Enum.map_reduce(shapes, 0, fn shape, pos ->
        {EXLA.Op.parameter(builder, pos, shape, <<?a + pos>>), pos + 1}
      end)

    fun
    |> apply([builder | params])
    |> EXLA.Builder.build()
    |> EXLA.Computation.compile(client(), shapes, opts)
  end

  @doc """
  Compiles and runs the given function.

  It expects a list of buffers which will be have their shapes
  used for compilation and then given on execution.
  """
  def run_one(args, opts \\ [], fun) do
    exec = compile(Enum.map(args, & &1.shape), opts, fun)
    [result] = EXLA.Executable.run(exec, [args], opts)
    result
  end

  def make_buffer(i, type = {:s, size}, {}) do
    shape = EXLA.Shape.make_shape(type, {})
    EXLA.BinaryBuffer.from_binary(<<i::size(size)-native>>, shape)
  end

  def make_buffer(enumerable, type = {:s, size}, dims) do
    shape = EXLA.Shape.make_shape(type, dims)
    data = for x <- enumerable, into: <<>>, do: <<x::size(size)-native>>
    EXLA.BinaryBuffer.from_binary(data, shape)
  end
end
