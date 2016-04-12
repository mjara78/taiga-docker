TODO
====

* Security: make sure /already_installed script does not depend on 'admin' user
 in case when someone wants to use alternative name (see TODO in
 seeds/already_installed.tmpl file)

* make sure Taiga sends emails, e.g. new user registered, password reset,
 general Taiga notifications

* enable Async tasks (leverage RabbitMQ, redis and the Taiga-events websocket
 server)

* add `apt-get upgrade` to the Dockerfile?
