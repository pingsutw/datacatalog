# WARNING: THIS FILE IS MANAGED IN THE 'BOILERPLATE' REPO AND COPIED TO OTHER REPOSITORIES.
# ONLY EDIT THIS FILE FROM WITHIN THE 'FLYTEORG/BOILERPLATE' REPOSITORY:
# 
# TO OPT OUT OF UPDATES, SEE https://github.com/flyteorg/boilerplate/blob/master/Readme.rst

FROM golang:1.17.1-alpine3.14 as builder
RUN apk add git openssh-client make curl

# COPY only the go mod files for efficient caching
COPY go.mod go.sum /go/src/github.com/flyteorg/datacatalog/
WORKDIR /go/src/github.com/flyteorg/datacatalog

# Pull dependencies
RUN go mod download

# COPY the rest of the source code
COPY . /go/src/github.com/flyteorg/datacatalog/

# This 'linux_compile' target should compile binaries to the /artifacts directory
# The main entrypoint should be compiled to /artifacts/datacatalog
RUN make linux_compile

# install grpc-health-probe 
RUN curl --silent --fail --show-error --location --output /artifacts/grpc_health_probe "https://github.com/grpc-ecosystem/grpc-health-probe/releases/download/v0.4.5/grpc_health_probe-linux-amd64" && \
    chmod +x /artifacts/grpc_health_probe && \
    echo '8699c46352d752d8f533cae72728b0e65663f399fc28fb9cd854b14ad5f85f44  /artifacts/grpc_health_probe' > .grpc_checksum && \
    sha256sum -c .grpc_checksum

# update the PATH to include the /artifacts directory
ENV PATH="/artifacts:${PATH}"

# This will eventually move to centurylink/ca-certs:latest for minimum possible image size
FROM alpine:3.14
LABEL org.opencontainers.image.source https://github.com/flyteorg/datacatalog

COPY --from=builder /artifacts /bin

RUN apk --update add ca-certificates

RUN addgroup -S flyte && adduser -S flyte -G flyte
USER flyte

CMD ["datacatalog"]
