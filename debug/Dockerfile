FROM quay.io/cybozu/golang:1.17-focal AS build
RUN git clone https://github.com/cybozu-go/accurate.git
WORKDIR /work/accurate
RUN CGO_ENABLED=0 go install github.com/go-delve/delve/cmd/dlv@latest
RUN CGO_ENABLED=0 go build -gcflags=all="-N -l" -o accurate-controller ./cmd/accurate-controller
ENTRYPOINT ["/go/bin/dlv", "dap", "--log", "-l", ":12345"]
