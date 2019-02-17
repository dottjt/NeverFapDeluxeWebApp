defmodule NfdWeb.AuthErrorHandler do
  use NfdWeb, :controller
  alias Plug.Conn

  @spec call(Conn.t(), atom()) :: Conn.t()
  def call(conn, :not_authenticated) do
    conn
    |> put_flash(:error, "You've to be authenticated first")
    |> redirect(to: Routes.registration_path(conn, :account))
  end

  @spec call(Conn.t(), atom()) :: Conn.t()
  def call(conn, :already_authenticated) do
    conn
    |> put_flash(:error, "You're already authenticated")
    |> redirect(to: Routes.page_path(conn, :hub))
  end
end

