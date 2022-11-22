# FROM quay.io/redhat-github-actions/runner:latest as runner
FROM --platform=linux/arm64 fedora:33 as base_builder

# Adapted from https://github.com/bbrowning/github-runner/blob/master/Dockerfile
RUN dnf -y upgrade --security && \
    dnf -y --setopt=skip_missing_names_on_install=False install \
    curl git jq hostname procps findutils which openssl unzip wget dnf-plugins-core && \
    dnf clean all

# To run Docker in Docker
RUN sudo dnf -y install dnf-plugins-core && \
    dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo && \
    dnf -y install docker-ce docker-ce-cli containerd.io
    # systemctl start docker

# Kubectl & Helm
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl" && \
    curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl.sha256" && \
    echo "$(<kubectl.sha256) kubectl" | sha256sum --check && \
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    kubectl version --client && \
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Terraform 1.1
RUN wget "https://releases.hashicorp.com/terraform/1.1.1/terraform_1.1.1_linux_arm64.zip" -O temp.zip \ 
    && unzip temp.zip \
    && chmod +x ./terraform \
    && mv ./terraform /usr/bin

# Python
RUN dnf install -y openssl-devel python3-pip python3 python3-devel python3

# The UID env var should be used in child Containerfile.
ENV UID=1000
ENV GID=0
ENV USERNAME="runner"

FROM base_builder as conf_builder

# Create our user and their home directory
RUN useradd -m $USERNAME -u $UID
# This is to mimic the OpenShift behaviour of adding the dynamic user to group 0.
RUN usermod -G 0 $USERNAME
ENV HOME /home/${USERNAME}
WORKDIR /home/${USERNAME}

# Override these when creating the container.
ARG GITHUB_PAT_
ARG GITHUB_OWNER_
ARG GITHUB_REPOSITORY_
ARG RUNNER_WORKDIR /home/${USERNAME}/_work_
ARG RUNNER_GROUP_
ARG RUNNER_LABELS_
ARG EPHEMERAL_

ENV GITHUB_PAT=$GITHUB_PAT_
ENV GITHUB_OWNER=$GITHUB_PAT_
ENV GITHUB_REPOSITORY=$GITHUB_PAT_
ENV RUNNER_WORKDIR="/home/${USERNAME}/_work"
ENV RUNNER_GROUP=$GITHUB_PAT_
ENV RUNNER_LABELS=$GITHUB_PAT_
ENV EPHEMERAL=$GITHUB_PAT_

# Allow group 0 to modify these /etc/ files since on openshift, the dynamically-assigned user is always part of group 0.
# Also see ./uid.sh for the usage of these permissions.
RUN chmod g+w /etc/passwd && \
    touch /etc/sub{g,u}id && \
    chmod -v ug+rw /etc/sub{g,u}id

COPY --chown=${USERNAME}:0 ./scripts/* ./scripts/

RUN chmod +x ./scripts/get-runner-release.sh && ./scripts/get-runner-release.sh && \
    chmod +x ./bin/installdependencies.sh && sudo ./bin/installdependencies.sh

# Set permissions so that we can allow the openshift-generated container user to access home.
# https://docs.openshift.com/container-platform/3.3/creating_images/guidelines.html#openshift-container-platform-specific-guidelines
RUN chown -R ${USERNAME}:0 /home/${USERNAME}/ && \
    chgrp -R 0 /home/${USERNAME}/ && \
    chmod -R g=u /home/${USERNAME}/

COPY --chown=${USERNAME}:0 ./scripts/uid.sh ./scripts/register.sh ./scripts/get_github_app_token.sh ./
COPY --chown=${USERNAME}:${USERNAME} ./scripts/entrypoint.sh ./

FROM conf_builder as source

RUN chmod u+x ./scripts/entrypoint.sh

USER $UID

ENTRYPOINT ["sh", "./entrypoint.sh"]
