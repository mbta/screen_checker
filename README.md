# ScreenChecker

Small application that regularly checks screen statuses and logs them to Splunk.

Currently it logs, once per minute, the statuses of all:

- Solari screens ([ScreenChecker.SolariData](./lib/screen_checker/solari_data.ex))
- GDS screens ([ScreenChecker.GdsData modules](./lib/screen_checker/gds_data/))
- Mercury v1 screens ([ScreenChecker.MercuryData.V1 module](./lib/screen_checker/mercury_data/v1))
- Mercury v2 screens ([ScreenChecker.MercuryData.V2 module](./lib/screen_checker/mercury_data/v2))

The list of Solari screen IPs is provided by an environment variable.
We fetch the list of active GDS and Mercury screens from an API endpoint.

## Bootstrap with

```sh
asdf install
mix deps.get
```

## Run locally with

```sh
# To skip logging Solari screen statuses, set `SOLARI_SCREEN_LIST='[]'`
# To skip logging GDS screen statuses, don't set `GDS_DMS_PASSWORD`
# To skip logging Mercury v1 screen statuses, don't set `MERCURY_API_KEY`
# To skip logging Mercury v2 screen statuses, don't set `MERCURY_V2_API_KEY`
SOLARI_SCREEN_LIST='[solari_screen_spec, ...]' GDS_DMS_PASSWORD='...' MERCURY_API_KEY='...' MERCURY_V2_API_KEY='...' mix run --no-halt
```

where `solari_screen_spec` is a JSON object of the form

```json
{
  "ip": "<IP address>",
  "name": "<screen name for logging>",
  "protocol": "<one of 'http' | 'https' | 'https_insecure'>"
}
```

## Test with

```sh
MIX_ENV=test mix coveralls.json
```

# Deploying

Screen checker runs on one of our on-prem Windows servers.

To deploy new code, simply use the "Deploy to Prod (on-prem)" GitHub Action.

Its supporting infrastructure is managed in Terraform. Check with the devops team if you need to make changes. (Secrets are probably the only thing you'd need to change)
