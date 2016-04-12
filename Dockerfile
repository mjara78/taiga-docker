FROM debian:jessie
MAINTAINER "Andrey Arapov <andrey.arapov@nixaid.com>"

# To avoid problems with Dialog and curses wizards
ENV DEBIAN_FRONTEND noninteractive

# OS & Python env deps for taiga-back
RUN apt-get update -qq \
    && apt-get install -y -- build-essential binutils-doc autoconf flex \
        bison libjpeg-dev libfreetype6-dev zlib1g-dev libzmq3-dev \
        libgdbm-dev libncurses5-dev automake libtool libffi-dev curl git \
        tmux gettext python3.4 python3.4-dev python3-pip libxml2-dev \
        libxslt-dev libpq-dev virtualenv \
        nginx \
    && rm -rf -- /var/lib/apt/lists/*

RUN pip3 install circus gunicorn

# Create taiga user
ENV USER taiga
ENV UID 1000
ENV GROUP www-data
ENV HOME /home/$USER
ENV DATA /opt/taiga
RUN useradd -u $UID -m -d $HOME -s /usr/sbin/nologin -g $GROUP $USER
RUN mkdir -p $DATA $DATA/media $DATA/static $DATA/logs /var/log/taiga \
    && chown -Rh $USER:$GROUP $DATA /var/log/taiga

# Install taiga-back
USER $USER
WORKDIR $DATA
RUN git clone -b stable https://github.com/taigaio/taiga-back.git $DATA/taiga-back \
    && virtualenv -p /usr/bin/python3.4 venvtaiga \
    && . venvtaiga/bin/activate \
    && cd $DATA/taiga-back \
    && pip3 install -r requirements.txt \
    && deactivate

# Install taiga-front (compiled)
RUN git clone -b stable https://github.com/taigaio/taiga-front-dist.git $DATA/taiga-front-dist

USER root

# Cleanups
RUN rm -f /etc/nginx/sites-enabled/default

# Copy template seeds
COPY seeds/*.tmpl /tmp/

VOLUME [ "$DATA/static", \
         "$DATA/media" ]

COPY launch /
CMD /launch
