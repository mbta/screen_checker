# ScreenChecker

Small application that regularly checks screen statuses and logs them to Splunk.

Bootstrap with
```sh
asdf install
mix deps.get
```

Run with
```sh
mix run --no-halt
```

Test with
```sh
 MIX_ENV=test mix coveralls.json
```