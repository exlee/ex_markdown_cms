defmodule MarkdownCMS.Renderer do
  @moduledoc """
  Documentation for `MarkdownCMS.Renderer`.
  """
  @default_template "default.html"

  import Phoenix.HTML, only: [raw: 1]

  def render(content_list) do
    for {key, content} <- content_list, into: "" do
      case get_template(key) do
        nil -> ""
        template -> Phoenix.View.render_to_string(MarkdownCMS.View, template, item: raw(content))
      end
    end
    |> raw
  end

  def get_template(key) do
    templates = Application.get_env(:markdown_cms, :templates, %{})
    Map.get(templates, key, nil)
  end

end
