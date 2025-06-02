ARG ELIXIR_VERSION=1.17.3
ARG ERLANG_VERSION=27.3.4
ARG ALPINE_VERSION=3.21.3

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${ERLANG_VERSION}-alpine-${ALPINE_VERSION} as build

ENV MIX_ENV=prod

RUN mkdir /screen_checker

WORKDIR /screen_checker

RUN apk add --no-cache git
RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY config/config.exs config/config.exs
COPY config/prod.exs config/prod.exs

RUN mix deps.compile

COPY lib lib
RUN mix release linux

# The one the elixir image was built with
FROM hexpm/erlang:${ERLANG_VERSION}-alpine-${ALPINE_VERSION}

RUN apk add --no-cache dumb-init && \
    mkdir /work /screen_checker && \
    adduser -D screen_checker && chown screen_checker /work

COPY --from=build /screen_checker/_build/prod/rel/linux /screen_checker

# Allow screen_checker to update the Timezone data
RUN chown screen_checker /screen_checker/lib/tzdata-*/priv /screen_checker/lib/tzdata*/priv/*

# Set exposed ports
ENV MIX_ENV=prod TERM=xterm LANG=C.UTF-8 \
    ERL_CRASH_DUMP_SECONDS=0 RELEASE_TMP=/work

USER screen_checker
WORKDIR /work

ENTRYPOINT ["/usr/bin/dumb-init", "--"]

HEALTHCHECK CMD ["/screen_checker/bin/linux", "rpc", "1 + 1"]
CMD ["/screen_checker/bin/linux", "start"]
