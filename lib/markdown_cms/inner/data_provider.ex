defmodule MarkdownCMS.Inner.DataProvider do
  @doc "Returns data store"
  @callback load() :: [Keyword.t]
end
