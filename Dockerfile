FROM ruby:3.3-slim

# ca-certificates for TLS (GitHub API + SMTP); build-essential not needed for the
# pure-Ruby `mail` gem.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# The build context is the repo root — that's where `action.yml` lives — so every
# source path is prefixed with `ruby/`. Gems install first for layer caching.
COPY ruby/Gemfile ./
RUN gem install bundler --no-document \
    && bundle config set --local without 'development' \
    && bundle install

COPY ruby/lib ./lib
COPY ruby/bin ./bin

ENTRYPOINT ["ruby", "/app/bin/boardly"]
