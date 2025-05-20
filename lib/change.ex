defmodule AshMock.Change do
  use Ash.Resource.Change

  alias Ash.Resource.Relationships.BelongsTo

  def change(%Ash.Changeset{} = cs, [deep?: deep?], ctx) do
    ash_opts = ctx |> Ash.Context.to_opts()
    tenant_attr = Ash.Resource.Info.multitenancy_attribute(cs.resource)

    belongs_toes =
      cs.resource
      |> Ash.Resource.Info.relationships()
      |> Enum.filter(fn
        %BelongsTo{source_attribute: src_attr} -> src_attr != tenant_attr
        _ -> false
      end)

    init_params = Map.merge(cs.attributes, cs.arguments)
    enforce_random = AshMock.Info.mock_enforce_random!(cs.resource)
    exclude = AshMock.Info.mock_exclude!(cs.resource)

    random_params =
      cs.resource
      |> Ash.ActionInput.for_action(
        :random_params,
        %{
          action: cs.action.name,
          init_params: init_params,
          enforce_random: enforce_random,
          exclude: exclude,
          include_defaults?: false
        },
        ash_opts
      )
      |> Ash.run_action!(ash_opts |> Keyword.put(:authorize?, false))

    attr_names = cs.resource |> Ash.Resource.Info.attributes() |> Enum.map(& &1.name)

    {random_attrs, random_args} =
      random_params |> Enum.split_with(fn {k, _} -> k in attr_names end)

    cs
    |> Ash.Changeset.change_attributes(random_attrs)
    |> Ash.Changeset.set_arguments(random_args)
    |> change_belongs_toes(belongs_toes, deep?, ash_opts)
  end

  defp change_belongs_toes(cs, belongs_toes, deep?, ash_opts) do
    belongs_toes
    |> Enum.reduce(
      cs,
      fn
        %BelongsTo{allow_nil?: true} = b, cs ->
          case cs |> Ash.Changeset.fetch_argument(b.name) do
            {:ok, parent} ->
              cs
              |> Ash.Changeset.manage_relationship(b.name, parent, type: :append_and_remove)
              |> Ash.Changeset.change_attribute(b.source_attribute, parent && parent.id)

            :error ->
              cs
          end

        %BelongsTo{allow_nil?: false} = b, cs ->
          # source_attribute is included in reject, so it cannot be passed when calling mock,
          # but it can be set in pre_change.
          parent_id = cs |> Ash.Changeset.fetch_change(b.source_attribute)

          parent =
            cs
            |> Ash.Changeset.fetch_argument(b.name)
            |> then(fn
              {:ok, nil} -> :error
              {:ok, parent} -> {:ok, parent}
              :error -> :error
            end)

          case {parent_id, parent, deep?} do
            {{:ok, _change}, _, _} ->
              cs

            {:error, {:ok, parent}, _} ->
              cs
              |> Ash.Changeset.manage_relationship(b.name, parent, type: :append_and_remove)
              |> Ash.Changeset.change_attribute(b.source_attribute, parent && parent.id)

            {:error, :error, false} ->
              cs

            {:error, :error, true} ->
              parent =
                b.destination
                |> Ash.Changeset.for_create(:mock, %{}, ash_opts)
                |> Ash.create!(ash_opts)

              cs
              |> Ash.Changeset.set_argument(b.name, parent)
              |> Ash.Changeset.manage_relationship(b.name, parent, type: :append_and_remove)
              |> Ash.Changeset.change_attribute(b.source_attribute, parent.id)
          end
      end
    )
  end
end
