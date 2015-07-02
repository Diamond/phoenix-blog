defmodule Pxblog.PageController do
  use Pxblog.Web, :controller

  def index(conn, _params) do
    posts = Repo.all from p in Pxblog.Post,
            limit: 5,
            order_by: [desc: p.updated_at],
            select: p,
            preload: [:user]
    render conn, "index.html", posts: posts
  end
end
