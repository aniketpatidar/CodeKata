#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
./bin/rails tailwindcss:build
./bin/rails assets:precompile
./bin/rails assets:clean
./bin/rails db:migrate
./bin/rails db:seed
