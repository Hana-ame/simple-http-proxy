# simple-http-proxy

A lightweight HTTP/HTTPS forward proxy written in Go. Supports CONNECT tunneling for HTTPS and direct forwarding for HTTP requests.

## Usage

```bash
# Build and run
./run.sh

# Or build manually
go build -o goproxy .
./goproxy

# Configure your browser/device to use proxy at localhost:1080
```

The proxy listens on `:1080` by default.
