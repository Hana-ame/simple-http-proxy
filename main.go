package main

import (
	"io"
	"log"
	"net"
	"net/http"
	"time"
)

var proxyTransport = &http.Transport{
	DialContext: (&net.Dialer{
		Timeout:   30 * time.Second,
		KeepAlive: 30 * time.Second,
	}).DialContext,
	MaxIdleConns:          100,
	IdleConnTimeout:       90 * time.Second,
	TLSHandshakeTimeout:   10 * time.Second,
	ExpectContinueTimeout: 1 * time.Second,
	Proxy:                 nil,
}

func main() {
	server := &http.Server{
		Addr:         ":1080",
		Handler:      http.HandlerFunc(proxyHandler),
		IdleTimeout:  120 * time.Second,
	}
	log.Printf("Starting HTTP proxy on %s", server.Addr)
	log.Fatal(server.ListenAndServe())
}

func proxyHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodConnect {
		handleTunnel(w, r)
	} else {
		handleHTTP(w, r)
	}
}

func handleHTTP(w http.ResponseWriter, r *http.Request) {
	req := r.Clone(r.Context())

	if req.URL.Scheme == "" {
		if r.TLS != nil {
			req.URL.Scheme = "https"
		} else {
			req.URL.Scheme = "http"
		}
	}
	req.Host = r.Host

	req.Header.Del("Proxy-Connection")
	req.Header.Del("Proxy-Authorization")
	req.Header.Del("Connection")
	req.Header.Del("Keep-Alive")
	req.Header.Del("Transfer-Encoding")
	req.Header.Del("Upgrade")

	resp, err := proxyTransport.RoundTrip(req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadGateway)
		return
	}
	defer resp.Body.Close()

	for k, v := range resp.Header {
		w.Header()[k] = v
	}
	w.WriteHeader(resp.StatusCode)
	io.Copy(w, resp.Body)
}

func handleTunnel(w http.ResponseWriter, r *http.Request) {
	destConn, err := net.DialTimeout("tcp", r.Host, 10*time.Second)
	if err != nil {
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
		return
	}

	hijacker, ok := w.(http.Hijacker)
	if !ok {
		destConn.Close()
		http.Error(w, "Hijacking not supported", http.StatusInternalServerError)
		return
	}
	clientConn, rw, err := hijacker.Hijack()
	if err != nil {
		destConn.Close()
		http.Error(w, err.Error(), http.StatusServiceUnavailable)
		return
	}

	tuneConn := func(c net.Conn) {
		if tc, ok := c.(*net.TCPConn); ok {
			_ = tc.SetNoDelay(true)
			_ = tc.SetKeepAlive(true)
			_ = tc.SetKeepAlivePeriod(30 * time.Second)
			_ = tc.SetReadBuffer(1 << 20)
			_ = tc.SetWriteBuffer(1 << 20)
		}
	}
	tuneConn(destConn)
	tuneConn(clientConn)

	// 必须主动 Flush 写入 200 Connection Established 响应
	rw.WriteString("HTTP/1.1 200 Connection Established\r\n\r\n")
	if err := rw.Flush(); err != nil {
		destConn.Close()
		clientConn.Close()
		return
	}

	// 从 rw 读取（优先排出缓冲区中可能存在的后续报文如 TLS ClientHello），再落到底层 conn
	go func() {
		defer destConn.Close()
		defer clientConn.Close()
		buf := make([]byte, 64*1024)
		_, _ = io.CopyBuffer(destConn, rw, buf)
	}()
	go func() {
		defer destConn.Close()
		defer clientConn.Close()
		buf := make([]byte, 64*1024)
		_, _ = io.CopyBuffer(clientConn, destConn, buf)
	}()
}

func transfer(destination net.Conn, source net.Conn) {
	defer destination.Close()
	defer source.Close()
	io.Copy(destination, source)
}
