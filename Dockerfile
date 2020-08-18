# Base Image
FROM golang:alpine

# Maintainer of the Docker file
LABEL maintainer="Sweta Sharma"

#Current working directory in container
WORKDIR /simple-service

COPY go.mod .

COPY go.sum .

# Download all the dependencies taht we defined in go.mod file
RUN go mod download
 
# Copy all the files recursively to the current directory with in container
COPY . .

# Environment variable for application port
ENV PORT 8080

# Build the application
RUN GO111MODULE=on go build

# Run the command once the container is initialized
ENTRYPOINT [ "./simple-service" ]