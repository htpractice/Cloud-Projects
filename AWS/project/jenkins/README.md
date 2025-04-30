# Running Jenkins
sudo docker run --name myjenkins -p 8080:8080 -p 50000:50000 -v /var/jenkins_home jenkins/jenkins:lts

# Running Jenkins

To run the Jenkins container with the context path `/jenkins`, use the following Docker command:

```sh
sudo docker run -itd --name myjenkins -p 8080:8080 -p 50000:50000 -v /var/jenkins_home:/var/jenkins_home -e JENKINS_OPTS="--prefix=/jenkins" jenkins/jenkins:lts


### Explanation:
- **Environment Variable**: `-e JENKINS_OPTS="--prefix=/jenkins"` sets the `JENKINS_OPTS` environment variable to configure Jenkins to use the context path `/jenkins`.
- **Image**: `jenkins/jenkins:lts` specifies the Jenkins image with the Long-Term Support (LTS) tag.
- **Container Name**: `--name myjenkins` names the container `myjenkins`.
- **Port Mapping**: `-p 8080:8080` maps port 8080 on the host to port 8080 in the container, and `-p 50000:50000` maps port 50000 on the host to port 50000 in the container.
- **Volume Mapping**: `-v /var/jenkins_home:/var/jenkins_home` mounts the host directory `/var/jenkins_home` to the container directory `/var/jenkins_home` to persist Jenkins data.

This command will start the Jenkins container and make it accessible on port 8080 of the host machine with the context path `/jenkins`.
### Explanation:
- **Environment Variable**: `-e JENKINS_OPTS="--prefix=/jenkins"` sets the `JENKINS_OPTS` environment variable to configure Jenkins to use the context path `/jenkins`.
- **Image**: `jenkins/jenkins:lts` specifies the Jenkins image with the Long-Term Support (LTS) tag.
- **Container Name**: `--name myjenkins` names the container `myjenkins`.
- **Port Mapping**: `-p 8080:8080` maps port 8080 on the host to port 8080 in the container, and `-p 50000:50000` maps port 50000 on the host to port 50000 in the container.
- **Volume Mapping**: `-v /var/jenkins_home:/var/jenkins_home` mounts the host directory `/var/jenkins_home` to the container directory `/var/jenkins_home` to persist Jenkins data.

This command will start the Jenkins container and make it accessible on port 8080 of the host machine with the context path `/jenkins`.