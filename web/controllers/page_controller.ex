defmodule Pxblog.PageController do
  use Pxblog.Web, :controller

  plug :action

  def index(conn, _params) do
    render conn, "index.html"
  end
end
