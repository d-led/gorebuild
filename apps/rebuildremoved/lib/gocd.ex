defmodule Gocd do
    require Logger
    use Tesla

    @gocd Application.get_env(:rebuildremoved, :gocd)


    plug Tesla.Middleware.BaseUrl, @gocd.url
    plug Tesla.Middleware.Tuples
    plug Tesla.Middleware.JSON

    # API

    def trigger_if_artifacts_missing(job_config) do
        job_config
        |> with_status()
        |> trigger_if_necessary()
    end


    # implementation


    defp with_status(job_config = %{pipeline: pipeline}) do
        job_config
        |> Map.put(:passed, passed(pipeline))
    end

    defp trigger_if_necessary(job_config = %{paths: paths, passed: true}) do
        case artifacts_of_latest_run(job_config) do
            nil -> false
            artifacts -> first_mising = paths
                         |> Enum.find(&(!GoCDartifacts.contain(artifacts, &1)))

                         first_mising |> trigger_if_missing(job_config)
        end
    end

    # don't trigger if not green
    defp trigger_if_necessary(%{pipeline: pipeline}) do
        Logger.info "not triggering #{pipeline}, as it is not green"
    end


    # if no artifacts returned from artifacts_of_latest_run
    defp trigger_if_missing(nil, _), do: true #nothing to do

    # https://api.gocd.org/current/#scheduling-pipelines
    defp trigger_if_missing(artifact, %{pipeline: pipeline, stage: stage, job: job}) do
        Logger.warn "Artifact #{artifact} missing from #{pipeline}/#{stage}/#{job} -> triggering the pipeline"

        case post("/api/pipelines/#{pipeline}/schedule",%{},headers: %{"Confirm" => "true"}) do
            { :error, %Tesla.Error{message: message} } -> Logger.error("Http error on #{pipeline}/#{stage}/#{job}: #{message}"); false
            _ -> true
        end
    end


    # https://api.gocd.org/current/#get-all-artifacts
    defp artifacts_of_latest_run(%{pipeline: pipeline, stage: stage, job: job}) do
        case get("/files"<>"/#{pipeline}"<>"/Latest"<>"/#{stage}"<>"/Latest"<>"/#{job}"<>".json") do
          { :ok, %Tesla.Env{body: files} } -> files
          { :error, %Tesla.Error{message: message} } -> Logger.error("Http error on #{pipeline}/#{stage}/#{job}: #{message}"); nil
        end
    end

    # https://api.gocd.org/current/#get-pipeline-history
    defp passed(pipeline) do
        case get("/api/pipelines/#{pipeline}/history") do
            { :ok, %Tesla.Env{body: status} } -> status |> last_run_passed()
            { :error, %Tesla.Error{message: message} } -> Logger.error("Http error on #{pipeline}: #{message}"); false
        end
    end

    defp last_run_passed( %{"pipelines"=>[last_pipeline|_rest]} ) do
        %{"stages"=>stages} = last_pipeline
        stages
        |> Enum.all?(fn stage -> Map.get(stage, "result") == "Passed" end)
    end

    def url, do: @gocd.url
end
