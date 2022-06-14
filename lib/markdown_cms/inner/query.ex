defmodule MarkdownCMS.Inner.Query do

  @special_query_keys [:group_by]
  defmacro __using__(opts) do
    id_field = Keyword.get(opts, :default_id, :slug)
    data_source = Keyword.get(opts, :data_source, [])

    quote do
      @doc """
      Return all known items from the data_source
      """
      def all(opts \\ []) do
        {options, _} = process_options(opts)

        data_source()
        |> return_grouped(options)
      end

      @doc """
      Query data_source ...
      """
      def query(query) do
        {options, query_map} = process_options(query)

        data_source()
        |> Enum.filter(&(match_item(&1, query_map)))
        |> return_grouped(options)
      end

      @doc """
      Find first result matching query.
      """
      def find(query) do
        query(query)
        |> List.first
      end


      @doc """
      Fetch by using ID specified by "default_id" option (default: slug).
      Returns :error on nil, or {:ok, value} tuple.
      """
      @spec get(any) :: :error | {:ok, any()}
      def get(id) do
        query([{id_field(), id}])
        |> case do
             [] -> {:error, :not_found}
             [value] -> {:ok, value}
             _ -> {:error, :multiple_found}
           end
      end

      @doc """
      Fetch plain data item by using ID specified by "default_id" options (default: slug).
      Raises when not found.
      """
      def get!(id) do
        case get(id) do
          {:ok, value} -> value
          {:error, :not_found} -> raise "Item with #{id_field()} == #{inspect(id)} not found!"
          {:error, :multiple_found} -> raise "Multiple items with #{id_field()} == #{inspect(id)} found."
        end
      end

      defp match_item(item, query_map) do
        Enum.all?(query_map, fn {k, v} ->
          v in Keyword.get_values(item, k)
        end)
      end

      defp process_options(options) do
        Map.new(options) |> Map.split(unquote(@special_query_keys))
      end

      defp return_grouped(data, %{group_by: key}) do
        data
        |> Enum.group_by(&(Keyword.get(&1, key)))
      end
      defp return_grouped(data, _options), do: data

      defp id_field(), do: unquote(id_field)
      defp data_source(), do: unquote(data_source)
    end
  end
end
