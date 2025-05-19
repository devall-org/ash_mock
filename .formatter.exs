spark_locals_without_parens = [
  allow_nil?: 1,
  always_atomic?: 1,
  argument: 2,
  argument: 3,
  constraints: 1,
  default: 1,
  description: 1,
  enforce_random: 1,
  exclude: 1,
  on: 1,
  only_when_valid?: 1,
  post_change: 1,
  post_change: 2,
  pre_change: 1,
  pre_change: 2,
  public?: 1,
  sensitive?: 1,
  where: 1
]

[
  import_deps: [:spark, :reactor, :ash, :ash_random_params],
  inputs: [
    "{mix,.formatter}.exs",
    "{config,lib,test}/**/*.{ex,exs}"
  ],
  plugins: [Spark.Formatter],
  locals_without_parens: spark_locals_without_parens,
  export: [
    locals_without_parens: spark_locals_without_parens
  ]
]
