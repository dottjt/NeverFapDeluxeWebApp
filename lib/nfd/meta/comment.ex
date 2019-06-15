defmodule Nfd.Meta.Comment do
  # use Timex
  use Ecto.Schema
  import Ecto.Changeset
  
  alias Nfd.Account.User
  alias Nfd.Meta.Page

  alias Nfd.Meta.Page
  alias Nfd.Account.User
  alias Nfd.Account.Subscriber

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "comments" do
    field :depth, :integer
    field :name, :string
    field :email, :string
    field :message, :string
    
    # so the reason why this is a field and not a reference is because the foreign key is a id and not page_id
    # although ideally it would be a reference, I'm just not sure how to do this.
    field :page_id, :binary_id 

    belongs_to :parent_message, Nfd.Meta.Comment, foreign_key: :parent_message_id
    belongs_to :user, User, foreign_key: :user_id

    timestamps()
  end

  # TODO: I still need to figure this out, in terms of getting the parent_id into the changeset in a meaningful way.

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:depth, :email, :name, :message, :page_id])
    # |> cast_assoc(:parent_message, with: &Nfd.Meta.Comment.id_changeset/2)
    # |> cast_assoc(:user, with: &Nfd.Account.User.id_changeset/2)
    |> validate_required([:depth, :email, :name, :message, :page_id])
  end

  def id_changeset(comment, attrs) do
    comment
    |> cast(attrs, [:id])
  end

  def organise_comments(comments) do
    comments
      |> Enum.filter(fn (comment) -> !comment.parent_message_id end)
      |> Enum.reduce(
        %{parents: []},
        fn reduce_comment, acc ->
          children_comments = recursive_find_comments(comments, reduce_comment, acc)
          %{parents: acc.parents ++ [Map.put(reduce_comment, :children, children_comments)]}
        end)
  end

  defp recursive_find_comments(comments, reduce_comment, acc) do
    # Find the children of the comment
    reduce_comment_children = Enum.filter(comments, fn (filter_comment) -> filter_comment.parent_message_id == reduce_comment.id end)

    # if children then add them to current comment
    if reduce_comment_children do
      reduce_comment_children
        |> Enum.map(fn (comment_child) ->
          new_comment_child = Map.put(reduce_comment, :children, reduce_comment_children)
          recursive_find_comments(comments, new_comment_child, acc)
        end)
    # if not children, then just pass back to the
    else
      %{child: reduce_comment}
    end
  end

  # https://hexdocs.pm/timex/Timex.Format.DateTime.Formatters.Default.html
  def organise_date(comments) do
    comments 
      |> Enum.map(fn (comment) ->
        commentDate = Timex.format!(comment.inserted_at, "{Mfull} {D}, {YYYY}") <> " at " <> Timex.format!(comment.inserted_at, "{h24}:{m} {am}") 
        Map.merge(comment, %{
          inserted_at: commentDate
        })
      end)
  end
end

