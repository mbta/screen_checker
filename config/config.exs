import Config

config :logger,
  backends: [{Logger.Backend.Splunk, :splunk}, :console]

config :logger, :console, level: :warn

config :logger, :splunk,
  connector: Logger.Backend.Splunk.Output.Http,
  host: 'https://http-inputs-mbta.splunkcloud.com/services/collector/event',
  token: {:system, "PROD_SIGNS_SPLUNK_TOKEN"},
  format: "$dateT$time [$level]$levelpad node=$node $metadata$message\n",
  metadata: [:request_id]
