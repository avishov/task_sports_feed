defmodule TaskSportsFeed.Utils do
  @moduledoc """
    Module holding utility functions for the
    rest of the applications.
  """

  @doc """
    Reads the file under the passed path (or if
    no path is passed, reads the default file
    present under a default path) and uses the
    Jason library to decode it.

  Returns `{:ok, term()}` when successful.
  Returns `{:error, posix()}` for fire-reading errors or
  `{:error, Jason.DecodeError.t()}` for JSON decoding errors.
  """
  def read_file(file \\ "priv/updates.json") do
    with {:ok, binary} <- File.read(file) do
      Jason.decode(binary)
    end
  end

  @doc """
    Reads the file under the passed path (or if
    no path is passed, reads the default file
    present under a default path) and uses the
    Jason library to decode it.

  Returns the parsed JSON as `term()` or raises
  either a `File.Error` for errors when reading the file or
  `Jason.DecodeError.t()` for errors while decoding the JSON
  in the file.
  """
  def read_file!(file \\ "priv/updates.json"),
    do:
      file
      |> File.read!()
      |> Jason.decode!()

  @doc """
    Reads the contents of the file and extracts match_ids from it.
    Then filters out match_id duplicates.

  Returns a list of unique match_ids as `{:ok, list()}` on success.
  Returns `{:error, posix()}` for fire-reading errors or
  `{:error, Jason.DecodeError.t()}` for JSON decoding errors.
  """
  def load_match_ids(file \\ "priv/updates.json") do
    with {:ok, decoded_json} <- read_file(file),
         match_ids <- Enum.map(decoded_json, & &1["match_id"]),
         unique_match_ids <- Enum.uniq(match_ids) do
      {:ok, unique_match_ids}
    end
  end
end
