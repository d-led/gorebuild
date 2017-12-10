use Mix.Config

config :rebuildremoved,
    artifacts: [
        %{pipeline: "test", stage: "defaultStage", job: "defaultJob",
            paths: [
                "foo/bar",
                "foo/bar/start.sh"
            ]
        },
        %{pipeline: "consumer", stage: "defaultStage", job: "DefaultJob",
            paths: [ "bla/blup" ]
        }
    ]
