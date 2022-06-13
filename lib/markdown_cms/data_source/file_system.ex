defmodule MarkdownCMS.DataSource.FileSystem do
  require Logger
  @behaviour MarkdownCMS.Inner.DataProvider

  @default_documents_location "markdown_cms/content/"
  def location do
    Application.get_env(:markdown_cms, :documents_location, @default_documents_location)
  end

  @default_content_tags [:title, :date, :locale, :type, :category, :slug, :tag]
  defp content_tags do
    Application.get_env(:markdown_cms, :content_tags, @default_content_tags)
  end

  @impl true
  def load do
    Logger.debug("Load data from filesystem")

    File.ls!(location())
    |> Enum.map(&( Path.join(location(), &1)))
    |> Enum.map(&unpack_files/1)
    |> List.flatten
    |> Enum.filter(&markdown_only/1)
    |> Enum.map(&parse/1)
  end

  defp markdown_only(file) do
    String.ends_with?(String.downcase(file), ".md")
  end

  defp unpack_files(path) do
    if File.dir?(path) do
      Enum.map(File.ls!(path), &(unpack_files(Path.join(path, &1))))
    else
      path
    end
  end

  defp remove_extension(file_name) do
    file_name
    |> String.split(".")
    |> List.first
  end

  def parse(file) do
    parsed = SemanticMarkdown.transform_from_file!(
      file,
      content_tags(),
      earmark_inner_transform: false
    )

    with_extras(parsed, file)
  end

  defp slugify(file_name) do
    file_name
    |> remove_extension
    |> String.replace("_", "-")
  end

  defp add_slug({parsed, split_path} = pair) do
    if !Keyword.has_key?(parsed, :slug) do
      {parsed ++ [slug: slugify(List.last(split_path))], split_path}
    else
      pair
    end
  end

  defp add_type({parsed, split_path}) when length(split_path) == 2 do
    if Keyword.has_key?(parsed, :type) do
      {parsed, split_path}
    else
      {parsed ++ [type: Enum.at(split_path, 0)], split_path}
    end
  end
  defp add_type(value), do: value

  defp add_type_tree({parsed, split_path}) when length(split_path) > 2 do
      {parsed ++ [type_tree: Enum.slice(split_path, 0..-1)], split_path}
  end
  defp add_type_tree(value), do: value

  defp with_extras(parsed, path) do
    split_path = Path.split(String.replace(path, location(), ""))

    {parsed, split_path}
    |> add_slug()
    |> add_type()
    |> add_type_tree()
    |> elem(0)
  end
end
