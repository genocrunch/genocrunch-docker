Genocrunch in Docker
====================

A Dockerfile to run Genocrunch web application on Docker.

## Resources

- **Git clone URL:** <https://github.com/genocrunch/genocrunch-docker.git>
- **Documentation:** <https://github.com/genocrunch/genocrunch-docker>
- **Docker image** <https://hub.docker.com/r/genocrunch/genocrunch-docker>
- **Genocrunch documentation:** <https://github.com/genocrunch/genocrunch>
- **Genocrunch official web site:** <https://genocrunch.epfl.ch>

## Rights

- **License:** MIT (See LICENSE.txt for details)

## System requirements

- **docker:** https://docs.docker.com
- **git:** https://git-scm.com/

## Installation (on Debian linux)

If not done yet, install docker by following the documentation at https://docs.docker.com/install.

Note: you will have to use sudo with docker commands if docker is not configured to be used as a non-root user. You may have to contact your IT administrator for that.

The Genocrunch web application will need to store some data files and to use a database. To avoid data loses when updating a container, you can set both data storage location and database on the host (as opposed to set it up on the docker container itself).

### Set the Genocrunch data storage location

Create a new data storage directory on the host side. This directory will be used by the Genocrunch web app running on the docker container:

```
$ mkdir /path/to/genocrunch/storage
```

### Set the Genocrunch database

Create a PostgreSQL database on the host side. This database will be used by the Genocrunch web app running on the docker container:

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

### Get the docker image

To get the docker image, you can either **Pull the docker image from dockerhub** or **Build the docker image from the Dockerfile**.

If you want a pre-build docker image with a default Genocrunch installation, pull it directly from dockerhub.
Building the image from the Dockerfile allows you to setup aa docker image with a custom installation of Genocrunch.

#### Pull the docker image from dockerhub

If you want a pre-build docker image with a default Genocrunch installation, pull it from the `genocrunch/genocrunch-docker` dockerhub repository:

```
$ docker pull genocrunch/genocrunch-docker:1.0.0
```

Although the docker image comes with default configuration, you will later be able to use the `-v` argument in the `docker run` command to customize the configuration by specifying custom configuration files.

You can get configuration files templates from the `config` directory of the https://github.com/genocrunch/genocrunch-docker repository. Here are three options to download these files:

- Get a full copy of the repository using `git clone`:
```
$ git clone https://github.com/genocrunch/genocrunch-docker.git
```
The configuration files will then be located in the `genocrunch-docker/config` directory.

- Download the `config` directory only using the DownGit tool [here](
https://minhaskamal.github.io/DownGit/#/home?url=https://github.com/genocrunch/genocrunch/tree/master/config).

- Download the configuration files one by one, following this example:
```
$ wget https://raw.githubusercontent.com/genocrunch/genocrunch-docker/master/config/config.yml
```

#### Build the docker image from the Dockerfile

Download the Dockerfile from its git repository:

```
$ git clone https://github.com/genocrunch/genocrunch-docker.git
```

Before building a docker image using the Dockerfile, you may want to edit the Dockerfile in order to customize the installation of the Genocrunch web app.
For this, open `genocrunch-docker/Dockerfile` with your favorite editor and add the following lines:

```
USER genocrunch_user
WORKDIR /home/genocrunch_user/genocrunch

# Additional link(s) that should be included in the Infos menu of the topbar (set to [] to ignore)
RUN sed -i 's/info_links:.*$/info_links: [{name: "link_name", href: "link_url", target: "_blank"}]/g' config/config.yml

# Webmaster email
RUN sed -i 's/webmaster_email:.*$/webmaster_email: webmaster_email/g' config/config.yml

# Google analytics tag (set to "" to ignore)
RUN sed -i 's/gtag_id:.*$/gtag_id: your_google_analytics_tag_id/g' config/config.yml

# Send a validation link to user email to confirm registration?
RUN sed -i 's/user_confirmable:.*$/user_confirmable: false/g' config/config.yml

# Compressed archive format for downloading an archive of analysis files. Valid choices are zip or tar.gz
RUN sed -i 's/archive_format:.*$/archive_format: zip/g' config/config.yml

# Max time without update for a job owned by a guest user not to be automatically deleted by the 'cleanup' rake task (in days)
RUN sed -i 's/max_sandbox_job_age:.*$/max_sandbox_job_age: 2/g' config/config.yml

# Max time without update for a job owned by a registered user not to be automatically deleted by the 'cleanup' rake task (in days)
RUN sed -i 's/max_job_age:.*$/max_job_age: 365/g' config/config.yml

# Set the email address to be used by the web app:
RUN sed -i 's/config.mailer_sender =.*$/config.mailer_sender = "app_email@gmail.com"/g' config/initializers/devise.rb
RUN sed -i 's/config.action_mailer.default_url_options =.*$/config.action_mailer.default_url_options = {:host => "localhost:3000"}/g' config/environments/development.rb
RUN sed -i 's/:address =>.*$/:address => "smtp.gmail.com",/g' config/environments/development.rb
RUN sed -i 's/:port =>.*$/:port => 587,/g' config/environments/development.rb
RUN sed -i 's/:domain =>.*$/:domain => "mail.google.com",/g' config/environments/development.rb
RUN sed -i 's/:user_name =>.*$/:user_name => "app_email@gmail.com",/g' config/environments/development.rb
RUN sed -i 's/:password =>.*$/:password => "app_email_password",/g' config/environments/development.rb
RUN sed -i 's/:authentication =>.*$/:authentication => :plain,/g' config/environments/development.rb
RUN sed -i 's/:enable_starttls_auto =>.*$/:enable_starttls_auto => true/g' config/environments/development.rb

# Set the database name, user and password (must match host settings described above):
RUN sed -i 's/database:.*$/database: genocrunch/g' config/database.yml
RUN sed -i 's/^.*username:.*$/  username: genocrunch_user/g' config/database.yml
RUN sed -i 's/^.*password:.*$/  password: genocrunch_db_password/g' config/database.yml
```

Finally, build the docker image using the `docker build` command:

```
$ docker build --rm -t genocrunch/genocrunch-docker .
```

### Initialize the database

Complete the installation of the Genocrunch web app by initializing its database from within a docker container using rails schema (`db/schema.rb`) and seeds (`db/seeds.rb`).
Caution: this will overwrite the database and should be applied only for initialization/re-initialization, not updates. For updates, use migrations or SQL queries.

**If you have pulled the image from dockerhub and the default database configuration does not match the configuration on the host, you can use the `-v` argument in the `docker run` command to specify custom configuration files as following:**

```
-v path/to/config/config.yml:/home/genocrunch_user/genocrunch/config/config.yml
-v path/to/config/initializers/devise.rb:/home/genocrunch_user/genocrunch/config/initializers/devise.rb
-v path/to/config/environments/development.rb:/home/genocrunch_user/genocrunch/config/environments/development.rb
-v path/to/config/database.yml:/home/genocrunch_user/genocrunch/config/database.yml
```

```
# Run a docker container in interactive mode:
# Replace /path/to/genocrunch/storage by the appropriate path (see the Set the Genocrunch data storage location section above).
# Replace host.ip.address by the host ip address.
# If needed, add custom configuration files using the -v argument as described above.
$ docker run -v /path/to/genocrunch/storage:/home/genocrunch_user/genocrunch/users -p 3000:3000 --add-host=hostaddress:host.ip.address -it genocrunch/genocrunch-docker bash

# Initialize the database:
$ rails db:schema:load

# To change default guest and admin passwords, emails and storage quotas, edit the `User.create` query in the db/seeds.rb file with nano:
$ nano db/seeds.rb

# Finally, seed the database:
$ rails db:seed

# You can finally close the container:
$ exit
```

## Usage

Run a docker container using the command below. Make sure to replace `/path/to/genocrunch/storage` with the appropriate path (see the `Set the Docker container external resources` section above) and replace `host.ip.address` by the host ip address.
This will automatically start the Genocrunch web server which will be accessible in a web browser at <http://localhost:3000> on the host and `host.ip.address:3000` on your network.

**Note: Remember that if you have pulled the image from dockerhub, you can use the `-v` argument in the `docker run` command to specify custom configuration files.**

```
# Replace /path/to/genocrunch/storage by the appropriate path (see the Set the Genocrunch data storage location section above).
# Replace host.ip.address by the host ip address.
# If needed, add custom configuration files using the -v argument as described in the Initialize the database section above.
$ docker run -v /path/to/genocrunch/storage:/home/genocrunch_user/genocrunch/users -p 3000:3000 --add-host=hostaddress:host.ip.address -it genocrunch/genocrunch-docker
```

