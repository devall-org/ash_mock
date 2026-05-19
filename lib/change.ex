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

    init_params = cs |> build_init_params()
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

  defp build_init_params(cs) do
    generated_attrs =
      cs.resource
      |> Ash.Resource.Info.attributes()
      |> Enum.filter(& &1.generated?)
      |> Enum.map(& &1.name)

    cs.attributes
    |> Map.drop(generated_attrs)
    |> Map.merge(cs.arguments)
  end

  defp change_belongs_toes(cs, belongs_toes, deep?, ash_opts) do
    belongs_toes
    |> Enum.reduce(
      cs,
      fn
        %BelongsTo{allow_nil?: true} = b, cs ->
          case cs |> Ash.Changeset.fetch_argument(b.name) do
            {:ok, parent} -> cs |> set_belongs_to(b, parent)
            :error -> cs
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
              cs |> set_belongs_to(b, parent)

            {:error, :error, false} ->
              cs

            {:error, :error, true} ->
              parent =
                b.destination
                |> Ash.Changeset.for_create(:mock, %{}, ash_opts)
                |> Ash.create!(ash_opts)

              cs
              |> Ash.Changeset.set_argument(b.name, parent)
              |> set_belongs_to(b, parent)
          end
      end
    )
  end

  # Set the FK directly and attach the parent as the loaded relationship via an
  # after_action hook. This mirrors how `Ash.Resource.Change.RelateActor` handles
  # belongs_to since ash 3.25.3, and avoids queuing a `manage_relationship`
  # instruction that could later overwrite the FK set by other changes
  # (e.g. resource-level `relate_actor`).
  defp set_belongs_to(cs, b, nil) do
    cs |> Ash.Changeset.change_attribute(b.source_attribute, nil)
  end

  defp set_belongs_to(cs, b, parent) do
    cs
    |> Ash.Changeset.change_attribute(b.source_attribute, parent.id)
    |> Ash.Changeset.after_action(fn _cs, record ->
      {:ok, record |> Map.put(b.name, parent)}
    end)
  end
end
