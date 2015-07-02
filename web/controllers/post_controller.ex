defmodule Pxblog.PostController do
  use Pxblog.Web, :controller

  alias Pxblog.Post
  alias Pxblog.User

  plug :check_permissions when action in [:new, :create, :edit, :update]
  plug :scrub_params, "post" when action in [:create, :update]

  def index(conn, %{"user_id" => user_id}) do
    if Repo.get User, user_id do
      posts = user_id
      |> Post.for_user
      |> Repo.all
      render(conn, "index.html", posts: posts)
    else
      conn
      |> put_flash(:error, "Invalid user specified!")
      |> redirect(to: page_path(conn, :index))
    end
  end

  def index(conn, _params) do
    posts = Repo.all from p in Post,
      order_by: [desc: p.updated_at],
      preload: [:user]
    render(conn, "index.html", posts: posts)
  end

  def new(conn, _params) do
    changeset = Post.changeset(%Post{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"post" => post_params}) do
    new_post = build(get_session(conn, :current_user), :posts)
    changeset = Post.changeset(new_post, post_params)

    if changeset.valid? do
      Repo.insert(changeset)

      conn
      |> put_flash(:info, "Post created successfully.")
      |> redirect(to: post_path(conn, :index))
    else
      render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    post = Repo.get(Post, id) |> Repo.preload [:user]
    render(conn, "show.html", post: post)
  end

  def edit(conn, %{"id" => id}) do
    post = Repo.get(Post, id)
    changeset = Post.changeset(post)
    render(conn, "edit.html", post: post, changeset: changeset)
  end

  def update(conn, %{"id" => id, "post" => post_params}) do
    post = Repo.get(Post, id)
    changeset = Post.changeset(post, post_params)

    if changeset.valid? do
      Repo.update(changeset)

      conn
      |> put_flash(:info, "Post updated successfully.")
      |> redirect(to: post_path(conn, :index))
    else
      render(conn, "edit.html", post: post, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    post = Repo.get(Post, id)
    Repo.delete(post)

    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: post_path(conn, :index))
  end

  defp check_permissions(conn, _params) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to do that!")
      |> redirect(to: page_path(conn, :index))
      |> halt
    end
  end
end
