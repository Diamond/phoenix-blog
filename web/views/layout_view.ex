defmodule Pxblog.LayoutView do
  use Pxblog.Web, :view

  def current_user(conn) do
    conn.assigns[:current_user]
  end
end
