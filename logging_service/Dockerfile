FROM ruby:3.1-slim

RUN apt-get update -qq && apt-get install -y build-essential libpq-dev

WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install

COPY . /app
CMD ["ruby", "app.rb"]