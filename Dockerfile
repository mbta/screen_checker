ARG ELIXIR_VERSION=1.14.5
ARG ERLANG_VERSION=25.3.2.2
ARG WINDOWS_VERSION=1809
# See also: ERTS_VERSION in the from image below

ARG BUILD_IMAGE=mbtatools/windows-elixir:$ELIXIR_VERSION-erlang-$ERLANG_VERSION-windows-$WINDOWS_VERSION
ARG FROM_IMAGE=mcr.microsoft.com/windows/servercore:$WINDOWS_VERSION

FROM $BUILD_IMAGE as build

ENV MIX_ENV=prod

# log which version of Windows we're using
RUN ver

RUN mkdir C:\screen_checker

WORKDIR C:\\screen_checker

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY config/config.exs config\\config.exs
COPY config/prod.exs config\\prod.exs

RUN mix deps.compile

COPY lib lib
# ^ anything else we need to copy?

RUN mix release

FROM $FROM_IMAGE
ARG ERTS_VERSION=13.0

USER ContainerAdministrator
COPY --from=build C:\\Erlang\\vcredist_x64.exe vcredist_x64.exe
RUN .\vcredist_x64.exe /install /quiet /norestart \
    && del vcredist_x64.exe

COPY --from=build C:\\screen_checker\\_build\\prod\\rel\\screen_checker C:\\screen_checker

WORKDIR C:\\screen_checker

# Ensure Erlang can run
RUN dir && \
    erts-%ERTS_VERSION%\bin\erl -noshell -noinput +V

EXPOSE 8001
# ^ Realtime_signs uses 80 instead

CMD ["C:\\screen_checker\\bin\\screen_checker.bat", "start"]
