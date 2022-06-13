defmodule MarkdownCMS.DataAgent do
  require Logger
	use Agent

  def start_link(_) do
    Agent.start_link(fn -> MarkdownCMS.DataSource.FileSystem.load() end, name: __MODULE__)
  end

  def all do
    Logger.debug("DataAgent providing data")
    Agent.get(__MODULE__, & &1)
  end

  def reload do
    Agent.update(__MODULE__, fn _ -> MarkdownCMS.DataSource.FileSystem.load() end)
  end
end
