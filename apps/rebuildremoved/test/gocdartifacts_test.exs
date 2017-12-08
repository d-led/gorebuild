defmodule GoCDartifactsTest do
  use ExUnit.Case

  @input %{
       :name => "bla",
       :type => "folder",
       :files => [
          %{
             :name => "blup",
             :type => "folder",
             :files => [
                %{
                   :name => "foo",
                   :type => "file"
                }
             ]
          },
          %{
             :name => "bar",
             :type => "file"
          }
       ]
    }

  test "an existing folder with children", do: assert @input |> GoCDartifacts.contain("bla")
  test "an existing folder with children inside a list", do: assert [@input] |> GoCDartifacts.contain("bla")
  test "an existing folder at the tail of the list", do: assert [%{:name=>"a", :type=>"file"}, @input] |> GoCDartifacts.contain("bla")
  test "an existing file", do: assert @input |> GoCDartifacts.contain("bla/blup/foo")
  test "a non-existing file", do: assert !(@input |> GoCDartifacts.contain("bla/blup/bar"))
  test "a non-existing file inside a list", do: assert !([@input, @input] |> GoCDartifacts.contain("bla/blup/bar"))
  test "a subfolder", do: assert @input |> GoCDartifacts.contain("bla/bar")
end
