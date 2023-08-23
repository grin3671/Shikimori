[![RSpec CI](https://github.com/shikimori/shikimori/actions/workflows/rspec.yml/badge.svg?branch=master)](https://github.com/shikimori/shikimori/actions/workflows/rspec.yml)

## Contributing
Feel free to open tickets or send pull requests with improvements. Thanks in advance for your help!

Please follow the [contribution guidelines](https://github.com/shikimori/shikimori/blob/master/CONTRIBUTING.md).

## Requirements
OSX or Linux

PostgreSQL >= 10.0, Ruby >= 2.6, NodeJS >= 10.0, Elasticsearch 6.x (7.0 not supported), Memcached, Redis

## Issues Board (Agile Season)
https://agileseason.com/#/shared/board/098d2e36dff32f296d7815cf943ac8eb

## Requirements

### Checkout all projects
```sh
git clone git@github.com:shikimori/shikimori.git
git clone git@github.com:shikimori/neko-achievements.git
cd neko-achievements
mix local.hex --force
mix deps.get
cd ..
git clone git@github.com:shikimori/camo-server.git
cd camo-server
yarn
cd ..
git clone git@github.com:shikimori/faye-server.git
cd faye-server
yarn
cd ..
cd shikimori
```

### Install `yarn`, `tmux` and `overmind` via Homebrew (OSX)
```sh
brew install yarn tmux overmind
```
In linux you have to install them another way.

### Install dependent gems and npm packages
```sh
yarn install
bundle install
```

## PostgreSQL
### DB
```sh
psql -d postgres
```
```sql
create user shikimori_development;
create user shikimori_test;
alter user shikimori_development createdb;
alter user shikimori_test createdb;
alter user shikimori_development with superuser;
alter user shikimori_test with superuser;
```

### Create databases
Make sure `en_US.UTF-8` database collation is set [https://gist.github.com/ffmike/877447#gistcomment-2851598](https://gist.github.com/morr/9507173acfd504837a7feb4485a5f669)

Or you manually initialize new database with command
```sh
initdb --pgdata=/usr/local/var/postgres-14 -E 'UTF-8' --lc-collate='en_US.UTF-8' --lc-ctype='en_US.UTF-8'
```

Or initdb for apple M1
```sh
initdb --pgdata=/opt/homebrew/var/postgresql@14 -E 'UTF-8' --lc-collate='en_US.UTF-8' --lc-ctype='en_US.UTF-8'
```


Create rails databases
```sh
rails db:create
```

### Extensions
```sh
psql -d shikimori_test_
```
```sql
CREATE EXTENSION unaccent;
CREATE EXTENSION hstore;
CREATE EXTENSION pg_stat_statements;
```

```sh
psql -d shikimori_development
```
```sql
CREATE EXTENSION unaccent;
CREATE EXTENSION hstore;
CREATE EXTENSION pg_stat_statements;
```

## Local Run
Everything you need to run is listed in [Procfile](https://github.com/shikimori/shikimori/blob/master/Procfile).
Shikimori uses [Overmind](https://github.com/DarthSim/overmind) to execute `Procfile`.


### Restore from a backup
```sh
rails db:drop && rails db:create
unzip -d db/ db/dump.sql.zip
psql -U shikimori_development -d shikimori_development -f db/dump.sql
rm db/dump.sql
RAILS_ENV=test rails db:schema:load
# migrate dump to latest schema
rails db:migrate
```

### Start rails server
```sh
rails server
```
### Start related services
```sh
overmind start
```
### Start some of related services
```sh
OVERMIND_PROCESSES=camo,faye overmind start
```

## Elasticsearch

In rails console:

```
Elasticsearch::RebuildIndexes.new.perform
```

## Elasticsearch fix on OSX
https://github.com/Homebrew/homebrew-core/issues/100260#issuecomment-1137067501
```
I've finally made it work, but I'm not sure this is the right call:

I've edited the service plist at /usr/local/Cellar/elasticsearch@6/6.8.23/homebrew.mxcl.elasticsearch@6.plist:

     <key>ProgramArguments</key>
     <array>
       <string>/usr/local/opt/elasticsearch@6/bin/elasticsearch</string>
     </array>
     <key>EnvironmentVariables</key>
     <dict>
+      <key>JAVA_HOME</key>
+      <string>'/usr/libexec/java_home -v 17'</string>
     </dict>
I had to edit the plist in the Cellar folder instead of the one in ~/Library/LaunchAgents because brew services is overwriting it at every start.

```


## Update neko rules
```sh
rails neko:update
```

## Other
### Make a backup
```sh
pg_dump -c shikimori_development > db/dump.sql
```

### Autorun rspec & rubocop
```sh
guard
```

### Record apipie docs
```sh
APIPIE_RECORD=all rspec spec/controllers/api/**
```

### Add new video hosting
```ruby
# app/services/video_extractor/player_url_extractor.rb
```

### Run locally in production mode
```sh
RAILS_ENV=production rails assets:precompile && IS_LOCAL_RUN=true RAILS_ENV=production rails server
```

### Webpack debugger
https://nodejs.org/en/docs/inspector/
Install the Chrome Extension NIM (Node Inspector Manager): https://chrome.google.com/webstore/detail/nim-node-inspector-manage/gnhhdgbaldcilmgcpfddgdbkhjohddkj
```sh
RAILS_ENV=development NODE_ENV=development NODE_PATH=node_modules node --inspect-brk node_modules/.bin/webpack-dev-server --progress --color --config config/webpack/development.js
```


### Webpack visualizer
https://chrisbateman.github.io/webpack-visualizer/

### Dependabot
```
@dependabot ignore this dependency
```

## [Sandboxes](/doc/sandboxes.md)
