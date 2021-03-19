import Config

config :screen_checker,
  screen_list_module: ScreenChecker.ScreenList

import_config "#{Mix.env()}.exs"
