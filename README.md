# Geodesic

*definition:* relating to or denoting the shortest possible line between two points on a sphere or other curved surface.

## Quickstart

Install the geodesic client, if you haven't already:
```
sudo bash
docker run --rm -it cloudposse/geodesic:latest > /usr/local/bin/geodesic && \
  chmod 755 /usr/local/bin/geodesic
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
