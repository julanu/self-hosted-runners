# Github Runner based on Redhat Runner Image

Github Runners that you can spin up for your Github organization or you can have multiple deployments for each of your repositories.
Simply follow the installation guide and add a couple of variables and you'll have your build agents ready in a couple of minutes.

Supports:
- Runners for user repositories
- Runners for organization repositories
- Custom built Docker image for runners
- Authentication against DockerHub registry


In this repository the `GITHUB_OWNER` and `namespace: self-hosted-runners` is set from the `values.yaml` file, the namespace must be created beforehand. The Docker image for the runners to use is based on the Dockerfile present in this repository and is published to a private DockerHub repository, you can update `runnerImage` and `runnerTag`.

### Values
You can override the default values such as resource limits and replica counts or inject environment variables by passing `--set` or `--set-string` to the `helm install` command.
Refer to the [`values.yaml`](./values.yaml) for values that can be overridden.

### Pre-requisites and installing runners
1. Runners can be scoped to an **organization** or a **repository**. Decide what the scope of your runner will be.
2. Create a GitHub Personal Access Token as per the PAT instructions in the [runner image README](https://github.com/redhat-actions/openshift-actions-runner#pat-guidelines). To be more specific the PAT will only need full access on the `repo` scope. If the runner will be for an organization, the token must also have the `admin:org` permission scope
3. Creating a Kubernetes secret to extract the `.dockerconfigjson` value to authenticate against the registry, or obtain it by authenticating through the CLI on Docker Hub
4. You can clone this repository and reference the chart's directory. This allows you to modify the chart if necessary.

### First method:
Login to DockerHub. When prompted, enter your Docker ID, and then the credential you want to use (access token, or password). The login process creates or updates a config.json file that holds an authorization token. 
```bash
# View the config.json file:
docker login -u <your_username>
cat ~/.docker/config.json
# The output contains a section similar to this:

{
    "auths": {
        "https://index.docker.io/v1/": {
            "auth": "c3R...zE2"
        }
    }
}
# You will be interested in in the value of the "auth" key
```
### Second method:
Getting your Docker access token if you are authenticating against DockerHub, it will create a Kubernetes secret in the default namespace.
```bash
kubectl create secret docker-registry regcred \
--docker-server=https://index.docker.io/v1/ \
--docker-username= \
--docker-password= \
--docker-email=

# Get the secret, you will be interest in the value under:
# data:
#   .dockerconfigjson:
# Copy that, you will need it later when installing the Helm chart, after that you can delete it
kubectl get secret regcred --output=yaml
kubectl delete secret regcred
```
After that in the `values.yaml` or by using `--set-string dockerToken=` you can set the value .

### Installing
```bash
export GITHUB_OWNER=        # For an org runner, this is the org. For a repo runner, this is the repo owner
export GITHUB_REPO=         # You can omit the repository for an org level runner
export GITHUB_PAT=
export DOCKER_PAT=
export RELEASE_NAME=actions-runners

# If you cloned the repository (eg. to edit the chart)
helm install $RELEASE_NAME ./self-hosted-runners \
--set-string githubPat=$GITHUB_PAT \
--set-string githubOwner=$GITHUB_OWNER \
--set-string githubRepository=$GITHUB_REPO \
&& echo "---------------------------------------" \
&& helm get manifest $RELEASE_NAME | kubectl get -f -

# Update Helm release after modifying values.yaml, by specifying the namespace where your release is installed
helm upgrade -f ./self-hosted-runners/values.yaml actions-runner ./self-hosted-runners/ -n self-hosted-runners
```

The runners should show up under `Settings > Actions > Self-hosted runners` shortly afterward.

### - Troubleshooting
The resources are labeled with `app.kubernetes.io/instance={{ .Release.Name }}`, so you can view all the resources with:
```bash
kubectl get all,secret -l=app.kubernetes.io/instance=$RELEASE_NAME
```
