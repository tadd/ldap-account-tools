FROM debian:stable

ENV DEBIAN_FRONTEND="noninteractive"

RUN apt-get update
RUN apt-get install -y apt-utils

RUN apt-get install -y \
  slapd ldap-utils \
  git ruby \
  ruby-dev libcrack2 libcrack2-dev libffi-dev gcc make

RUN gem install bundler

ENV BUNDLE_CACHE_DIR /tmp/bundle-cache

RUN mkdir -p ${BUNDLE_CACHE_DIR}
RUN mkdir -p ${BUNDLE_CACHE_DIR}/lib/ldap_account_tools/util

ADD Gemfile ${BUNDLE_CACHE_DIR}/
ADD Gemfile.lock ${BUNDLE_CACHE_DIR}/
ADD ldap-account-tools.gemspec ${BUNDLE_CACHE_DIR}/
ADD lib/ldap_account_tools/version.rb ${BUNDLE_CACHE_DIR}/lib/ldap_account_tools/version.rb
ADD lib/ldap_account_tools/util ${BUNDLE_CACHE_DIR}/lib/ldap_account_tools/util
RUN cd ${BUNDLE_CACHE_DIR} \
 && bundle install --path vendor/bundle \
 && bundle package --all

ADD docker/testspace-setup.bash /opt/setup.bash

RUN bash /opt/setup.bash

RUN rm -rf /var/lib/apt/lists/*

ADD docker/testspace-run.bash /opt/run.bash

CMD [ "bash", "/opt/run.bash" ]
