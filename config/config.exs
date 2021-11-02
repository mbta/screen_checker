import Config

config :screen_checker,
  solari_screen_list_module: ScreenChecker.SolariScreenList,
  gds_dms_username: "mbtadata@gmail.com",
  gds_dms_password: System.get_env("GDS_DMS_PASSWORD")

import_config "#{Mix.env()}.exs"
