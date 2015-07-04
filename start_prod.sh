#!/bin/bash
npm install
./node_modules/brunch/bin/brunch build --production
mix phoenix.digest
rm -rf ./config/prod.secret.exs
ln -sf /config/pxblog/prod.secret.exs ./config/prod.secret.exs
MIX_ENV=prod PORT=4001 elixir --detached -S mix phoenix.server
