FROM jenkins/jenkins:lts

# Switch to the root user to install packages
USER root

# Install AWS CLI
RUN apt-get update && \
    apt-get install -y python3-pip && \
    pip3 install awscli && \
    apt-get clean

# Switch back to the Jenkins user
USER jenkins