Genocrunch in Docker
====================

A Dockerfile to run Genocrunch web application on Docker.

## Resources

- **Git clone URL:** <https://github.com/genocrunch/genocrunch_docker.git>
- **Documentation:** <https://github.com/genocrunch/genocrunch_docker>
- **Genocrunch documentation:** <https://c4science.ch/source/genocrunch-2.1>
- **Genocrunch official web server:** <https://genocrunch.epfl.ch>

## Rights

- **Copyright:** All rights reserved. ECOLE POLYTECHNIQUE FEDERALE DE LAUSANNE, Switzerland, Laboratory of Intestinal Immunology, 2018
- **License:** MIT (See LICENSE.txt for details)
- **Author:** A Rapin

## Requirements

- **Docker version 17.12.0-ce**

## Installation (on Debian linux)

Note: you may have to use `sudo` with docker commands if docker is not configured to be used as a non-root user.

### Set the Docker container external resources

The Genocrunch web application will need to store some data files and to use a database. To avoid data loses when updating a container, you can set both data storage location and database on the host (as opposed to set it up on the docker container itself).

First, create a new data storage directory on the host side. This directory will be used by the Genocrunch web app running on the docker container:

```
$ mkdir /path/to/genocrunch/storage
```

Also create a PostgreSQL database on the host side. This database will be used by the Genocrunch web app running on the docker container:

```
$ sudo apt-get install postgresql postgresql-contrib
$ sudo su postgres
$ psql
postgres=# create role genocrunch_user with login password 'genocrunch_db_password';
postgres=# create database genocrunch owner genocrunch_user;
postgres=# \q
$ exit
```

Then, allow the docker container to be listened from the database by modifying the `/etc/postgresql/9.?/main/postgresql.conf` file as following:

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

Finally, restart the PostgreSQL service:

```
$ sudo /etc/init.d/postgresql restart
```

### Build the docker image

First, download the Dockerfile from its git repository:

```
$ git clone https://github.com/genocrunch/genocrunch_docker.git
```

Before building a docker image using the Dockerfile, you may want to edit the Dockerfile in order to customize the installation of the Genocrunch web app.
For this, open `genocrunch_docker/Dockerfile` with your favorite editor and follow the following instructions:


Edit this line to define the CRAN mirror from which to download R packages:

```
#Dockerfile

...
RUN echo "options(repos=structure(c(CRAN='https://stat.ethz.ch/CRAN')))" >> .Rprofile
...
```

Edit this line to define any custom link to be included in the info menu of the Genocrunch web app topbar:

```
#Dockerfile

...
# config/config.yml
...
RUN sed -i 's/info_links:.*$/info_links: [{name: "link_name", href: "link_url", target: "_blank"}]/g' config/config.yml
...
```

Edit this line to define whether new users will be asked to confirm their email address via a confirmation link or not:

```
#Dockerfile

...
# config/config.yml
...
RUN sed -i 's/user_confirmable:.*$/user_confirmable: false/g' config/config.yml
...
```

Edit these lines to set the email address to be used by the web app:

```
#Dockerfile

...
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
$ docker build --rm -t genocrunch .
```

### Database initialization

Complete the installation of the Genocrunch web app by initializing its database from within a docker container using rails schema (`db/schema.rb`) and seeds (`db/seeds.rb`).
Caution: this will overwrite the database and should be applied only for initialization/re-initialization, not updates. For updates, use migrations or SQL queries.

```
$ docker run -v /path/to/genocrunch/storage:/home/genocrunch_user/genocrunch/users -p 3000:3000 --add-host=hostaddress:host.ip.address -it genocrunch bash
$ rails db:schema:load

# To change default guest and admin passwords, emails and storage quotas, edit the `User.create` query in the db/seeds.rb file with nano:
$ nano db/seeds.rb

# Finally, seed the database:
$ rails db:seed
$ exit
```

### Run a docker container

Run a docker container using the command below. Make sure to replace `/path/to/genocrunch/storage` with the appropriate path (see the `Set the Docker container external resources` section above) and replace `host.ip.address` by the host ip address.
This will automatically start the Genocrunch web server which will be accessible in a web browser at <http://localhost:3000> on the host and `host.ip.address:3000` on your network.

```
$ docker run -v /path/to/genocrunch/storage:/home/genocrunch_user/genocrunch/users -p 3000:3000 --add-host=hostaddress:host.ip.address -it genocrunch
```

