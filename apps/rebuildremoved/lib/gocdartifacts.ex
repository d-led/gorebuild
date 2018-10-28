# Queries on GoCD Pipeline Artifacts as returned from the API Call
# https://api.gocd.org/current/#get-all-artifacts

defmodule GoCDartifacts do
  # traverse the list of artifacts, whether they contain the desired path
  def contain([artifact = %{} | rest], path), do: contain(artifact, path) || contain(rest, path)

  # single artifact check
  def contain(artifact = %{}, path), do: artifact |> contain_(String.split(path, "/", trim: true))

  # no match
  def contain(_, _), do: false

  # matching the artifact name exactly
  defp contain_(%{"name" => name}, [name]), do: true

  # match files in artifact subfolders
  defp contain_(%{"name" => dir, "type" => "folder", "files" => files}, [dir | path]) do
    files |> Enum.any?(&contain_(&1, path))
  end

  # no match
  defp contain_(_artifact, _path), do: false
end
