# AshMock

A mock resource generator extension for Ash resources.

## Installation

Add `ash_mock` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash_mock, "~> 0.2.0"}
  ]
end
```

## Usage

AshMock provides a convenient way to generate mock resource for your Ash resources. Here's how to use it:

```elixir
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
```

### Example Test

```elixir
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
```

## Features

- Automatic mock resource generation for Ash resources
- Deep relationship mocking
- Customizable mock data patterns
- Random value generation using AshRandomParams (see https://github.com/devall-org/ash_random_params for more information)

## License

MIT