# Geodesic

## Quickstart

Install the geodesic client:
```
curl geodesic.sh | bash
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
cloud deploy demo
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
