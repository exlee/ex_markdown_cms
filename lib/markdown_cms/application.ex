defmodule MarkdownCMS.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_, _) do
    children = [
      MarkdownCMS.DataAgent
    ]

    opts = [strategy: :one_for_one, name: MarkdownCMS.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
