# Geodesic

## Quickstart

Install the geodesic client:
```
make install
```

Run the geodesic shell:
```
geodesic
```

Configure your AWS credentials in `/geodesic/config/aws`

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

