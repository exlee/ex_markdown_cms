import Config

config :markdown_cms,
  documents_location: "docs/",
  use_agent: true

if Config.config_env() == :test do
  config :markdown_cms,
    documents_location: "test/sample_data/",
    data_source: :test
end
