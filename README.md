# ScreenChecker
Small application that regularly checks screen statuses and logs them to Splunk.

Bootstrap with
```sh
asdf install
mix deps.get
```

Run locally with
```sh
mix run --no-halt
```

Test with
```sh
 MIX_ENV=test mix coveralls.json
```

# Deploying
Screen checker runs as a Windows service on Opstech3.

The version of Erlang we use is precompiled Erlang/OTP 22.1, installed via [this Windows installer](https://www.erlang-solutions.com/resources/download.html) to `/c/Users/RTRUser/bin/`.

The version of Elixir we use is precompiled Elixir 1.9.4, downloaded [here](https://github.com/elixir-lang/elixir/releases) and unzipped to `/c/Users/RTRUser/bin`.

The `screen_checker` code is `git clone`d to `/c/Users/RTRUser/GitHub/screen_checker/`. There is only a prod environment.

We build the application via Elixir-native `mix release`, setting the `PATH` to include the aforementioned versions of Elixir and Erlang. The release gets built into `_build/prod/rel/`.

To manage the Windows service we use [`WinSW 2.9`](https://github.com/winsw/winsw/releases/tag/v2.9.0). The service is configured via an XML file in `/c/Users/RTRUser/apps/`. In particular, environment variables are updated by editing the XML file.

## First time, one-time setup if you're a new user on Opstech3
Open File Explorer and navigate to `C:\Users\RTRUser`. Confirm admin access if it asks.

## Deploying a new version
1. In Git Bash, navigate to `/c/Users/RTRUser/GitHub/screen_checker`.
1. `git pull` the latest version.
1. Run `./build_release.sh screen_checker` to compile a new release. The second argument gives the name of the Erlang node to run the release under and isn't terribly important as long as it's unique.
1. Open the Windows `Services` application and restart `screen-checker`.
1. Tag the release in git: `git tag -a yyyy-mm-dd -m "Deployed on [date] at [time]"`.
1. Push the tag to GitHub: `git push origin yyyy-mm-dd`.

## Getting service config changes to take effect
If you make changes to the WinSW service's XML config (located at `C:\Users\RTRUser\apps\screen_checker.xml`), you will need to recreate the service.

1. Make your config changes.
1. Open the Windows `Services` application and stop `screen-checker`. Keep `Services` open for now.
1. Open Command Prompt as administrator.
1. `cd C:\Users\RTRUser\apps`
1. `screen_checker.exe uninstall`
1. `screen_checker.exe install`
1. Switch back to `Services` and start `screen-checker` again.
