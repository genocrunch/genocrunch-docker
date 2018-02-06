# DOWNLOAD BASE IMAGE OF CENTOS7
FROM centos:centos7

MAINTAINER alexis rapin

# CREATE APP USER
RUN adduser -m genocrunch_user
WORKDIR /home/genocrunch_user

# MISC
RUN yum -y install nano

# INSTALL RUBY WITH RBENV

# Install dependencies
RUN yum -y update && yum clean all
RUN yum install -y git-core \
    zlib \
    zlib-devel \
    gcc \
    gcc-c++ \
    patch \
    readline \
    readline-devel \
    libyaml-devel \
    libffi-devel \
    openssl-devel \
    make \
    bzip2 \
    bzip2-devel \
    autoconf \
    automake \
    libtool \
    bison \
    curl \
    sqlite-devel \
    epel-release \
    nodejs && yum clean all

# Install rbenv from github
USER genocrunch_user
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv
RUN echo 'export PATH="(~/.rbenv/bin:$PATH"' >> ~/.bashrc
RUN echo 'eval "$(~/.rbenv/bin/rbenv init -)"' >> ~/.bashrc
RUN source ~/.bashrc
RUN git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
USER root
RUN cd /home/genocrunch_user/.rbenv/plugins/ruby-build && ./install.sh

# Install ruby
USER genocrunch_user
RUN ~/.rbenv/bin/rbenv install 2.3.1
RUN ~/.rbenv/bin/rbenv global 2.3.1

# Install rails
RUN echo "gem: --no-document" > ~/.gemrc
RUN ~/.rbenv/shims/gem install bundler
RUN ~/.rbenv/shims/gem install rails -v 5.0.1
RUN ~/.rbenv/bin/rbenv rehash
RUN echo 'export PATH="~/.rbenv/versions/2.3.1/bin:$PATH"' >> .bashrc

# INSTALL POSTGRESQL
USER root
RUN yum -y install postgresql \
    postgresql-contrib \
    postgresql-devel \
    postgresql-libs
#RUN postgresql-setup initdb
#RUN sed -i 's/^\(host.*\)ident$/\1md5/g;' /var/lib/pgsql/data/pg_hba.conf
#RUN systemctl start postgresql
#RUN systemctl enable postgresql

# INSTALL PYTHON2.7
#RUN yum install -y python-pip
#RUN pip install numpy
#RUN yum -y groupinstall 'Development Tools'

# INSTALL R
RUN yum install -y R-core \
    R-base \
    R-devel \
    libcurl-devel

# Install R packages
RUN yum install -y libxml2-devel
RUN echo "options(repos=structure(c(CRAN='https://cran.uib.no')))" >> .Rprofile
RUN echo ".libPaths('/usr/share/R/library')" >> .Rprofile
RUN Rscript -e "install.packages('ineq')"
RUN Rscript -e "install.packages('rjson')"
RUN Rscript -e "install.packages('fpc')"
RUN Rscript -e "install.packages('multcomp')"
RUN Rscript -e "install.packages('FactoMineR')"
RUN Rscript -e "install.packages('colorspace')"
RUN Rscript -e "install.packages('vegan')"
RUN Rscript -e "install.packages('optparse')"
RUN Rscript -e "install.packages('gplots')"
RUN Rscript -e "install.packages('fossil')"
RUN Rscript -e "install.packages('coin')"
RUN Rscript -e "install.packages('SNFtool')"
RUN Rscript -e "install.packages('devtools')"
RUN Rscript -e "library(devtools); install_github('igraph/rigraph')"
RUN Rscript -e "source('https://bioconductor.org/biocLite.R'); biocLite('sva')"

# INSTALL THE APP
USER genocrunch_user

# Create a new Rails project
WORKDIR /home/genocrunch_user
RUN ~/.rbenv/versions/2.3.1/bin/rails new genocrunch -d postgresql -B
WORKDIR /home/genocrunch_user/genocrunch
RUN GIT_CURL_VERBOSE=1 git clone https://git@c4science.ch/source/genocrunch-2.1.git /tmp/genocrunch
RUN rsync -r /tmp/genocrunch/ ./
RUN rm -r /tmp/genocrunch

# Install R/python scripts
USER root
RUN chmod 755 install.sh && ./install.sh
USER genocrunch_user

# Install gems
RUN ~/.rbenv/versions/2.3.1/bin/bundle install

# Get versions (print a json file with versions of R packages)
RUN lib/genocrunch_console/bin/get_version.py

# Configure the app
USER root
EXPOSE 3000
USER genocrunch_user

# config/config.yml
RUN cp config/config.yml.keep config/config.yml
RUN sed -i 's/data_dir:.*$/data_dir: \/home\/genocrunch_user\/genocrunch/g' config/config.yml
RUN sed -i 's/info_links:.*$/info_links: []/g' config/config.yml
RUN sed -i 's/user_confirmable:.*$/user_confirmable: false/g' config/config.yml

# config/initializers/devise.rb
RUN cp config/initializers/devise.rb.keep config/initializers/devise.rb
RUN sed -i 's/config.mailer_sender =.*$/config.mailer_sender = "noreply.genocrunch@gmail.com"/g' config/initializers/devise.rb

# config/environments/development.rb
RUN cp config/environments/development.rb.keep config/environments/development.rb
RUN sed -i 's/config.action_mailer.default_url_options =.*$/config.action_mailer.default_url_options = {:host => "localhost:3000"}/g' config/environments/development.rb
RUN sed -i 's/:address =>.*$/:address => "smtp.gmail.com",/g' config/environments/development.rb
RUN sed -i 's/:port =>.*$/:port => 587,/g' config/environments/development.rb
RUN sed -i 's/:domain =>.*$/:domain => "mail.google.com",/g' config/environments/development.rb
RUN sed -i 's/:user_name =>.*$/:user_name => "noreply.genocrunch@gmail.com",/g' config/environments/development.rb
RUN sed -i 's/:password =>.*$/:password => "email_password",/g' config/environments/development.rb
RUN sed -i 's/:authentication =>.*$/:authentication => :plain,/g' config/environments/development.rb
RUN sed -i 's/:enable_starttls_auto =>.*$/:enable_starttls_auto => true/g' config/environments/development.rb

# config/database.yml
RUN cp config/database.yml.keep config/database.yml
RUN sed -i 's/^.*username:.*$/  username: genocrunch_user/g' config/database.yml
RUN sed -i 's/database:.*$/database: genocrunch/g' config/database.yml
RUN sed -i 's/^.*password:.*$/  password: genocrunch_db_password/g' config/database.yml
RUN sed -i 's/^.*host:.*$/  host: hostaddress/g' config/database.yml

RUN cp db/seeds.rb.keep db/seeds.rb

# Run Genocrunch
CMD source /home/genocrunch_user/.bashrc && RAILS_ENV=development ruby bin/delayed_job -n 2 start; /home/genocrunch_user/genocrunch/bin/rails server
