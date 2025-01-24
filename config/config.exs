import Config

config :screen_checker,
  solari_screen_list_module: ScreenChecker.SolariScreenList

config :logger,
  backends: [:console]

import_config "#{Mix.env()}.exs"
