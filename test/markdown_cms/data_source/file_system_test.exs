defmodule MarkdownCMS.DataSource.FileSystemTest do
	use ExUnit.Case
  alias MarkdownCMS.DataSource.FileSystem, as: FileAgent

  def get_item(data, value, key \\ :slug) do
    data
      |> Enum.filter(fn item -> Keyword.get(item, key) == value end)
      |> List.first
  end

  test "loads for test_data" do
    result = FileAgent.start_link(documents_location: "test/sample_data/basic")
    assert elem(result, 0) == :ok
  end

  describe "with default configuration" do
    setup do
      {:ok, pid} = FileAgent.start_link(documents_location: "test/sample_data/basic")
      %{pid: pid, data: FileAgent.data(pid)}
    end


    test "infers type from directory", context do
      item = get_item(context.data, "static-sub-1")
      assert Keyword.get(item, :type) == "static"
    end

    test "prioritize type from parsed file content", context do
      item = get_item(context.data, "static-10")
      assert Keyword.get(item, :type) == "static"
    end
    test "infers slug from filenames", context do
      assert get_item(context.data, "guide-1")
    end

    test "priorityze slug from parsed file content", context do
      item = get_item(context.data, "Article 10", :title)
      assert Keyword.get(item, :slug) == "not-a-10-file"
    end

    test "it should have well formed test tree", context do
      item =  get_item(context.data, "static-sub-1")
      assert Keyword.get(item, :type_tree) == ["static", "subdir"]
    end

    test "it should add forward slash when missing in configuration", context do
      Agent.get(context.pid, fn state -> state.documents_location end)
      |> String.ends_with?("/")
    end

    test "it should parse tag content tag by default", context do
      item =  get_item(context.data, "guide-1")
      assert Keyword.get_values(item, :tag) == ["guide", "verified"]
    end

  end

  test "runs even if there are duplicate slugs" do
    {result, _pid} = FileAgent.start_link(documents_location: "test/sample_data/duplicate_slugs")
    assert result == :ok

  end
end
