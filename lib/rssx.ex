defmodule Rssx do
  @moduledoc """
  RSS feed parser that fetches and parses RSS feeds into Elixir data structures.
  """

  @doc """
  Fetches an RSS feed from a URL and parses it into an Elixir data structure.
  """
  def fetch(url) when is_binary(url) do
    with {:ok, %{status: 200, body: body}} <- Req.get(url),
         {:ok, parsed_rss} <- parse_rss(body) do
      {:ok, parsed_rss}
    else
      {:ok, %{status: status}} ->
        {:error, "HTTP #{status}"}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Parses RSS XML string into an Elixir data structure.
  """
  def parse_rss(xml) when is_binary(xml) do
    xml
    |> from_xml_string()
    |> extract_rss_data()
  end

  def from_xml_string(xml) do
    xml
    |> String.replace(~r/<\?xml.*?>/i, "")
    |> Floki.parse_document()
    |> case do
      {:ok, parsed} -> Floki.raw_html(parsed)
      {:error, _} -> ""
    end
    |> String.trim()
    |> try_parse()
  end

  defp try_parse(""), do: %{}

  defp try_parse(xml) do
    try do
      XmlToMap.naive_map(xml)
    rescue
      _ -> %{}
    end
  end

  defp extract_rss_data(%{"rss" => feed}), do: {:ok, feed}
  defp extract_rss_data(%{"feed" => feed}), do: {:ok, feed}
  defp extract_rss_data(_), do: %{error: "Invalid RSS format"}

  def extract_items(%{"item" => items}) when is_list(items) do
    Enum.map(items, &extract_item/1)
  end

  def extract_items(%{"item" => item}) when is_map(item) do
    [extract_item(item)]
  end

  def extract_items(_), do: []

  defp extract_item(item) when is_map(item) do
    %{
      title: get_text(item, "title"),
      description: get_text(item, "description"),
      link: get_text(item, "link"),
      pub_date: get_text(item, "pubDate"),
      author: get_text(item, "author"),
      guid: get_text(item, "guid")
    }
  end

  def extract_atom_entries(%{"entry" => entries}) when is_list(entries) do
    Enum.map(entries, &extract_atom_entry/1)
  end

  def extract_atom_entries(%{"entry" => entry}) when is_map(entry) do
    [extract_atom_entry(entry)]
  end

  def extract_atom_entries(_), do: []

  defp extract_atom_entry(entry) when is_map(entry) do
    %{
      title: get_text(entry, "title"),
      description: get_text(entry, "summary"),
      link: get_link(entry),
      pub_date: get_text(entry, "updated"),
      author: get_author(entry),
      guid: get_text(entry, "id")
    }
  end

  defp get_text(map, key) when is_map(map) do
    case Map.get(map, key) do
      %{"#content" => content} -> content
      content when is_binary(content) -> content
      _ -> nil
    end
  end

  defp get_text(_, _), do: nil

  defp get_link(%{"link" => %{"@href" => href}}), do: href
  defp get_link(%{"link" => link}) when is_binary(link), do: link
  defp get_link(_), do: nil

  defp get_author(%{"author" => %{"name" => %{"#content" => name}}}), do: name
  defp get_author(%{"author" => %{"name" => name}}) when is_binary(name), do: name
  defp get_author(%{"author" => author}) when is_binary(author), do: author
  defp get_author(_), do: nil
end
