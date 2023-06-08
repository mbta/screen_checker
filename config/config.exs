import Config

config :screen_checker,
  solari_screen_list_module: ScreenChecker.SolariScreenList,
  gds_dms_username: "mbtadata@gmail.com"

config :logger,
  backends: [:console]

import_config "#{Mix.env()}.exs"
