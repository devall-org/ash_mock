# Rules for working with AshMock

## Understanding AshMock

AshMock automatically generates mock actions for Ash resources, making it easy to create test data with randomized values and relationships.

## Basic Usage

### Adding the Extension

```elixir
defmodule Post do
  use Ash.Resource, 
    domain: Domain, 
    data_layer: Ash.DataLayer.Ets, 
    extensions: [AshMock]

  attributes do
    uuid_primary_key :id
    attribute :title, :string, allow_nil?: false, public?: true
    attribute :tag, :string, allow_nil?: true, public?: true
  end

  relationships do
    belongs_to :author, Author, allow_nil?: false, public?: true
  end

  actions do
    defaults [:read, :destroy, create: :*, update: :*]
  end
end
```

Adding the extension automatically generates `:mock` and `:shallow_mock` actions.

### Using Mock Actions

```elixir
# Deep mock - automatically creates belongs_to relationships
post = Post |> Ash.Changeset.for_create(:mock) |> Ash.create!()
assert post.author.name |> String.starts_with?("name-")

# Shallow mock - relationships must be provided manually
author = Author |> Ash.Changeset.for_create(:shallow_mock) |> Ash.create!()
post = Post |> Ash.Changeset.for_create(:shallow_mock, %{author: author}) |> Ash.create!()
assert author.id == post.author_id
```

## Mock Configuration

Use the `mock` block for detailed configuration:

```elixir
mock do
  # Fields that must be randomized by AshRandomParams
  enforce_random [:email, :age]
  
  # Fields to exclude from mock generation
  exclude [:internal_id]
  
  # Add custom arguments to mock actions
  argument :type, :string
  
  # Changes applied before generating mock data
  pre_change relate_actor(:reporter)
  pre_change {MyCustomChange, :foo}
  
  # Changes applied after generating mock data
  post_change fn changeset, _context ->
    # Custom logic
    changeset
  end
end
```

## Testing Best Practices

- **Data layer**: Use `Ash.DataLayer.Ets` with `private? true` for test resources
- **Nil values**: Attributes with `allow_nil?: true` will be nil
- **Required values**: Attributes with `allow_nil?: false` get random values
- **Identity conflicts**: Include identity fields in `enforce_random` to avoid conflicts in concurrent tests

```elixir
# For resources with identity fields
mock do
  enforce_random [:email, :username]  # ensures unique values
end
```

## AshRandomParams Integration

AshMock uses [AshRandomParams](https://github.com/devall-org/ash_random_params) internally to generate random values. The `enforce_random` and `exclude` options are passed through to AshRandomParams.

