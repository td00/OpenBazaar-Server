FROM ubuntu:15.04
MAINTAINER eiabea <developer@eiabea.com>

# Install required Debian packages
RUN set -ex \
  && echo "deb http://us.archive.ubuntu.com/ubuntu vivid main universe" | tee -a /etc/apt/sources.list \
  # Launching apt-get Stuff
  # Watch the dependencies of the packages! 
  && apt-get update -q \
  && apt-get autoremove -q -y \
  && apt-get install -q -y build-essential libssl-dev libffi-dev python-dev openssl python-pip libzmq3-dev libsodium-dev autoconf automake pkg-config libtool git \
  && apt-get clean autoclean -q -y \
  && rm -rf /var/lib/apt/lists/* /var/lib/apt/lists/partial/* /tmp/* /var/tmp/*

# Download github Stuff from zeromq/libzmq
RUN git clone https://github.com/zeromq/libzmq
WORKDIR /libzmq
# Install libzmq from github
RUN ./autogen.sh
RUN ./configure
# Make install (libzmq)
RUN make
RUN make install
RUN ldconfig

# Install cryptography
WORKDIR /
RUN pip install cryptography

# Install Openbazaar-Server from github
RUN git clone https://github.com/td00/OpenBazaar-Server.git
WORKDIR /OpenBazaar-Server/
# Run pip stuff with requirements.txt @ /OpenBazaar-Server/
RUN pip install -r requirements.txt -r test_requirements.txt
RUN make

# Copy entrypoint script and mark it executable
COPY ./docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Create Openbazaar user and set correct permissions
RUN adduser --disabled-password --gecos \"\" openbazaar
RUN chown -R openbazaar:openbazaar /OpenBazaar-Server
# Mount OpenBazaar Folders
VOLUME /root/.openbazaar
VOLUME /ssl
# Define a entry point
ENTRYPOINT ["/docker-entrypoint.sh"]
# Launch command
CMD ["python", "openbazaard.py", "start"]
