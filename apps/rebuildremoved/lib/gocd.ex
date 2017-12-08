defmodule Gocd do
    require Logger
    use Tesla

    @gocd Application.get_env(:rebuildremoved, :gocd)


    plug Tesla.Middleware.BaseUrl, @gocd.url
    plug Tesla.Middleware.Tuples
    plug Tesla.Middleware.JSON

    # {:ok, %Tesla.Env{__client__: nil, __module__: Gocd, body: [%{"files" => [%{"name" => "config.exs", "type" => "file", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/config/config.exs"}], "name" => "config", "type" => "folder", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/config"}, %{"files" => [%{"name" => "console.log", "type" => "file", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/cruise-output/console.log"}, %{"name" => "md5.checksum", "type" => "file", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/cruise-output/md5.checksum"}], "name" => "cruise-output", "type" => "folder", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/cruise-output"}, %{"files" => [%{"files" => [%{"name" => "start.sh", "type" => "file", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/foo/bar/start.sh"}], "name" => "bar", "type" => "folder", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/foo/bar"}], "name" => "foo", "type" => "folder", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/foo"}] ...
    def get_artifacts_for(%{pipeline: pipeline, stage: stage, job: job}) do
        get("/files"<>"/#{pipeline}"<>"/Latest"<>"/#{stage}"<>"/Latest"<>"/#{job}"<>".json")
    end

    def get_artifacts do
        get("/files"<>"/test"<>"/Latest"<>"/defaultStage"<>"/Latest"<>"/defaultJob"<>".json")
    end

    def hi do
        Logger.info @gocd.url
        # Logger.info inspect(get_artifacts())
    end
end
