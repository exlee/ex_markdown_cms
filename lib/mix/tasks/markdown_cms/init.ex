defmodule Mix.Tasks.MarkdownCms.Init do
  @moduledoc "Initializes ModuleCMS.View"
  @shortdoc "Initializes ModuleCMS.View"

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    IO.inspect(File.cwd!)
    Mix.Generator.copy_file(Path.join(Mix.Project.deps_paths().markdown_cms, "source/view.ex"), "lib/markdown_cms/view.ex")
    Mix.Generator.copy_file(Path.join(Mix.Project.deps_paths().markdown_cms, "source/templates/default.html.heex"), "lib/markdown_cms/templates/default.html.heex")
  end
end
