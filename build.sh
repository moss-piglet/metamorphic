#!/usr/bin/env bash
# exit on error
set -o errexit

# Initial setup
mix deps.get --only prod
MIX_ENV=prod mix compile

# Compile assets
npm install --prefix ./apps/metamorphic_web/assets

# Deploy assets
MIX_ENV=prod mix assets.deploy

# Migrate database
MIX_ENV=prod mix ecto.migrate

# Seed the database
MIX_ENV=prod mix run apps/metamorphic/priv/repo/seeds.exs

# Build the release and overwrite the existing release directory
MIX_ENV=prod mix release --overwrite