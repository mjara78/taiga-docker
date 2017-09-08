Taiga in Docker
===============

This container allows you to run [Taiga](https://taiga.io/) in a Docker container.

What is Taiga?
--------------

Taiga is a project management application that can handle both simple and
complex projects for startups, software developers, and other target teams.
It tracks the progress of a project. Taiga's design is clean and elegant
design—something that is supposed to be "beautiful to look at all day long."
With Taiga, you can use either Kanban or Scrum template, or both. Backlogs are
shown as a running list of all features and User Stories added to the project.

Taiga integrates video conferencing functions with the use of third party
services from Talky.io and Appear.in. Group and private chat is done via HipChat.

Dockerfile
----------

The Dockerfile performs the following steps:
* install the OS & Python dependencies required to run Taiga Django backend.
* install nginx - to serve the content including static assests which Django
 app should not be handling.
* install circus - a process & socket manager for the Python web application.
* install gunicorn - a Python Web Server Gateway Interface (WSGI) HTTP Server
 to serve dynamic content.
* create taiga user for running circus & gunicorn.
* clone stable branches of the taiga backend and frontend.
* copy templates which will be then processed by the launch script when the
 container starts.


Running Taiga
=============

I recommend to use Docker Compose for running the Taiga.

Docker Compose
--------------

Below is a docker compose file as example

**docker-compose.yml**
```
version: '2'

volumes:
  postgres_data: {}
  taiga_static: {}
  taiga_media: {}

networks:
  backend: {}

services:
  postgres:
    # https://hub.docker.com/_/postgres/
    image: postgres
    networks:
      - backend
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./db:/docker-entrypoint-initdb.d:ro
    env_file:
      - ./postgres.env
      - ./taiga-db.env

  taiga:
    # https://hub.docker.com/r/andrey01/taiga
    image: andrey01/taiga
    # build: .
    networks:
      - backend
    ports:
      - 80:80
    volumes:
      - taiga_static:/opt/taiga/static
      - taiga_media:/opt/taiga/media
    env_file:
      - ./taiga.env
      - ./taiga-db.env
    environment:
      - TZ=Europe/Amsterdam
    depends_on:
      - postgres
```

The following file is required so that Postgres will create taiga database that
is used by the Taiga backend.

**db/init-taiga-db.sh**
```
#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE USER $TAIGA_DB_USER;
    CREATE DATABASE $TAIGA_DB_NAME;
    GRANT ALL PRIVILEGES ON DATABASE $TAIGA_DB_NAME TO $TAIGA_DB_USER;
    ALTER USER $TAIGA_DB_USER WITH PASSWORD '$TAIGA_DB_PASSWORD';
EOSQL
```

The environment variables
-------------------------

This file will defines a superuser for Postgres.

**postgres.env**
```
POSTGRES_USER=admin
POSTGRES_PASSWORD=admin
```

This file defines individual settings for Taiga.

**taiga.env**
```
GUNICORN_WORKERS=1
SITE_URI=http://taiga.mydomain.com
PUBLIC_REGISTER=true
ADMIN_EMAIL=admin@mydomain.com
NOREPLY_EMAIL=no-reply@mydomain.com
EMAIL_HOST=smtp.gmail.com
EMAIL_HOST_PORT=587
EMAIL_USE_TLS=True
# EMAIL_HOST_USER=youremail@gmail.com
# EMAIL_HOST_PASSWORD=yourpassword
```

This file defines the database settings for Taiga.

**taiga-db.env**
```
TAIGA_DB_USER=taiga
TAIGA_DB_NAME=taiga
TAIGA_DB_PASSWORD=secretpassword
TAIGA_DB_HOST=postgres
TAIGA_DB_PORT=5432
```


Run the Taiga
-------------

```
docker-compose up -d taiga
```

Now you can access Taiga with your favorite Web Browser.
Default user **admin** with password **123123** will be created on the first
run. **Please do not forget to change the password.**

I recommend to run nginx reverse proxy in front of this container, so that
you could use TLS.
[Let's Encrypt](https://letsencrypt.org) project is now able to issue free
SSL/TLS certificates.


Maintenance
===========

Keeping your image up2dated
---------------------------

This is simple, just run the following commands which will ensure that you
are running the latest images
```
docker-compose pull
docker-compose up -d
```

Accessing the Taiga Database
----------------------------

You can access it using the docker compose or docker as follows

> docker-compose run --rm postgres sh -c 'PGPASSWORD=$TAIGA_DB_PASSWORD exec psql -h "$TAIGA_DB_HOST" -U $TAIGA_DB_USER'

> docker run -ti --rm --net taiga_backend --env-file taiga-db.env postgres sh -c 'PGPASSWORD=$TAIGA_DB_PASSWORD exec psql -h "$TAIGA_DB_HOST" -U $TAIGA_DB_USER'

Backup the database
-------------------

Below is an example of how you can make the Taiga PostgreSQL database backup

> docker-compose run --rm postgres sh -c 'PGPASSWORD=$TAIGA_DB_PASSWORD exec pg_dump -h "$TAIGA_DB_HOST" -U $TAIGA_DB_USER $TAIGA_DB_NAME' > taiga-db.backup

To restore it

> docker-compose run --rm postgres sh -c 'PGPASSWORD=$TAIGA_DB_PASSWORD exec psql -h "$TAIGA_DB_HOST" -U $TAIGA_DB_USER $TAIGA_DB_NAME' < taiga-db.backup

There are also volumes containing the data you might want to backup externally
```
$ docker volume ls
DRIVER              VOLUME NAME
local               taiga_taiga_media
local               taiga_taiga_static
local               taiga_postgres_data
```

Quick launch
------------

For the impatient ones:

```
docker network create test1
docker run --rm -ti --network test1 --name postgres postgres:10-alpine
docker volume rm taiga_media
docker volume rm taiga_static
docker run --rm -ti --network test1 --name taiga -e SITE_URI=http://taiga -e TAIGA_DB_USER=taiga -e TAIGA_DB_NAME=taiga -e TAIGA_DB_PASSWORD=passw0rd -v taiga_static:/opt/taiga/static -v taiga_media:/opt/taiga/media andrey01/taiga
```

If you are running browser in a Docker container:

```
docker network connect test1 chrome_chrome_1
```

Open ``http://taiga`` and test Taiga.

Tearing down:

```
docker volume rm taiga_media
docker volume rm taiga_static
docker network disconnect test1 chrome_chrome_1
docker network rm test1
```

Useful links
------------

* [Docker Compose file reference](https://docs.docker.com/compose/compose-file/)
* [Taiga: Setup production environment](https://taigaio.github.io/taiga-doc/dist/setup-production.html)
* [Read Taiga upgrade notes](https://taigaio.github.io/taiga-doc/dist/upgrades.html)
* [How to upgrade Taiga](https://taigaio.github.io/taiga-doc/dist/upgrades.html)
