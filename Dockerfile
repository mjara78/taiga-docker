FROM debian:buster
MAINTAINER "Manuel Jara <manuel.jara.oliver@gmail.com>"
EXPOSE 80

# To avoid problems with Dialog and curses wizards
ENV DEBIAN_FRONTEND noninteractive

# OS & Python env deps for taiga-back
RUN apt-get update \
    && apt-get install -y -- build-essential binutils-doc autoconf flex \
        bison libjpeg-dev libfreetype6-dev zlib1g-dev libzmq3-dev \
        libgdbm-dev libncurses5-dev automake libtool libffi-dev curl git \
        tmux gettext python3 python3-dev python3-pip libxml2-dev \
        libxslt-dev virtualenvwrapper \
        nginx && \
        rm -rf -- /var/lib/apt/lists/*

RUN pip3 install circus gunicorn

# Create taiga user
ENV USER taiga
ENV UID 1000
ENV GROUP www-data
ENV HOME /home/$USER
ENV DATA /opt/taiga
RUN useradd -u $UID -m -d $HOME -s /usr/sbin/nologin -g $GROUP $USER
RUN mkdir -p $DATA $DATA/media $DATA/static $DATA/logs /var/log/taiga \
    && chown -Rh $USER:$GROUP /var/log/taiga

WORKDIR $DATA

RUN ln -svf /bin/bash /bin/sh

# Install taiga-back
RUN git clone --depth 1 -b 5.5.9 https://github.com/taigaio/taiga-back.git taiga-back \
    && source /usr/share/virtualenvwrapper/virtualenvwrapper.sh \
    && mkvirtualenv -p /usr/bin/python3 venvtaiga \
    && workon venvtaiga \
    && cd taiga-back \
    && pip3 install --upgrade setuptools \
    && pip3 install -r requirements.txt \
	&& pip3 install django_smtp_ssl \
    && deactivate

# Install taiga-front (compiled)
RUN git clone --depth 1 -b 5.5.10-stable https://github.com/taigaio/taiga-front-dist.git taiga-front-dist
COPY robots.txt taiga-front-dist/dist/robots.txt

RUN apt-get update \
    && apt-get install -y nano vim

USER root

# Cleanups
RUN rm -f /etc/nginx/sites-enabled/default

# Copy template seeds
COPY seeds/*.tmpl /tmp/

VOLUME [ "$DATA/static", "$DATA/media" ]

COPY launch /
CMD /launch
