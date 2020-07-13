Step 1. 
Identify the exit code for the docker container.
The exit code may give you hint to what happened to stop the container running.

How to find Exit Codes:
1. List all containers that exited
```docker ps --filter "status=exited"```
2. Grep by Container Name
```docker ps -s grep <container-name>
docker ps -a | grep hello-world```
3. Inspect by container id
```docker inspect <container-id> --format='{{.status.ExitCode}}'
Example: docker inspect ca6cbb290468 --format='{{.State.ExitCode}}'```


