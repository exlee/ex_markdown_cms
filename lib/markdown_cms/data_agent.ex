defmodule MarkdownCMS.DataAgent do
  require Logger
	use Agent

  def start_link(_) do
    Agent.start_link(fn -> MarkdownCMS.Content.initialize_all() end, name: __MODULE__)
  end

  def all do
    Logger.info(".all call received")
    Agent.get(__MODULE__, & &1)
  end

  def reload do
    Agent.update(__MODULE__, fn _ -> MarkdownCMS.Content.initialize_all end)
  end
end
