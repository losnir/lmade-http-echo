FROM jrei/crystal-alpine:0.31.1 AS build
WORKDIR /app
COPY . /app
RUN crystal build --static --release --no-debug ./http-echo.cr

FROM scratch AS dist
WORKDIR /app
COPY --from=build /app/http-echo .
ENTRYPOINT ["/app/http-echo"]