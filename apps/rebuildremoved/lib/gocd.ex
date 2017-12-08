defmodule Gocd do
    require Logger

    @gocd Application.get_env(:rebuildremoved, :gocd)

    def hi, do: Logger.info @gocd.url
end
