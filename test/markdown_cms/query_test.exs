defmodule MarkdownCMS.QueryTest do
  use ExUnit.Case

  def sample_data() do
    [
      [content: "Content", title: "Title A", category: "Category A", slug: "a"],
      [content: "Content", title: "Title B", category: "Category B"],
      [content: "Content", title: "Title C", category: "Category A", slug: "c"],
      [content: "Content", title: "Title D", category: "Category B"],
      [content: "Content", title: "Title E", category: "Category A"],
      [content: "Content", title: "Title F", category: "Category C", slug: "duplicate-slug"],
      [content: "Content", title: "Title G", category: "Category C", slug: "duplicate-slug"],

    ]
  end

  defmodule Query do
    use MarkdownCMS.Inner.Query,
      data_source: MarkdownCMS.QueryTest.sample_data(),
      id_field: :slug
  end

  test "all should return all data" do
    assert Query.all() == sample_data()
  end

  test "find should return existing item" do
    assert Query.find(title: "Title D") ==
      [content: "Content", title: "Title D", category: "Category B"]

  end

  test "find should return only one item even if many exist" do
    assert Query.find(category: "Category A") ==
      [content: "Content", title: "Title A", category: "Category A", slug: "a"]
  end

  test "find should return nil when data is found" do
    assert Query.find(slug: "unknown") == nil
  end

  test "get! should raise when data is not found" do
    assert_raise RuntimeError, fn ->
      Query.get!("unknown")
    end
  end

  test "get! with existing id should return" do
    assert Query.get!("c") ==
      [content: "Content", title: "Title C", category: "Category A", slug: "c"]
  end

  test "get should not raise when data is not found" do
    assert Query.get("unknown") == {:error, :not_found}
  end

  test "get with existing id should return wrapped in {:ok, _}" do
    assert Query.get("c") == {:ok, [content: "Content", title: "Title C", category: "Category A", slug: "c"]}
  end

  test "get returning multiple queries should return an error" do
    assert Query.get("duplicate-slug") == {:error, :multiple_found}
  end

  test "get! returning multiple queries should raise" do
    assert_raise RuntimeError, fn ->
      Query.get!("duplicate-slug") == {:error, :multiple_found}
    end
  end

end
