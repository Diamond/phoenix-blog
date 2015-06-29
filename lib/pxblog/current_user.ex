defmodule Pxblog.CurrentUser do
  import Plug.Conn
  import Plug.Session

  def init(default), do: default

  def call(conn, _default) do
    current_user = get_session(conn, :current_user)
    if current_user do
      assign(conn, :current_user, current_user)
    else
      conn
    end
  end
end
