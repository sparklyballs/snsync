ARG ALPINE_VER="3.12"
ARG RUBY_VER="2.7.1-slim-buster"
FROM alpine:${ALPINE_VER} as fetch-stage

############## fetch stage ##############

# install fetch packages
RUN \
	apk add --no-cache \
		bash \
		curl \
		git

# set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# set workdir
WORKDIR /syncing-server

# fetch version file
RUN \
	set -ex \
	&& curl -o \
	/tmp/version.txt -L \
	"https://raw.githubusercontent.com/sparklyballs/versioning/master/version.txt"

# fetch source code
# hadolint ignore=SC1091
RUN \
	. /tmp/version.txt \
	&& set -ex \
	&& mkdir -p \
		app \
	&& curl -o \
		/tmp/snsync.tar.gz -L \
		"https://github.com/standardnotes/syncing-server/archive/${SNSYNC_COMMIT}.tar.gz" \
	&& tar xf \
		/tmp/snsync.tar.gz -C \
		/syncing-server --strip-components=1


FROM ruby:${RUBY_VER}

# set workdir
WORKDIR /syncing-server

# add artifacts from fetch stage
COPY --from=fetch-stage /syncing-server /syncing-server

# install build packages
RUN \
	apt-get update \
	&& apt-get install -y \
	--no-install-recommends \
		git \
		build-essential \
	\
	# install runtime packages
	\
	&& apt-get install -y \
	--no-install-recommends \
		libmariadb-dev \
	# install gem and bundle packages
	\
	&& gem install bundler \
	&& bundle install \
	\
	# cleanup
	\
	&& apt-get remove --purge -y \
		build-essential \
		git \
	&& apt-get autoremove -y \
	&& rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/*

