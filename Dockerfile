FROM elixir:1.10.3 AS builder
ENV MIX_ENV=prod
RUN mkdir /app
WORKDIR /app
COPY . .
RUN mix release gossip_cluster

FROM buildpack-deps:buster
ENV LANG=C.UTF-8
RUN mkdir /app
COPY --from=builder /app/_build /app
CMD ["/app/prod/rel/gossip_cluster/bin/gossip_cluster", "start"]
