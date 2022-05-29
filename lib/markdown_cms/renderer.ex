defmodule MarkdownCMS.Renderer do
  @moduledoc """
  Documentation for `MarkdownCMS.Renderer`.
  """
  @default_root "templates"
  @default_template "default.html"

  import Phoenix.HTML, only: [raw: 1]

  def process(content_list) do
    for {key, content} <- content_list, into: "" do
      case get_template(key) do
        nil -> ""
        template -> Phoenix.View.render_to_string(view_module, template, item: raw(content))
      end
    end
    |> raw
  end

  def get_template(key) do
    templates = Application.get_env(:markdown_cms, :templates, %{})
    Map.get(templates, key, nil)
  end

  def view_module do
    MarkdownCMS.View
  end
  def view_modulex do
    Application.get_env(:markdown_cms, :view_module) ||
    raise """
    :view_module is not configured

    Set it in your app as:

    config :markdown_cms, view_module: YourPhoenixAppWeb.LayoutView
    """
  end

end
