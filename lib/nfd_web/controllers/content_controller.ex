defmodule NfdWeb.ContentController do
  use NfdWeb, :controller
  use Timex
  
  alias Nfd.Redirects

  alias Nfd.API
  alias Nfd.API.Content

  alias Nfd.Meta
  alias Nfd.Account.Subscriber

  
  plug :put_layout, "general.html"

  def articles(conn, _params) do
    page_type = "page"
    client = API.is_localhost(conn.host) |> API.api_client()

    case client |> Content.articles() do
      {:ok, response} ->
        Meta.increment_visit_count(response.body["data"])
        conn |> render("articles.html", item: response.body["data"], articles: response.body["data"]["articles"] |> Enum.reverse(), page_type: page_type)
      {:error, _error} ->
        render_404_page(conn)
    end
  end

  def article(conn, %{"slug" => slug}) do
    page_type = "content"
    client = API.is_localhost(conn.host) |> API.api_client()

    verified_slug = Redirects.redirect(conn, slug, "article")

    case client |> Content.article(verified_slug) do
      {:ok, response} ->
        check_api_response_for_404(conn, response.status)
        Meta.increment_visit_count(response.body["data"])
        # TODO: Check condition if date is below/in front of
        if response.body["data"]["draft"] == false do 
          {:ok, articlesResponse} = client |> Content.articles()

          comments = Meta.list_collection_access_by_page_id(response.body["data"]["page_id"])
          comment_form_changeset = Meta.Comment.changeset(%Meta.Comment{}, %{})

          { previousArticle, nextArticle } = getPreviousNextArticle(articlesResponse.body["data"]["articles"] |> Enum.reverse(), response.body["data"]);
          seven_day_kickstarter_changeset = Subscriber.changeset(%Subscriber{}, %{})

          conn |> render("article.html", item: response.body["data"], articles: articlesResponse.body["data"]["articles"] |> Enum.reverse(), seven_day_kickstarter_changeset: seven_day_kickstarter_changeset, previousArticle: previousArticle, nextArticle: nextArticle, page_type: page_type, comments: comments, comment_form_changeset: comment_form_changeset)  
        else 
          render_404_page(conn)
        end
      {:error, _error} ->
        render_404_page(conn)
    end
  end

  def practices(conn, _params) do
    page_type = "page"
    client = API.is_localhost(conn.host) |> API.api_client()

    case client |> Content.practices() do
      {:ok, response} ->
        Meta.increment_visit_count(response.body["data"])
        conn |> render("practices.html", item: response.body["data"], practices: response.body["data"]["practices"] |> Enum.reverse(), page_type: page_type)
      {:error, _error} ->
        render_404_page(conn)
    end
  end

  def practice(conn, %{"slug" => slug}) do
    page_type = "content"
    client = API.is_localhost(conn.host) |> API.api_client()

    verified_slug = Redirects.redirect(conn, slug, "practice")

    case client |> Content.practice(verified_slug) do
      {:ok, response} ->
        check_api_response_for_404(conn, response.status)
        Meta.increment_visit_count(response.body["data"])
        if response.body["data"]["draft"] == false do 
          {:ok, articlesResponse} = client |> Content.articles()
          {:ok, practicesResponse} = client |> Content.practices()

          { previousArticle, nextArticle } = getPreviousNextArticle(practicesResponse.body["data"]["practices"] |> Enum.reverse(), response.body["data"]);
          seven_day_kickstarter_changeset = Subscriber.changeset(%Subscriber{}, %{})
          
          conn |> render("practice.html", item: response.body["data"], articles: articlesResponse.body["data"]["articles"] |> Enum.reverse(), practices: practicesResponse.body["data"]["practices"] |> Enum.reverse(), seven_day_kickstarter_changeset: seven_day_kickstarter_changeset, previousArticle: previousArticle, nextArticle: nextArticle, page_type: page_type)
        else
          render_404_page(conn)
        end
      {:error, _error} ->
        render_404_page(conn)
    end
  end

  def courses(conn, _params) do
    page_type = "page"
    client = API.is_localhost(conn.host) |> API.api_client()

    case client |> Content.courses() do
      {:ok, response} ->
        Meta.increment_visit_count(response.body["data"])
        conn |> render("courses.html", item: response.body["data"], courses: response.body["data"]["courses"] |> Enum.reverse(), page_type: page_type)
      {:error, _error} ->
        render_404_page(conn)
    end
  end

  def course(conn, %{"slug" => slug}) do
    page_type = "content"
    client = API.is_localhost(conn.host) |> API.api_client()

    verified_slug = Redirects.redirect(conn, slug, "course")

    case client |> Content.course(verified_slug) do
      {:ok, response} ->
        check_api_response_for_404(conn, response.status)
        Meta.increment_visit_count(response.body["data"])
        if response.body["data"]["draft"] == false do 
          {:ok, articlesResponse} = client |> Content.articles()
          {:ok, practicesResponse} = client |> Content.practices()
          conn |> render("course.html", item: response.body["data"], articles: articlesResponse.body["data"]["articles"] |> Enum.reverse(), practices: practicesResponse.body["data"]["practices"] |> Enum.reverse(), page_type: page_type)
        else
          render_404_page(conn)
        end
      {:error, _error} ->
          render_404_page(conn)
    end
  end

  def podcasts(conn, _params) do
    page_type = "page"
    client = API.is_localhost(conn.host) |> API.api_client()

    case client |> Content.podcasts() do
      {:ok, response} ->
        Meta.increment_visit_count(response.body["data"])
        conn |> render("podcasts.html", item: response.body["data"], podcasts: response.body["data"]["podcasts"] |> Enum.reverse(), page_type: page_type)
      {:error, _error} ->
        render_404_page(conn)
    end
  end

  def podcast(conn, %{"slug" => slug}) do
    page_type = "content"
    client = API.is_localhost(conn.host) |> API.api_client()

    verified_slug = Redirects.redirect(conn, slug, "podcast")

    case client |> Content.podcast(verified_slug) do
      {:ok, response} ->
        check_api_response_for_404(conn, response.status)
        Meta.increment_visit_count(response.body["data"])
        {:ok, podcastsResponse} = client |> Content.podcasts()
        { previousArticle, nextArticle } = getPreviousNextArticle(podcastsResponse.body["data"]["podcasts"] |> Enum.reverse(), response.body["data"]);

        if response.body["data"]["draft"] == false do 
          conn |> render("podcast.html", item: response.body["data"], page_type: page_type, previousArticle: previousArticle, nextArticle: nextArticle)
        else 
          render_404_page(conn)
        end
      {:error, _error} ->
        render_404_page(conn)
    end
  end

  def quotes(conn, _params) do
    page_type = "page"
    client = API.is_localhost(conn.host) |> API.api_client()

    case client |> Content.quotes() do
      {:ok, response} ->
        check_api_response_for_404(conn, response.status)
        Meta.increment_visit_count(response.body["data"])
        conn |> render("quotes.html", item: response.body["data"], items: response.body["data"]["quotes"], page_type: page_type)
      {:error, error} ->
        render_404_page(conn)
    end
  end

  def quote(conn, %{"slug" => slug}) do
    page_type = "content"
    client = API.is_localhost(conn.host) |> API.api_client()

    verified_slug = Redirects.redirect(conn, slug, "quote")

    case client |> Content.quote(verified_slug) do
      {:ok, response} ->
        check_api_response_for_404(conn, response.status)
        Meta.increment_visit_count(response.body["data"])
        # {:ok, dt} = Timex.parse(response.body["data"]["date"], "{ISO:Extended:Z}")
        # Okay, I just realised that we don't need to check time, because netlify won't bulid posts with a date set to the future :D
        {:ok, quotesResponse} = client |> Content.quotes()

        { previousArticle, nextArticle } = getPreviousNextArticle(quotesResponse.body["data"]["quotes"] |> Enum.reverse(), response.body["data"]);

        if response.body["data"]["draft"] == false do 
          conn |> render("quote.html", item: response.body["data"], previousArticle: previousArticle, nextArticle: nextArticle, page_type: page_type)
        else
          render_404_page(conn)
        end
      {:error, _error} ->
        render_404_page(conn)
    end
  end


  def meditations(conn, _params) do
    page_type = "page"
    client = API.is_localhost(conn.host) |> API.api_client()

    case client |> Content.meditations() do
      {:ok, response} ->
        Meta.increment_visit_count(response.body["data"])    
        conn |> render("meditations.html", item: response.body["data"], meditations: response.body["data"]["meditations"] |> Enum.reverse(), page_type: page_type)
      {:error, _error} ->
        render_404_page(conn)
    end
  end

  def meditation(conn, %{"slug" => slug}) do
    page_type = "content"
    client = API.is_localhost(conn.host) |> API.api_client()

    verified_slug = Redirects.redirect(conn, slug, "meditation")

    case client |> Content.meditation(verified_slug) do
      {:ok, response} ->
        check_api_response_for_404(conn, response.status)
        Meta.increment_visit_count(response.body["data"])
        {:ok, meditationsResponse} = client |> Content.meditations()
        { previousArticle, nextArticle } = getPreviousNextArticle(meditationsResponse.body["data"]["meditations"] |> Enum.reverse(), response.body["data"]);

        if response.body["data"]["draft"] == false do 
          conn |> render("meditation.html", item: response.body["data"], previousArticle: previousArticle, nextArticle: nextArticle, page_type: page_type)
        else 
          render_404_page(conn)
        end
      {:error, _error} ->
        render_404_page(conn)
    end
  end


  def blogs(conn, _params) do
    page_type = "page"
    client = API.is_localhost(conn.host) |> API.api_client()

    case client |> Content.blogs() do
      {:ok, response} ->
        Meta.increment_visit_count(response.body["data"])    
        conn |> render("blogs.html", item: response.body["data"], blogs: response.body["data"]["blogs"] |> Enum.reverse(), page_type: page_type)
      {:error, _error} ->
        render_404_page(conn)
    end
  end

  def blog(conn, %{"slug" => slug}) do
    page_type = "content"
    client = API.is_localhost(conn.host) |> API.api_client()

    verified_slug = Redirects.redirect(conn, slug, "blog")

    case client |> Content.blog(verified_slug) do
      {:ok, response} ->
        check_api_response_for_404(conn, response.status)
        Meta.increment_visit_count(response.body["data"])
        {:ok, blogsResponse} = client |> Content.blogs()
        { previousArticle, nextArticle } = getPreviousNextArticle(blogsResponse.body["data"]["blogs"] |> Enum.reverse(), response.body["data"]);

        if response.body["data"]["draft"] == false do 
          conn |> render("blog.html", item: response.body["data"], previousArticle: previousArticle, nextArticle: nextArticle, page_type: page_type)
        else 
          render_404_page(conn)
        end
      {:error, _error} ->
        render_404_page(conn)
    end
  end

  def updates(conn, _params) do
    page_type = "page"
    client = API.is_localhost(conn.host) |> API.api_client()

    case client |> Content.updates() do
      {:ok, response} ->
        Meta.increment_visit_count(response.body["data"])    
        conn |> render("updates.html", item: response.body["data"], updates: response.body["data"]["updates"] |> Enum.reverse(), page_type: page_type)
      {:error, _error} ->
        render_404_page(conn)
    end
  end

  def update(conn, %{"slug" => slug}) do
    page_type = "content"
    client = API.is_localhost(conn.host) |> API.api_client()

    verified_slug = Redirects.redirect(conn, slug, "update")

    case client |> Content.update(verified_slug) do
      {:ok, response} ->
        check_api_response_for_404(conn, response.status)
        Meta.increment_visit_count(response.body["data"])
        {:ok, updatesResponse} = client |> Content.updates()
        { previousArticle, nextArticle } = getPreviousNextArticle(updatesResponse.body["data"]["updates"] |> Enum.reverse(), response.body["data"]);

        if response.body["data"]["draft"] == false do 
          conn |> render("update.html", item: response.body["data"], previousArticle: previousArticle, nextArticle: nextArticle, page_type: page_type)
        else 
          render_404_page(conn)
        end
      {:error, _error} ->
        render_404_page(conn)
    end
  end

  defp check_api_response_for_404(conn, status) do
    if status != 200, do: render_404_page(conn)
  end

  defp render_404_page(conn) do 
    conn 
      |> put_view(NfdWeb.ErrorView)
      |> render("404.html")
  end

  defp getPreviousNextArticle(articles, currentArticle) do
    articleValues = 
      Enum.reduce(articles, %{last: nil, values: [], correct: false, previousArticle: nil, nextArticle: nil}, fn article, acc ->
        if acc.correct do
          %{last: article, previousArticle: acc.previousArticle, nextArticle: article, correct: false }
        else  
          if currentArticle["slug"] == article["slug"] do 
            %{last: article, previousArticle: acc.last, nextArticle: nil, correct: true }
          else 
            %{last: article, previousArticle: acc.previousArticle, nextArticle: acc.nextArticle, correct: false}
          end
        end
      end)
      
    { articleValues.previousArticle, articleValues.nextArticle }
  end
end
