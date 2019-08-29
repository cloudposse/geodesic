## Operating on Codefresh Pipelines via Command Line Tools

This Readme describes how to operate on Codefresh Pipelines using 
command line tools. Familiarity with Codefresh Pipelines is assumed.

Prerequisites:
- You must have an account with `admin` access on Codefresh
- You must have created a project on Codefresh

You will also need to have an API key, which you can create as
explained [below](#setting-up-api-key).

### Pipeline Spec Files

Pipelines can be defined by "pipeline spec files", which are YAML files
containing [pipeline specs](https://codefresh-io.github.io/cli/pipelines/spec/).
Note, however, that the documentation is likely out of date (by Codefresh's
own admission) and the best reference for the current pipeline spec is
what is downloaded by `codefresh get pipeline`.

This Readme uses YAML-format pipeline specs stored in files with `.yaml`
extensions. It is possible to use other formats, such as JSON, but that
is beyond our scope.

### Setting up an API key

To interact with Codefresh remotely, you need an API key. You can get one from
the Codefresh web UI under [User Settings](https://g.codefresh.io/user/settings).

There are different ways to install and use it, as explained via
`codefresh auth help`. Probably the most secure way is to store
the key in a password manager like 1Password or in `chamber` and 
set the environment variable `CF_API_KEY` with it as needed.


### Pipeline and Trigger secrets

Codefresh allows you to set "secrets" at the Pipeline and Trigger level. 
Secrets are encrypted and not displayed. However, if you are defining your
pipelines and their associated triggers using files that will be checked
into Git, you should not use pipeline or trigger secrets, because you risk
either deleting them during an update or exposing them by checking them
into Git by mistake. 

You can, instead, use Project secrets, which are available to the pipelines
by default, or you can import secrets via [Shared Configurations](https://g.codefresh.io/account-admin/account-conf/shared-config)
defined under Account Settings. Simply add the name of the Shared Configuration
to the `spec.contexts` array of the pipeline.

### Downloading Codefresh Pipelines

##### **Using `codefresh` CLI tool**

You can download pipeline specs from Codefresh using the [Codefresh CLI](https://codefresh-io.github.io/cli/pipelines/)
```
codefresh get pipelines -o yaml [id..]
```
where `id` is a pipeline name or ID string. Generally you will use a full
pipeline name, which is of the form `project/pipeline`. So for the `build`
pipeline in the `Geodesic` project, the pipeline name should be 
`Geodesic/build`. It will display on the web UI as the "build" pipeline under
the "Geodesic" project

##### **Using `codefresh-pipeline` CLI tool**

The `codefresh-pipeline` tool in Geodesic provides some helpful enhancements 
to the Codefresh CLI tool. 

The primary enhancement is that `codefresh-pipeline` automatically removes
any read-only parameters from downloaded pipeline specs so that the resulting
pipeline file can easily be used as the basis for future uploads, and 
so that comparisons between installed and proposed pipelines do not show
meaningless (to developers) changes.

By default, `codefresh-pipeline` saves downloaded pipelines in YAML files with
`.pip` extensions ("pip" is Codefresh's abbreviation for "pipeline"). 
Downloaded files are given ".pip" extensions so as not to accidentally overwrite 
definition files for uploading, which should have `.yaml` extensions. 

See the `codefresh-pipeline` usage (available by executing `codefresh-pipeline`
with no arguments) for the best documentation. 

### Uploading Codefresh Pipelines

Use the `codefresh` CLI tool to create or modify pipelines from a pipeline
spec, which should be in a file with a `.yml` or `yaml` filename extension.

Codefresh enforces a distinction between creating and modifying pipelines.
- If a pipeline exists, you must use `replace` to modify it.
    ```
    codefresh replace -f pipeline.yaml
    ```

- If a pipeline does not exist, you must use `create` to create it.
    ```
    codefresh create -f pipeline.yaml
    ```

### Comparing Codefresh Pipelines

You can compare the current pipeline spec in use by Codefresh with a local
spec file, to see if one or the other is out of date and to see what would
change if you replaced the pipeline in use with the one defined in the 
spec file. 

```text
codefresh-pipeline compare pipeline.yaml
```

If there are no changes, the tool will output
```text
* No changes
```

If there are changes, the existing and proposed pipeline specs will be
displayed side-by-side, with change indicators between the two sides.
Sometimes the changes can be hard to see in the side-by-side output. Look
for the `<`, `>`, and `|` characters in between the two sides, and if that
does not work, try piping the output through `grep '[<>|]'`