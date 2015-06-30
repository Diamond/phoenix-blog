defmodule Pxblog.ResumeControllerTest do
  use Pxblog.ConnCase

  alias Pxblog.Resume
  @valid_attrs %{body: "some content"}
  @invalid_attrs %{}

  setup do
    conn = conn()
    {:ok, conn: conn}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, resume_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing resumes"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, resume_path(conn, :new)
    assert html_response(conn, 200) =~ "New resume"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, resume_path(conn, :create), resume: @valid_attrs
    assert redirected_to(conn) == resume_path(conn, :index)
    assert Repo.get_by(Resume, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, resume_path(conn, :create), resume: @invalid_attrs
    assert html_response(conn, 200) =~ "New resume"
  end

  test "shows chosen resource", %{conn: conn} do
    resume = Repo.insert %Resume{}
    conn = get conn, resume_path(conn, :show, resume)
    assert html_response(conn, 200) =~ "Show resume"
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    resume = Repo.insert %Resume{}
    conn = get conn, resume_path(conn, :edit, resume)
    assert html_response(conn, 200) =~ "Edit resume"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    resume = Repo.insert %Resume{}
    conn = put conn, resume_path(conn, :update, resume), resume: @valid_attrs
    assert redirected_to(conn) == resume_path(conn, :index)
    assert Repo.get_by(Resume, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    resume = Repo.insert %Resume{}
    conn = put conn, resume_path(conn, :update, resume), resume: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit resume"
  end

  test "deletes chosen resource", %{conn: conn} do
    resume = Repo.insert %Resume{}
    conn = delete conn, resume_path(conn, :delete, resume)
    assert redirected_to(conn) == resume_path(conn, :index)
    refute Repo.get(Resume, resume.id)
  end
end
