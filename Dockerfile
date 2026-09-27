# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is dev-oriented: it installs build tooling and keeps bundler
# caches in a named volume (mounted by docker-compose.yml) so gem installs
# survive container rebuilds and code edits do not require a rebuild.

ARG RUBY_VERSION=4.0.7
FROM docker.io/library/ruby:$RUBY_VERSION-slim

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential curl git libsqlite3-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /rails

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN chmod +x bin/docker-entrypoint

ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000

CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
