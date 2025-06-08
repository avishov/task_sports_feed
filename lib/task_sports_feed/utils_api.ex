defmodule TaskSportsFeed.UtilsAPI do
  @moduledoc """
    Utils API for Mox.
  """

  # callbacks for Mox
  @callback read_file(String.t()) ::
              {:ok, term()} | {:error, atom()} | {:error, Jason.DecodeError.t()}
  @callback read_file!(String.t()) :: term()
  @callback load_match_ids(String.t()) ::
              {:ok, list()} | {:error, atom()} | {:error, Jason.DecodeError.t()}

  def read_file(file \\ "priv/updates.json"), do: impl().read_file(file)
  def read_file!(file \\ "priv/updates.json"), do: impl().read_file!(file)
  def load_match_ids(file \\ "priv/updates.json"), do: impl().load_match_ids(file)
  defp impl, do: Application.get_env(:task_sports_feed, :utils, TaskSportsFeed.Utils)
end
