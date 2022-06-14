defmodule MarkdownCMS.DataSource.FileSystem do
  require Logger
  @behaviour MarkdownCMS.Inner.DataProvider

  @impl true
  def load(pid \\ __MODULE__) do
    if debug?(pid) do
      Logger.debug("Loading from filesystem")
      Agent.get(pid, fn state -> load_from_filesystem(state) end)
    else
      Logger.debug("Loading from Agent")
      Agent.get(pid, fn state -> state.data end)
    end
  end

  def reload(pid \\ __MODULE__) do
    Logger.debug("Reloading filesystem")

    Agent.get_and_update(pid, fn state ->
      Map.put(state, :data, load_from_filesystem(state))
    end)
  end

  @spec load_from_filesystem(options_map()) :: any
  def load_from_filesystem(options) do

    File.ls!(options.documents_location)
    |> Enum.map(&( Path.join(options.documents_location, &1)))
    |> Enum.map(&unpack_files/1)
    |> List.flatten
    |> Enum.filter(&markdown_only/1)
    |> Enum.map(&(parse(options, &1)))
  end

  use Agent

  @default_name __MODULE__

  @default_options %{
    documents_location: "markdown_cms/content/",
    content_tags: [:title, :date, :locale, :type, :category, :slug, :tag],
    debug: false
  }

  @type options() :: [option()]
  @type option() ::
            {:content_tags, [atom(), ...]}
            | {:documents_location, String.t}
            | {:debug, bool()}
            | {:name, atom()}

  @type options_map() :: %{
    content_tags: [atom(), ...],
    documents_location: String.t,
    debug: bool()
  }


  @spec start_link(options()) :: Agent.on_start()
  def start_link(opts) do
    options_map = Map.new(opts)
    |> Map.take([:content_tags, :documents_location, :debug])
    |> then(&(Map.merge(@default_options, &1)))
    |> ensure_trailing_slash()

    data = load_from_filesystem(options_map)

    Agent.start_link(
      fn -> Map.put(options_map, :data, data) end,
      name: Keyword.get(opts, :name, @default_name)
    )
  end

  defp ensure_trailing_slash(options_map) do
    location = options_map.documents_location
    unless String.ends_with?(location, "/") do
      %{options_map | documents_location: location <> "/"}
    else
      options_map
    end
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


  def parse(options, file) do
    parsed = SemanticMarkdown.transform_from_file!(
      file,
      options.content_tags,
      earmark_inner_transform: false
    )

    with_extras(options, parsed, file)
  end

  def debug?(pid) do
    Agent.get(pid, fn state -> state.debug end)
  end
  def data(pid) do
    Agent.get(pid, fn state -> state.data end)
  end

  defp check_for_duplicate_ids(keys, options) do
    IO.inspect(keys)
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

  defp add_type({parsed, split_path}) when length(split_path) >= 2 do
    if Keyword.has_key?(parsed, :type) do
      {parsed, split_path}
    else
      {parsed ++ [type: Enum.at(split_path, 0)], split_path}
    end
  end
  defp add_type(value), do: value

  defp add_type_tree({parsed, split_path}) when length(split_path) > 2 do
      {parsed ++ [type_tree: Enum.slice(split_path, 0..-2)], split_path}
  end
  defp add_type_tree(value), do: value

  defp with_extras(options, parsed, path) do
    split_path = Path.split(String.replace(path, options.documents_location, ""))

    {parsed, split_path}
    |> add_slug()
    |> add_type()
    |> add_type_tree()
    |> elem(0)
  end
end
