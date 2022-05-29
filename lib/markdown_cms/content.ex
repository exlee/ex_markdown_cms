defmodule MarkdownCMS.Content do
  @location Application.get_env(:markdown_cms, :document_location)
  @default_document_location "markdown_cms/content/"
  @parsed_content_tags [:title, :date, :locale, :category, :slug, :tag]

  def parse(file) do
    parsed = SemanticMarkdown.transform_from_file!(
      file,
      get_transform_tags(),
      earmark_inner_transform: false
    )

    with_extras(parsed, file)
  end


  defp add_slug({parsed, split_path} = pair) do
    if !Keyword.has_key?(parsed, :slug) do
      {parsed ++ [slug: slugify(List.last(split_path))], split_path}
    else
      pair
    end
  end

  defp add_type({parsed, split_path}) when length(split_path) == 2 do
      {parsed ++ [type: Enum.at(split_path, 0)], split_path}
  end
  defp add_type(value), do: value

  defp add_type_tree({parsed, split_path}) when length(split_path) > 2 do
      {parsed ++ [type_tree: Enum.slice(split_path, 0, -1)], split_path}
  end
  defp add_type_tree(value), do: value

  defp with_extras(parsed, path) do
    split_path = Path.split(String.replace(path, location, ""))

    {parsed, split_path}
    |> add_slug()
    |> add_type()
    |> add_type_tree()
    |> elem(0)

  end

  defp get_transform_tags do
    cond do
      extra_tags = Application.get_env(:markdown_cms, :extra_parse_tags) ->
        @parsed_content_tags ++ List.wrap(extra_tags)
      parse_tags = Application.get_env(:markdown_cms, :parse_tags) ->
        parse_tags
      true ->
        @parsed_content_tags
    end
  end

  def initialize_all do
    File.ls!(location)
    |> Enum.map(&( Path.join(location, &1)))
    |> Enum.map(&unpack_files/1)
    |> List.flatten
    |> Enum.filter(&markdown_only/1)
    |> Enum.map(&parse/1)
  end

  def all(opts \\ []) do
    initialize_all
    |> return_grouped(Map.new(opts))
  end

  defp remove_extension(file_name) do
    file_name
    |> String.split(".")
    |> List.first
  end

  defp slugify(file_name) do
    file_name
    |> remove_extension
    |> String.replace("_", "-")
  end

  defp unpack_files(path) do
    if File.dir?(path) do
      Enum.map(File.ls!(path), &(unpack_files(Path.join(path, &1))))
    else
      path
    end
  end

  defp markdown_only(file) do
    String.ends_with?(String.downcase(file), ".md")
  end

  defp return_grouped(data, %{group_by: key}) do
    data
    |> Enum.group_by(&(Keyword.get(&1, key)))
  end
  defp return_grouped(data, _options), do: data


  @special_keys [:group_by]
  def query(query) do
    {options, query_map} = Map.new(query) |> Map.split(@special_keys)

    all()
    |> Enum.filter(&(match_item(&1, query_map)))
    |> return_grouped(options)
  end

  def match_item(item, query_map) do
    Enum.all?(query_map, fn {k, v} ->
      v in Keyword.get_values(item, k)
    end)
  end

  def find(query) do
    query(query)
    |> List.first
  end

  def location do
    Application.get_env(:markdown_cms, :document_location, @default_document_location)
  end
end
