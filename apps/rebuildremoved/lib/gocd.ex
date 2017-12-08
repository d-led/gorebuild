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
        # todo: ensure, only if not running already and not failed
        job_config
        |> Map.put(:status, status_of(pipeline))
    end


    defp trigger_if_necessary(job_config = %{paths: paths}) do
        artifacts = artifacts_of_latest_run(job_config)

        first_mising = paths
            |> Enum.find(&(!GoCDartifacts.contain(artifacts, &1)))

        first_mising |> trigger_if_missing(job_config)
    end

    defp trigger_if_missing(nil, _), do: true #nothing to do

    defp trigger_if_missing(artifact, %{pipeline: pipeline, stage: stage, job: job}) do
        Logger.warn "Artifact #{artifact} missing from #{pipeline}/#{stage}/#{job} -> triggering the pipeline"

        post("/api/pipelines/#{pipeline}/schedule",%{},headers: %{"Confirm" => "true"}) |> IO.inspect
    end

    # implementation

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
