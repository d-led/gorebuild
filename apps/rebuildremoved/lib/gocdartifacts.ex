defmodule GoCDartifacts do
   def contain([artifact = %{} | rest], path), do: contain(artifact, path) || contain(rest, path)
   def contain(artifact = %{}, path), do: artifact |> contain_(String.split(path,"/",trim: true))
   def contain(_, _), do: false


   defp contain_(%{"name"=>name}, [name]), do: true

   defp contain_(%{"name"=>dir, "type"=>"folder", "files" => files}, [dir | path]) do
      files |> Enum.any?(&(contain_(&1, path)))
   end

   defp contain_(_artifact, _path), do: false
end
