# Geodesic

*definition:* relating to or denoting the shortest possible line between two points on a sphere or other curved surface.

## Quickstart

Install the geodesic client, if you haven't already:
```
curl https://geodesic.sh | bash
```

Run the geodesic shell:
```
geodesic
```

Configure your AWS credentials in `/geodesic/state/aws`

Run `assume-role $role` where $role is the one you configured in your AWS configuration.

### Bringing up a cluster

```
cloud configure
cloud up
cloud init
```

### Connecting to the cluster
```
cloud ssh
```

### Destroying a cluster
```
cloud down
```

### Pulling down an existing cluster
```
cloud config pull \
  CLUSTER_STATE_BUCKET=config.demo.dev.cloudposse.com \
  CLUSTER_STATE_BUCKET_REGION=us-east-1
```

### Using `kubectl` outside of geodesic

Have `kubectl installed on your local machine? Then after setting up `geodesic`, you can export the `KUBECONFIG` environment variable to point to the one in `geodesic`. Note, `kubectl` does not support `~` in for the `HOME` directory.
```
export KUBECONFIG="${HOME}/.geodesic/kubernetes/kubeconfig" 
```
