defmodule Gocd do
    require Logger
    use Tesla

    @gocd Application.get_env(:rebuildremoved, :gocd)


    plug Tesla.Middleware.BaseUrl, @gocd.url
    plug Tesla.Middleware.Tuples
    plug Tesla.Middleware.JSON

    def trigger_if_artifacts_missing(job_config) do
        job_config
        |> with_status()
        |> trigger_if_green()
    end


    defp with_status(job_config = %{pipeline: pipeline}) do
        job_config
        |> Map.put(:status, status_of(pipeline))
    end


    defp trigger_if_green(job_config = %{pipeline: pipeline, stage: stage, job: job, paths: paths}) do
        job_config
        |> artifacts_of_latest_run() 
        |> IO.inspect
        #api/pipelines/pipeline1/status
    end

    # implementation

    # {:ok, %Tesla.Env{__client__: nil, __module__: Gocd, body: [%{"files" => [%{"name" => "config.exs", "type" => "file", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/config/config.exs"}], "name" => "config", "type" => "folder", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/config"}, %{"files" => [%{"name" => "console.log", "type" => "file", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/cruise-output/console.log"}, %{"name" => "md5.checksum", "type" => "file", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/cruise-output/md5.checksum"}], "name" => "cruise-output", "type" => "folder", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/cruise-output"}, %{"files" => [%{"files" => [%{"name" => "start.sh", "type" => "file", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/foo/bar/start.sh"}], "name" => "bar", "type" => "folder", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/foo/bar"}], "name" => "foo", "type" => "folder", "url" => "https://localhost:8154/go/files/test/1/defaultStage/1/defaultJob/foo"}] ...
    defp artifacts_of_latest_run(%{pipeline: pipeline, stage: stage, job: job}) do
        { :ok, %Tesla.Env{body: files} } = get("/files"<>"/#{pipeline}"<>"/Latest"<>"/#{stage}"<>"/Latest"<>"/#{job}"<>".json")
        files
    end

    defp status_of(pipeline) do
        { :ok, %Tesla.Env{body: status} } = get("/api/pipelines/#{pipeline}/status")
        
        status
    end

    def hi do
        Logger.info @gocd.url
    end
end
