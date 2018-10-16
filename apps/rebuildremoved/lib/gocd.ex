defmodule Gocd do
    require Logger
    use Tesla

    @gocd Application.get_env(:rebuildremoved, :gocd)


    plug Tesla.Middleware.BaseUrl, @gocd.url
    plug Tesla.Middleware.JSON, engine: Poison

    # API

    def start do
        Logger.warn "Starting to poll #{@gocd.url}"
        if authentication_provided?() do
            Logger.warn "Authenticating as user: #{@gocd.user}"
        end
    end


    def trigger_if_artifacts_missing(job_config) do
        job_config
        |> with_status()
        |> missing_artifact?()
        |> trigger_if_necessary()
    end


    # implementation


    defp with_status(job_config = %{pipeline: pipeline}) do
        job_config
        |> Map.put(:status, status_of(pipeline))
    end


    defp missing_artifact?(job_config = %{paths: paths, status: %{should_run: true}}) do
        case artifacts_of_latest_run(job_config) do
            nil ->
                job_config |> Map.put(:missing_artifact, nil)

            artifacts
                -> job_config
                    |> Map.put(:missing_artifact,
                        paths |> Enum.find(&(!GoCDartifacts.contain(artifacts, &1)))
                    )

        end
    end

    # must have been an error upstream
    defp missing_artifact?(job_config = %{}), do: job_config |> Map.put(:missing_artifact, nil)



    defp trigger_if_necessary(%{missing_artifact: nil}), do: true #nothing to do

    defp trigger_if_necessary(job_config = %{missing_artifact: artifact, status: %{should_run: true, can_run: true}}) do
        artifact |> trigger(job_config)
    end

    defp trigger_if_necessary(%{pipeline: pipeline, status: %{should_run: true, can_run: false}}) do
        Logger.warn "not triggering #{pipeline}, as it currently cannot be scheduled"
    end

    # don't trigger if not green
    defp trigger_if_necessary(%{pipeline: pipeline}) do
        Logger.warn "not triggering #{pipeline}, as the last run of the pipeine is not green"
    end

    defp status_of(pipeline) do
        case schedulable_and_unpaused?(pipeline) do
            %{can_run: true} -> last_run_ok?(pipeline)
            _ -> %{can_run: false}
        end
    end

    # GoCD API calls


    # https://api.gocd.org/current/#scheduling-pipelines
    defp trigger(artifact, %{pipeline: pipeline, stage: stage, job: job}) do
        Logger.warn "Artifact #{artifact} missing from #{pipeline}/#{stage}/#{job} -> triggering the pipeline #{@gocd.url}/tab/pipeline/history/#{pipeline}"

        case post(client(true, [{"Accept", "application/vnd.go.cd.v1+json"}]), "/api/pipelines/#{pipeline}/schedule", %{}) do
            { :ok, %Tesla.Env{ body: body } } -> Logger.warn("Pipeline '#{pipeline}': #{String.trim(body)}"); false
            { status, _} -> Logger.warn("Pipeline '#{pipeline}': #{inspect(status)}"); true
        end
    end



    # https://api.gocd.org/current/#get-all-artifacts
    defp artifacts_of_latest_run(%{pipeline: pipeline, stage: stage, job: job}) do
        case get(client(), "/files"<>"/#{pipeline}"<>"/Latest"<>"/#{stage}"<>"/Latest"<>"/#{job}"<>".json") do
          { :ok, %Tesla.Env{body: files} } -> files
        end
    end

    # https://api.gocd.org/current/#get-pipeline-history
    defp last_run_ok?(pipeline) do
        try do
            case get(client(), "/api/pipelines/#{pipeline}/history") do
                { :ok, %Tesla.Env{body: status} } ->
                    status |> last_run()
            end
        rescue
            e ->
                Logger.error("last_run_ok?: Error querying pipeline #{pipeline}: #{inspect(e)}")
                %{can_run: false}
        end
    end

    # https://api.gocd.org/current/#get-pipeline-status
    defp schedulable_and_unpaused?(pipeline) do
        try do
            case get(client(), "/api/pipelines/#{pipeline}/status") do
                { :ok, %Tesla.Env{body: %{"schedulable"=>true, "paused"=>false} } } ->
                    %{can_run: true}

                { :ok, %Tesla.Env{body: %{"schedulable"=>schedulable, "paused"=>paused} } } ->
                    Logger.info("Skipping pipeline #{pipeline}, as it's schedulable: #{schedulable}, paused: #{paused}")
                    %{can_run: false}
            end
        rescue
            e ->
                Logger.error("schedulable_and_unpaused?: Error querying pipeline #{pipeline}: #{inspect(e)}")
                %{can_run: false}
        end
    end

    defp last_run( %{"pipelines"=>[_last_pipeline = %{"stages"=>stages, "can_run"=>can_run} | _rest]} ) do
        %{
            should_run: stages |> Enum.all?(fn stage -> Map.get(stage, "result") == "Passed" end),
            can_run: can_run
        }
    end

    defp last_run(response) when is_binary(response) do
        Logger.warn "Unexpected response: #{String.slice(response, 0, 15)}..."
        %{can_run: false}
    end


    # REST client configuration


    defp client(confirm \\ false, header_list \\ []) do
        if authentication_provided?() do
            Tesla.build_client(
                [{Tesla.Middleware.BasicAuth, Map.merge(%{username: @gocd.user, password: @gocd.password}, %{})}]
                ++
                headers(confirm, header_list)
            )
        else
            Tesla.build_client(headers(confirm, header_list))
        end
    end

    defp headers(false, _), do: []
    defp headers(true, []), do: [{Tesla.Middleware.Headers, [{"Confirm", "true" }]}]
    defp headers(true, headers), do: [{Tesla.Middleware.Headers, [{"Confirm", "true" }]++headers}]

    defp authentication_provided? do
        @gocd.password != nil && @gocd.user != nil
    end

end
