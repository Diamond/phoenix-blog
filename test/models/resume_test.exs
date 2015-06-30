defmodule Pxblog.ResumeTest do
  use Pxblog.ModelCase

  alias Pxblog.Resume

  @valid_attrs %{body: "some content"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Resume.changeset(%Resume{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Resume.changeset(%Resume{}, @invalid_attrs)
    refute changeset.valid?
  end
end
