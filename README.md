Sabacon
=============

Sabacon is a service perfomance online judge system.

Build image
-------------

```bash
$ docker build -t koduki/sabacon .
```

Run app server
-------------

If redis isn't running, you need to run.

```bash
$ docker run -d redis
```

Next, run the jobq worker daemon.

```bash
$  ./dwrap.sh jobq
```

Finally, run the application.

```bash
$ ./dwrap.sh
```

Operation for development
-------------

### scaffold

```bash
$ ./dwrap.sh rails g scaffold submission problem:integer repos_url:string tag:string
```

### db:migrate

```bash
$ ./dwrap.sh rake db:migrate RAILS_ENV=development
```

Operation for deploy
-------------

Deopoy this application to Heroku.

### Initialize heroku configration

```bash
$ heroku config:add RAILS_ENV=production
$ heroku config:add RACK_ENV=production
$ heroku config:add SECRET_KEY_BASE=`./dwrap.sh bundle exec rake secret|tail -1`
$ heroku config:add RAILS_SERVE_STATIC_FILES=enabled
$ heroku config:add RAILS_LOG_TO_STDOUT=enabled
$ heroku config:add LANG=en_US.UTF-8
```

### precompile assets

```bash
$ ./dwrap.sh rake assets:precompile
$ ./dwrap.sh build
```

### db:migration

```bash
$ heroku run rake db:migrate
$ heroku restart
```

### Deploy

```bash
$ ./dwrap.sh deploy-web
$ ./dwrap.sh deploy-worker
```