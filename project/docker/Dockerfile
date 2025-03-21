FROM jenkins/jenkins:lts

# Switch to the root user to install packages
USER root

# Install dependencies, Docker, and sudo
RUN apt-get update && \
    apt-get install -y unzip curl sudo && \
    apt-get install -y apt-transport-https ca-certificates gnupg-agent software-properties-common && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get install -y docker-ce docker-ce-cli containerd.io && \
    apt-get clean

# Download and install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && \
    unzip /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    rm -rf /tmp/awscliv2.zip /tmp/aws

# Add Jenkins user to the docker group
RUN usermod -aG docker jenkins

# Switch back to the Jenkins user
USER jenkins