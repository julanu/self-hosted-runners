# Github Runner based on Redhat Runner Image

## Helm repository
The repository can be added with:
```
helm repo add openshift-actions-runner https://redhat-actions.github.io/openshift-actions-runner-chart
```

The packaged charts can be browsed [here](https://github.com/redhat-actions/openshift-actions-runner-chart/tree/release-chart/packages).

## Installing runners
1. Runners can be scoped to an **organization** or a **repository**. Decide what the scope of your runner will be.
2. Create a GitHub Personal Access Token as per the PAT instructions in the [runner image README](https://github.com/redhat-actions/openshift-actions-runner#pat-guidelines).
3. You can clone this repository and reference the chart's directory. This allows you to modify the chart if necessary.

```bash
# For an org runner, this is the org. For a repo runner, this is the repo owner (org or user).
export GITHUB_OWNER=
export GITHUB_PAT=
# Your release name
export RELEASE_NAME=actions-runners

# If you cloned the repository (eg. to edit the chart)
helm install $RELEASE_NAME ./self-hosted-runners --set-string githubPat=$GITHUB_PAT \
&& echo "---------------------------------------" \
&& helm get manifest $RELEASE_NAME | kubectl get -f -

# Update Helm release after modifying values.yaml
helm upgrade -f ./self-hosted-runners/values.yaml actions-runner ./self-hosted-runners/
```
The runners should show up under `Settings > Actions > Self-hosted runners` shortly afterward.

## Values
You can override the default values such as resource limits and replica counts or inject environment variables by passing `--set` or `--set-string` to the `helm install` command.
Refer to the [`values.yaml`](./values.yaml) for values that can be overridden.

## Troubleshooting
The resources are labeled with `app.kubernetes.io/instance={{ .Release.Name }}`, so you can view all the resources with:
```bash
kubectl get all,secret -l=app.kubernetes.io/instance=$RELEASE_NAME
```
