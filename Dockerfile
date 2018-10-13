FROM golang:alpine as root
# ARG TOKEN
WORKDIR /go/src/github.com/gertcuykens/redis
RUN apk add --no-cache ca-certificates musl-dev gcc file git vim curl \
    && apk update \
    && apk upgrade \
    && rm -rf /var/cache/apk/*
COPY . .
# RUN git config --global url."https://...:${TOKEN}@.../".insteadOf "https://.../"
# GO111MODULE=on go mod vendor
CMD ["go", "test", "-v", "./..."]

FROM root as dev
RUN go build -tags 'netgo noplugin' -ldflags '-d -s -w -extldflags "-static"' -a -o /app/bin/main
CMD ["/app/bin/main"]

FROM root as debug
RUN go build -tags 'netgo noplugin' -ldflags '-w -extldflags "-static"' -a -gcflags "all=-N -l" -o /app/bin/debug
RUN ldd /app/bin/debug; exit 0
RUN file /app/bin/debug
RUN go get -u github.com/derekparker/delve/cmd/dlv
CMD ["dlv", "--listen=:2345", "--headless=true", "--api-version=2", "exec", "/app/bin/debug"]
EXPOSE 2345

FROM scratch as release
COPY --from=dev /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=dev /app/bin/main /app/bin/main
ENTRYPOINT ["/app/bin/main"]
