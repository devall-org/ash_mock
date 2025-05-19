defmodule AshMock.Transformer do
  use Spark.Dsl.Transformer

  alias Spark.Dsl.Transformer
  alias Ash.Resource.Builder
  alias Ash.Resource.Relationships.BelongsTo
  alias Ash.Resource.Attribute
  alias Ash.Resource.Actions.Argument

  def before?(AshCloak.Transformers.SetupEncryption), do: true
  def before?(_), do: false

  def after?(Ash.Resource.Transformers.BelongsToAttribute), do: true
  def after?(_), do: false

  def transform(dsl_state) do
    belongs_toes = dsl_state |> get_belongs_toes()
    reject = belongs_toes |> Enum.map(fn %BelongsTo{source_attribute: src} -> src end)

    attrs =
      dsl_state
      |> Transformer.get_entities([:attributes])
      |> Enum.filter(fn %Attribute{} = a ->
        a.writable? and a.name not in reject
      end)

    factory_args =
      dsl_state
      |> Transformer.get_entities([:mock])
      |> Enum.filter(fn
        %Argument{} -> true
        %{} -> false
      end)

    belongs_to_args = belongs_toes |> build_belongs_to_args()

    args = factory_args ++ belongs_to_args

    dsl_state
    |> add_action(
      :mock,
      {attrs, args},
      false
    )
    |> add_action(
      :mock_deep,
      {attrs, args},
      true
    )
    |> then(fn dsl_state -> {:ok, dsl_state} end)
  end

  defp add_action(
         dsl_state,
         action,
         {attrs, args},
         deep?
       ) do
    [pre_changes, post_changes] =
      [
        AshMock.PreChange,
        AshMock.PostChange
      ]
      |> Enum.map(fn change_type ->
        dsl_state
        |> Transformer.get_entities([:mock])
        |> Enum.flat_map(fn
          %^change_type{} = change -> [%{change | __struct__: Ash.Resource.Change}]
          _ -> []
        end)
      end)

    factory_change = %Ash.Resource.Change{change: {AshMock.Change, [deep?: deep?]}}
    changes = pre_changes ++ [factory_change] ++ post_changes

    dsl_state
    |> Builder.add_action(:create, action,
      accept: attrs |> Enum.map(& &1.name),
      arguments: args,
      changes: changes
    )
    |> Builder.add_interface(action)
    |> then(fn {:ok, dsl_state} -> dsl_state end)
  end

  defp get_belongs_toes(%{} = dsl_state) do
    multitenant_attr = dsl_state |> Transformer.get_option([:multitenancy], :attribute)

    dsl_state
    |> Transformer.get_entities([:relationships])
    |> Enum.filter(fn
      %BelongsTo{source_attribute: source_attribute} -> source_attribute != multitenant_attr
      %{} -> false
    end)
  end

  defp build_belongs_to_args(belongs_toes) do
    belongs_toes
    |> Enum.map(fn %BelongsTo{} = b ->
      Builder.build_action_argument(b.name, :struct,
        default: nil,
        constraints: [
          instance_of: b.destination
        ]
      )
    end)
    |> Enum.map(fn {:ok, arg} -> arg end)
  end
end
