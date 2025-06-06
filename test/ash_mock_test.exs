defmodule AshMockTest.Case do
  use ExUnit.Case, async: true

  alias __MODULE__.{Post, Author, Domain}

  defmodule Post do
    use Ash.Resource, domain: Domain, data_layer: Ash.DataLayer.Ets, extensions: [AshMock]

    ets do
      private? true
    end

    attributes do
      uuid_primary_key :id

      attribute :title, :string, allow_nil?: false, public?: true
      attribute :tag, :string, allow_nil?: true, public?: true
    end

    actions do
      defaults [:read, :destroy, create: :*, update: :*]
    end

    relationships do
      belongs_to :author, Author, allow_nil?: false, public?: true
    end
  end

  defmodule Author do
    use Ash.Resource, domain: Domain, data_layer: Ash.DataLayer.Ets, extensions: [AshMock]

    ets do
      private? true
    end

    attributes do
      uuid_primary_key :id

      attribute :name, :string, allow_nil?: false, public?: true
    end

    relationships do
      has_many :posts, Post, public?: true
    end

    actions do
      defaults [:read, :destroy, create: :*, update: :*]
    end
  end

  defmodule Domain do
    use Ash.Domain, validate_config_inclusion?: false

    resources do
      resource Post
      resource Author
    end
  end

  test "mock" do
    post = Post |> Ash.Changeset.for_create(:mock) |> Ash.create!()

    assert post.author.name |> String.starts_with?("name-")
    assert post.title |> String.starts_with?("title-")
    assert post.tag == nil
  end

  test "shallow_mock" do
    author = Author |> Ash.Changeset.for_create(:shallow_mock) |> Ash.create!()
    post = Post |> Ash.Changeset.for_create(:shallow_mock, %{author: author}) |> Ash.create!()

    assert author.id == post.author_id

    assert author.name |> String.starts_with?("name-")
    assert post.title |> String.starts_with?("title-")
    assert post.tag == nil
  end
end
