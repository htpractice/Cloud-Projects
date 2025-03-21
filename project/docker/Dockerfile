FROM jenkins/jenkins:lts

# Switch to the root user to install packages
USER root

# Install dependencies and pipx
RUN apt-get update && \
    apt-get install -y python3-pip python3-venv && \
    pip3 install pipx && \
    pipx ensurepath && \
    apt-get clean

# Install AWS CLI using pipx
RUN pipx install awscli

# Switch back to the Jenkins user
USER jenkins