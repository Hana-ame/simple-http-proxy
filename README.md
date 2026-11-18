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

## Prebuilt binaries

Every `v*` tag is built by GitHub Actions (`.github/workflows/release.yml`) and published to the [Releases](https://github.com/Hana-ame/simple-http-proxy/releases) page:

| OS | Arch | Asset |
| --- | --- | --- |
| Linux | x86-64 | `goproxy-<tag>-linux-amd64` |
| Linux | arm64 | `goproxy-<tag>-linux-arm64` |
| Windows | x86-64 | `goproxy-<tag>-windows-amd64.exe` |

To cut a release, push a tag:

```bash
git tag v0.1.0
git push origin v0.1.0
```

## SSH Port Forwarding

### Option 1: Remote → Local（把本地代理暴露到远端）

在本地执行，把远端 `:1080` 映射到本机 `:1080`，远端机器可通过 `localhost:1080` 使用本机的代理：

```bash
ssh -R 1080:localhost:1080 root@cloudcone.moonchan.xyz
```

### Option 2: Local → Remote（使用远端代理）

在本地执行，把本机 `:1080` 映射到远端 `:1080`，本机可通过 `localhost:1080` 使用远端机器的代理：

```bash
ssh -L 1080:localhost:1080 root@cloudcone.moonchan.xyz
```
