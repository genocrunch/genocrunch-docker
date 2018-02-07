Genocrunch in Docker
====================

A Dockerfile to run Genocrunch web application on Docker.

## Resources

- **Git clone URL:** <https://c4science.ch/source/genocrunch_docker.git>
- **Documentation:** <https://c4science.ch/source/genocrunch_docker>
- **Genocrunch documentation:** <https://c4science.ch/source/genocrunch-2.1>
- **Genocrunch official web server:** <https://genocrunch.epfl.ch>

## Requirements

- **Docker version 17.12.0-ce**

## Installation

### Set the Docker container external resources

To avoid data loses when updating a container, use data storage on the host:

```
$ mkdir /path/to/genocrunch/storage  # if users data storage location does not exist yet
```

Also set a database to be used by the containers:

```
$ sudo su postgres
$ psql
postgres=# create role genocrunch_user with login password 'genocrunch_db_password';
postgres=# create database genocrunch owner genocrunch_user;
postgres=# \q
$ exit
```

Allow the docker container to be listened from the database by modifying the `/etc/postgresql/9.?/main/postgresql.conf` file as following:

```
#/etc/postgresql/9.?/main/postgresql.conf 
...
listen_addresses = '*'
...
```

Also add the following line to `/etc/postgresql/9.?/main/pg_hba.conf`:

```
#/etc/postgresql/9.?/main/pg_hba.conf 
...
host    all             all             0.0.0.0/0               md5 
...
```

Restart the PostgreSQL service:

```
$ sudo /etc/init.d/postgresql restart
```

### Build the docker image

Set the Dockerfile:

```
$ cd /path/to/genocrunch
$ cp Dockerfile.keep Dockerfile
```

Edit these lines to set the app email address:

```
#Dockerfile

...
# config/config.yml
...
RUN sed -i 's/info_links:.*$/info_links: [{name: "link_name", href: "link_url", target: "_blank"}]/g' config/config.yml
RUN sed -i 's/user_confirmable:.*$/user_confirmable: false/g' config/config.yml

# config/initializers/devise.rb
...
RUN sed -i 's/config.mailer_sender =.*$/config.mailer_sender = "app_email@gmail.com"/g' config/initializers/devise.rb

# config/environments/development.rb
...
RUN sed -i 's/config.action_mailer.default_url_options =.*$/config.action_mailer.default_url_options = {:host => "localhost:3000"}/g' config/environments/development.rb
RUN sed -i 's/:address =>.*$/:address => "smtp.gmail.com",/g' config/environments/development.rb
RUN sed -i 's/:port =>.*$/:port => 587,/g' config/environments/development.rb
RUN sed -i 's/:domain =>.*$/:domain => "mail.google.com",/g' config/environments/development.rb
RUN sed -i 's/:user_name =>.*$/:user_name => "app_email@gmail.com",/g' config/environments/development.rb
RUN sed -i 's/:password =>.*$/:password => "app_email_password",/g' config/environments/development.rb
RUN sed -i 's/:authentication =>.*$/:authentication => :plain,/g' config/environments/development.rb
RUN sed -i 's/:enable_starttls_auto =>.*$/:enable_starttls_auto => true/g' config/environments/development.rb
...
```

Edit these lines to fit the database name, user and password set previously:

```
#Dockerfile

...
# config/database.yml
...
RUN sed -i 's/^.*username:.*$/  username: genocrunch_user/g' config/database.yml
RUN sed -i 's/database:.*$/database: genocrunch/g' config/database.yml
RUN sed -i 's/^.*password:.*$/  password: genocrunch_db_password/g' config/database.yml
...
```

Finally, build the docker image:

```
$ cd /path/to/genocrunch
$ docker build --rm -t genocrunch .
```

### Run a docker container

Run the docker container with the command below. Make sure to replace `/path/to/genocrunch/storage` with the appropriate path and replace `host.ip.address` by the host ip address.
This will automatically start the Genocrunch web server which will be accessible in a web browser at <http://localhost:3000> on the host and `host_ip_address:3000` on the network.

```
$ cd /path/to/genocrunch
$ docker run -v /path/to/genocrunch/storage:/home/genocrunch_user/genocrunch/users -p 3000:3000 --add-host=hostaddress:host.ip.address -it genocrunch
```

Complete the installation by initializing the database from within a docker container using `db/schema.rb` and `db/seeds.rb`:

```
$ docker run -v /path/to/genocrunch/storage:/home/genocrunch_user/genocrunch/users -p 3000:3000 --add-host=hostaddress:host.ip.address -it genocrunch bash

# Caution: this will overwrite the current database.
# For updates, use migrations instead
$ rails db:schema:load
$ rails db:seeds
$ exit
```
