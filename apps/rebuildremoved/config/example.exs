use Mix.Config

config :rebuildremoved,
  artifacts: [
    %{pipeline: "test", stage: "defaultStage", job: "defaultJob", paths: ["foo"]},
    %{pipeline: "consumer", stage: "defaultStage", job: "DefaultJob", paths: ["bla"]}
  ]

config :logger, level: :warn
