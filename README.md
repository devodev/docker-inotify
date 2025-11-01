# docker-inotify

[![Version](https://img.shields.io/docker/v/devodev/inotify?color=brightgreen&label=version)](https://github.com/devodev/docker-inotify)
[![Version](https://img.shields.io/docker/image-size/devodev/inotify)](https://github.com/devodev/docker-inotify)
[![Docker Pulls](https://img.shields.io/docker/pulls/devodev/inotify.svg)](https://hub.docker.com/r/devodev/inotify/)
[![Docker Stars](https://img.shields.io/docker/stars/devodev/inotify.svg)](https://hub.docker.com/r/devodev/inotify/)

## Quick reference

- **Maintained by**: [devodev](https://github.com/devodev)

## Supported tags and respective `Dockerfile` links

- [`0.4.0`, `0.4`, `latest`](https://github.com/devodev/docker-inotify)

## Quick reference (cont.)

- **Where to file issues**: [https://github.com/devodev/docker-inotify/issues](https://github.com/devodev/docker-inotify/issues)

## What is Inotify?

> GitHub repository: <https://github.com/inotify-tools/inotify-tools>

From the linux man pages (<https://man7.org/linux/man-pages/man7/inotify.7.html>):

*The inotify API provides a mechanism for monitoring filesystem events. Inotify can be used to
monitor individual files, or to monitor directories. When a directory is monitored, inotify will
return events for the directory itself, and for files inside the directory.*

Two command-line tools are distributed as part of the `inotify-tools` package (`inotifywait`,
`inotifywatch`) and allows to interact with the Inotify API.

## How to use this image

`docker-inotify` provides an Alpine-based image that contains the `inotify-tools` package, as well
as `bash` and a series of network-related command-line utilities such as `curl`, `netcat`, etc. It
also includes a lightweight `inotifywait.sh` script that can watch files and/or directories and send
events to a user-defined script. The script can be entirely configured through environment
variables.

The main use-case for this image is to provide an easy way to trigger an action based on a
configuration file change. All you need to do is mount a volume in the sidecar to be monitored, and
provide a script to trigger when an event is received.

### How it works

An `inotifywait` process watches INOTIFY_TARGET, and runs INOTIFY_SCRIPT with the triggered event
data as arguments.

When using the default configuration values, the script will receive:

| argv | name                                    |
| ---- | --------------------------------------- |
| `$1` | timestamp                               |
| `$2` | watched file/directory path             |
| `$3` | event name(s)                           |
| `$4` | filename (if a directory is monitored)  |

#### Arguments examples

> Watched events: `modify delete delete_self`

A watched file being modified/deleted

```bash
22:48:36 /test MODIFY
22:48:36 /test DELETE_SELF
```

A file being modified/deleted in a watched directory

```bash
22:48:36 /test/ MODIFY a_file
22:48:36 /test/ DELETE a_file
```

The following section describes how to configure the watch process.

### Environment variables

#### Global

| Variable       | Required | Default value | Description                                |
| -------------- | -------- | ------------- | ------------------------------------------ |
| INOTIFY_TARGET | true     | empty         | The file or directory to watch for events  |
| INOTIFY_SCRIPT | true     | empty         | The script to run whenever an event occurs |
| INOTIFY_QUIET  | false    | true          | If set, suppress log messages              |

#### Watch configuration

> The default values should be fine in most cases.
>
> See [inotify-tools](https://github.com/inotify-tools/inotify-tools) for more details about
> `inotifywait` available flags.
>
> Booleans can be set to any value to be considered true.

| Variable               | Default value               | Description                                                         |
| ---------------------- | --------------------------- | ------------------------------------------------------------------- |
| INOTIFY_CFG_CSV        | false                       | (bool) Output events using CSV format                               |
| INOTIFY_CFG_EVENTS     | `modify delete delete_self` | Space-separated list of events to watch                             |
| INOTIFY_CFG_EXCLUDE    | -                           | Exclude a subset of files using a POSIX regex pattern               |
| INOTIFY_CFG_EXCLUDEI   | -                           | Same as `INOTIFY_CFG_EXCLUDE` but case insensitive                  |
| INOTIFY_CFG_INCLUDE    | -                           | Include a subset of files using a POSIX regex pattern               |
| INOTIFY_CFG_INCLUDEI   | -                           | Same as `INOTIFY_CFG_INCLUDE` but case insensitive                  |
| INOTIFY_CFG_QUIET      | true                        | (bool) Suppress inotifywait logging                                 |
| INOTIFY_CFG_RECURSIVE  | false                       | (bool) Watch all subdirectories with unlimited depth                |
| INOTIFY_CFG_TIMEFMT    | `%H:%M:%S`                  | The strftime-compatible pattern used to display %T in emitted event |
| INOTIFY_CFG_TIMEOUT    | -                           | Timeout and re-setup watchers after X seconds of no event received  |

### Example

#### Kubernetes

The following example defines a `Pod` containing an application container and an `inotify` sidecar
that will be used to trigger a server reload whenever the mounted configuration file (here a shared
`ConfigMap`) is updated.

```yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: application-conf
data:
  application.conf: |-
    [server]
    property=value
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: inotify-example-reload-script
data:
  reload-server.sh: |-
    #!/usr/bin/env bash

    timestamp="$1"; shift
    file="$1"; shift
    event="$1"; shift

    echo "[${timestamp}] file: ${file} changed (${event}), triggering server reload"
    curl -s -X POST http://localhost:8080/reload
---
apiVersion: v1
kind: Pod
metadata:
  name: inotify-example
spec:
  containers:
  - name: application
    image: application/server:latest
    ports:
      - containerPort: 8080
        name: server
    volumeMounts:
      - name: conf
        mountPath: /conf/application.conf
        readOnly: true
        subPath: application.conf
  - name: reload-server-sidecar
    image: devodev/inotify:latest
    env:
      - name: INOTIFY_TARGET
        value: "/conf/application.conf"
      - name: INOTIFY_SCRIPT
        value: "/reload-server.sh"
    volumeMounts:
      - name: conf
        mountPath: /conf/application.conf
        readOnly: true
        subPath: application.conf
      - name: reload-script
        mountPath: /reload-server.sh
        readOnly: true
        subPath: reload-server.sh
  volumes:
    - name: conf
      configMap:
        name: application-conf
    - name: reload-script
      configMap:
        name: inotify-example-reload-script
        # makes sure the script is executable
        defaultMode: 0777
```
