# Set base image to build on top to
FROM	debian:jessie

# Set labels for documentations
LABEL	maintainer="pupupulp"

# Set to noninteractive to skip configurable/interactive installations : Passed
ENV	DEBIAN_FRONTEND noninteractive

# Set Firebird 3.0 environment variables : Passed
ENV	FB_URL=https://github.com/FirebirdSQL/firebird/releases/download/R3_0_3
ENV	FB_DIST=Firebird-3.0.3.32900-0.amd64.tar.gz
ENV	FB_SETUP_DIR=/home/fb
ENV FB_DB_ALIAS=cvendb
ENV FB_DB_PATH=/databases/cven.fdb

# Install package dependencies : Passed
RUN	apt-get update \
	&& apt-get install -qy \
		wget \
		libicu52 \
		libtommath0 \
		libicu-dev \
		libtommath-dev \
		netcat

# Install Firebird 3.0 from github repository : Passed
RUN	mkdir ${FB_SETUP_DIR} && cd ${FB_SETUP_DIR} \
	&& wget ${FB_URL}/${FB_DIST} \
	&& tar xzvpf ${FB_DIST} \
	&& cd Firebird* \
	&& ./install.sh -silent

# Add configs to firebird configuration files : Passed
RUN	echo "DatabaseAccess = Full" >> /opt/firebird/firebird.conf \
	&& echo "ServerMode = SuperClassic" >> /opt/firebird/firebird.conf \
	&& echo "WireCrypt = Enabled" >> /opt/firebird/firebird.conf \
	&& echo "AuthServer = Legacy_Auth, Srp, Win_Sspi" >> /opt/firebird/firebird.conf \
	&& echo "UserManager = Legacy_UserManager, Srp" >> /opt/firebird/firebird.conf \
	&& echo "${FB_DB_ALIAS}=${FB_DB_PATH}" >> /opt/firebird/databases.conf

# Set volume for container : Passed
VOLUME ["/databases"]

# Set container port : Passed
EXPOSE	"3050"

# Set Healthcheck environment variables : Passed
ENV	FB_ISQL=/opt/firebird/bin/isql
ENV	HOME_IP=127.0.0.1

# Make script file for docker Healthcheck : Passed
RUN	touch /opt/firebird/docker-healthcheck.sh

# Set Healthcheck script content
RUN	echo " \
		#!/usr/bin/env bash \
		if [[ -z "${FB_USER}" || -z "${FB_PASS}" || -z "${FB_DB}" ]]; then \
			nc -z "${HOME_IP}" "${FB_PORT}" < /dev/null \
			exit $? \
		else \
			FB_HEALTH=` \
				${FB_ISQL} -user "{FB_USER}" -password "${FB_PASS}" "${HOME_IP}/${FB_PORT}:${FB_DB}" << "EOF" \
				SHOW DATABASE; << "EOF" \
			` \
			exit $? \
		fi \
	" >> ${FB_DIR}/docker-healthcheck.sh

# Healthcheck for Firebird 3.0 service
HEALTHCHECK CMD ["/opt/firebird/docker-healthcheck.sh || exit 1"]

# Remove installation files and dependencies : Passed
RUN	rm -rf ${FB_SETUP_DIR} \
	&& apt-get purge -qy --auto-remove \
		wget \
	&& rm -rf /var/lib/apt/lists/*

# Set environment work dir : Passed
WORKDIR	/opt/firebird/bin

# Start firebird service : Passed
CMD	["./fbguard"]

