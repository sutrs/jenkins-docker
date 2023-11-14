FROM ubuntu:18.04

LABEL maintainer="Raja Sekhar <rajasekhar.tummalapalli@gmail.com>"

ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG JENKINS_AGENT_HOME=/home/${user}

ENV JENKINS_AGENT_HOME ${JENKINS_AGENT_HOME}

RUN groupadd -g ${gid} ${group} \
    && useradd -d "${JENKINS_AGENT_HOME}" -u "${uid}" -g "${gid}" -m -s /bin/bash "${user}"


RUN apt-get update \
    && apt-get install --no-install-recommends -y openssh-server vim git \
# Install JDK 8 (latest stable edition at 2019-04-01)
    && apt-get install -qy openjdk-11-jdk \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i /etc/ssh/sshd_config \
        -e 's/#PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/#RSAAuthentication.*/RSAAuthentication yes/'  \
        -e 's/#PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/#SyslogFacility.*/SyslogFacility AUTH/' \
        -e 's/#LogLevel.*/LogLevel INFO/' && \
    mkdir /var/run/sshd


# install wget
RUN apt update && apt install -y wget curl && \
    RUN curl -sL https://deb.nodesource.com/setup_14.x | bash
RUN apt install -y nodejs

#To be able to compile native addons from npm you’ll need to install the development tools:
RUN apt install -y build-essential

#Installing Node.js and npm using NVM
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.3/install.sh | bash

#RUN export NVM_DIR="$HOME/.nvm" [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"



VOLUME "${JENKINS_AGENT_HOME}" "/tmp" "/run" "/var/run"
WORKDIR "${JENKINS_AGENT_HOME}"

#COPY setup-sshd /usr/local/bin/setup-sshd
COPY --chown=jenkins:jenkins slave.jar /home/jenkins
COPY --chown=jenkins:jenkins remoting.jar /home/jenkins
COPY --chown=jenkins:jenkins ./.ssh /home/jenkins/.ssh/



# Standard SSH port
EXPOSE 22
#ENTRYPOINT ["setup-sshd"]

CMD ["/usr/sbin/sshd", "-D"]
