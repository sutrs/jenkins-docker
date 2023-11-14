# Pull base image
# ---------------
FROM jenkins/jenkins:lts

# Author
# ------
MAINTAINER Raja Sekhar <rajasekhar.tummalapalli@gmail.com, @Raja>

# Build the container
# -------------------
USER root

# install wget
RUN apt update && apt install -y wget net-tools openssh-server vim  && \
    apt install -y --no-install-recommends gnupg curl ca-certificates apt-transport-https && \
    curl -sSfL https://apt.octopus.com/public.key | apt-key add - && \
    sh -c "echo deb https://apt.octopus.com/ stable main > /etc/apt/sources.list.d/octopus.com.list" && \
    apt update && apt install -y octopuscli
RUN jenkins-plugin-cli --plugins octopusdeploy:3.1.6


RUN apt-get update && \
    apt-get -y install apt-transport-https \
      ca-certificates \
      gnupg2 \
      software-properties-common && \
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg > /tmp/dkey; apt-key add /tmp/dkey && \
    add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
      $(lsb_release -cs) \
      stable" && \
    apt-get update && apt-get install -y docker-ce-cli


#RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
RUN service ssh start

#Update the username and password
ENV JENKINS_USER admin
ENV JENKINS_PASS admin

# allows to skip Jenkins setup wizard
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

# install jenkins plugins
COPY ./jenkins-plugins.txt /usr/share/jenkins/jenkins-plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/jenkins-plugins.txt

#RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/jenkins-plugins.txt
#RUN while read i ; \
#                do /usr/local/bin/install-plugins.sh $i ; \
#        done < /usr/share/jenkins/jenkins-plugins


#id_rsa.pub file will be saved at /root/.ssh/
RUN ssh-keygen -f /root/.ssh/id_rsa -t rsa -N ''
#RUN ssh-keygen -t rsa -f jenkins_agent


# Jenkins runs all grovy files from init.groovy.d dir
# use this for creating default admin user
COPY default-user.groovy /usr/share/jenkins/ref/init.groovy.d/

#VOLUME /var/jenkins_home



# get maven 3.2.2
RUN wget --no-verbose -O /tmp/apache-maven-3.5.4-bin.tar.gz http://apache.cs.utah.edu/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz

# verify checksum
# RUN echo "35c39251d2af99b6624d40d801f6ff02 /tmp/apache-maven-3.4.0-bin.tar.gz" | md5sum -c

# install maven
RUN tar xzf /tmp/apache-maven-3.5.4-bin.tar.gz -C /opt/
RUN ln -s /opt/apache-maven-3.5.4 /opt/maven
RUN ln -s /opt/maven/bin/mvn /usr/local/bin
RUN rm -f /tmp/apache-maven-3.5.4-bin.tar.gz
ENV MAVEN_HOME /opt/maven

RUN chown -R jenkins:jenkins /opt/maven

# install git (MH: Git should be preinstalled in the original Jenkins docker image prep)
# RUN apt-get install -y git

# remove download archive files
RUN apt-get clean


USER jenkins
EXPOSE 22
EXPOSE 8080
EXPOSE 50000
#CMD ["/usr/sbin/sshd", "-D"]
