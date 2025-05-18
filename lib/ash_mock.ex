defmodule AshMock do
  defmodule PreChange do
    defstruct [:change, :on, :only_when_valid?, :description, :always_atomic?, where: []]
  end

  defmodule PostChange do
    defstruct [:change, :on, :only_when_valid?, :description, :always_atomic?, where: []]
  end

  @argument %Spark.Dsl.Entity{
    name: :argument,
    describe: """
    Declares an argument for the mock, mock_deep, and mock_new actions.
    """,
    examples: [
      "argument :password_confirmation, :string"
    ],
    target: Ash.Resource.Actions.Argument,
    args: [:name, :type],
    transform: {Ash.Type, :set_type_transformation, []},
    schema: Ash.Resource.Actions.Argument.schema()
  }

  @pre_change %Spark.Dsl.Entity{
    name: :pre_change,
    describe: """
    A change to be applied to the changeset before generating mock data.

    See `Ash.Resource.Change` for more details.
    """,
    examples: [
      "pre_change relate_actor(:reporter)",
      "pre_change {MyCustomChange, :foo}"
    ],
    no_depend_modules: [:change],
    target: PreChange,
    schema: Ash.Resource.Change.schema(),
    args: [:change]
  }

  @post_change %Spark.Dsl.Entity{
    name: :post_change,
    describe: """
    A change to be applied to the changeset after generating mock data.

    See `Ash.Resource.Change` for more details.
    """,
    examples: [
      "post_change relate_actor(:reporter)",
      "post_change {MyCustomChange, :foo}"
    ],
    no_depend_modules: [:change],
    target: PostChange,
    schema: Ash.Resource.Change.schema(),
    args: [:change]
  }

  @mock %Spark.Dsl.Section{
    name: :mock,
    describe: """
    Configuration settings for mock, mock_deep, and mock_new actions.
    Define arguments, changes, and other mock-related settings here.
    """,
    schema: [
      enforce_random: [
        type: {:wrap_list, :atom},
        required: false,
        default: [],
        doc: """
        Fields to be randomized by AshRandomParams.
        See `AshRandomParams` for more details.
        """
      ],
      exclude: [
        type: {:wrap_list, :atom},
        required: false,
        default: [],
        doc: """
        Fields to be excluded by AshRandomParams.
        See `AshRandomParams` for more details.
        """
      ],
      upsert_identity: [
        type: :atom,
        required: false,
        doc: """
        The identity to use when upserting records in the mock_new action.
        """
      ]
    ],
    imports: [
      Ash.Resource.Change.Builtins,
      Ash.Expr
    ],
    examples: [
      """
      mock do
        enforce_random [:email, :age]
        exclude [:name]
        upsert_identity :company_name

        argument :type, :string
        argument :content, :string

        pre_change relate_actor(:reporter)
        pre_change {MyCustomChange, :foo}

        post_change fn changeset, context ->
          # Your custom logic here
          changeset
        end
      end
      """
    ],
    entities: [
      @argument,
      @pre_change,
      @post_change
    ]
  }

  use Spark.Dsl.Extension,
    sections: [@mock],
    transformers: [AshMock.Transformer],
    add_extensions: [AshRandomParams]
end
