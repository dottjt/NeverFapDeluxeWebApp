defmodule NfdWeb.RegistrationController do
  use NfdWeb, :controller

  def index(conn, _params) do
    # user = Pow.Plug.current_user()

    # if user do

    # end

    conn 
      |> redirect(to: Routes.registration_path(conn, :account))
  end

  def account(conn, _params) do

    IO.puts('woah')

    changeset = Pow.Plug.change_user(conn)

    render(conn, "account.html", changeset: changeset)
  end

  def new(conn, _params) do
    # We'll leverage `Pow.Plug`, but you can also follow the classic Phoenix way:
    # changeset = MyApp.Users.User.changeset(%MyApp.Users.User{}, %{})

    changeset = Pow.Plug.change_user(conn)

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    # We'll leverage `Pow.Plug`, but you can also follow the classic Phoenix way:
    # user =
    #   %MyApp.Users.User{}
    #   |> MyApp.Users.User.changeset(user_params)
    #   |> MyApp.Repo.insert()

    conn
    |> Pow.Plug.create_user(user_params)
    |> case do
      {:ok, user, conn} ->
        conn
        |> put_flash(:info, "Welcome!")
        |> redirect(to: Routes.page_path(conn, :hub))

      {:error, changeset, conn} ->
        render(conn, "account.html", changeset: changeset)
    end
  end
end
