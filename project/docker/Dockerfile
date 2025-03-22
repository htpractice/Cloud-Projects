FROM jenkins/jenkins:lts

# Switch to the root user to install packages
USER root

# Install dependencies and sudo
RUN apt-get update && \
    apt-get install -y unzip curl sudo apt-transport-https ca-certificates gnupg-agent software-properties-common && \
    apt-get clean

# Download and install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && \
    unzip /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    rm -rf /tmp/awscliv2.zip /tmp/aws

# Install Docker using the script
RUN curl https://get.docker.com/ > dockerinstall && chmod 777 dockerinstall && ./dockerinstall && rm dockerinstall

# Add Jenkins user to the docker group
RUN usermod -aG docker jenkins

# Allow Jenkins user to use sudo without a password
RUN echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Switch back to the Jenkins user
USER jenkins