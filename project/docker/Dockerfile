FROM jenkins/jenkins:lts

# Switch to the root user to install packages
USER root

# Install dependencies
RUN apt-get update && \
    apt-get install -y unzip curl && \
    apt-get clean

# Download and install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && \
    unzip /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install && \
    rm -rf /tmp/awscliv2.zip /tmp/aws

# Switch back to the Jenkins user
USER jenkins