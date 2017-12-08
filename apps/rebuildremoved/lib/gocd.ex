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
        |> trigger_if_necessary()
    end


    defp with_status(job_config = %{pipeline: pipeline}) do
        job_config
        |> Map.put(:status, status_of(pipeline))
    end


    defp trigger_if_necessary(job_config = %{pipeline: pipeline, stage: stage, job: job, paths: paths}) do
        artifacts = artifacts_of_latest_run(job_config)

        first_mising = paths
            |> Enum.find(&(!GoCDartifacts.contain(artifacts, &1)))

        first_mising |> trigger_if_missing(job_config)
    end

    defp trigger_if_missing(nil, _), do: true #nothing to do

    defp trigger_if_missing(artifact, job_config = %{pipeline: pipeline, stage: stage, job: job}) do
        Logger.warn "Artifact #{artifact} missing from #{pipeline}/#{stage}/#{job} -> triggering the pipeline"
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
