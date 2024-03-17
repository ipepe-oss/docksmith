# DockSmith
DockSmith is a simple HTTP server to quickly debug Docker containers on remote server

## Features

 - By default, it only looks at the containers with `docksmith_enabled=true` label
 - It can pull logs from the containers
 - It can execute basic docker commands on the containers

## Initial ChatGPT prompt:
```
Is there a docker containter image that uses /var/run/docker.sock:/var/run/docker.sock volume to pull information about logs and allows basic docker command executions through HTTP server?
```