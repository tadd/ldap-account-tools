FROM debian:stable

ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get update
RUN apt-get install -y apt-utils

RUN apt-get install -y \
  slapd ldap-utils \
  git ruby \
  ruby-dev libcrack2 libcrack2-dev libffi-dev gcc make

RUN gem install bundler

ADD docker/testspace-setup.bash /opt/setup.bash

RUN bash /opt/setup.bash

# RUN rm -rf /var/lib/apt/lists/*

ADD docker/testspace-run.bash /opt/run.bash

CMD [ "bash", "/opt/run.bash" ]
