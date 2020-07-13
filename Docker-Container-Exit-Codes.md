# Step 1. 
Identify the exit code for the docker container.
The exit code may give you hint to what happened to stop the container running.

## How to find Exit Codes:
1. List all containers that exited
```
docker ps --filter "status=exited"
```

2. Grep by Container Name
```
docker ps -s grep <container-name>
docker ps -a | grep hello-world
```

3. Inspect by container id

```
docker inspect <container-id> --format='{{.status.ExitCode}}'
Example: docker inspect ca6cbb290468 --format='{{.State.ExitCode}}'
```


### Exit Code 0:
No foreground process attached such as Java process or a shell process that runs until SIGTERM event occurs.

```
docker run hello-world
docker ps -a | grep hello-world
```

### Exit Code 1:
Indicates that the container stopped due to either an application error or an incorrect reference in Dockerfile to file that is not present in the container.
ENTRYPOINT["java", "-jar", "sample.ja"]



