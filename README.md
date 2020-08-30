# http-echo

`http-echo` is a simple http server written in Crystal that echoes back every request in a JSON format.

## Features

- Functional http server
- Supports reporting of StatsD-like metrics (with tags)
- Logging to standard streams (STDOUT or STDERR) allows exporting logs via your favorite docker orchestrator (ECS, Nomad, etc.)

## Configuration

Configuration is simple and done via environment variables:

- `BIND_ADDR`: The IP address to bind / listen on (default is `0.0.0.0` and usually there's no need to change that)
- `BIND_PORT`: The port to bind / listen on (default is `8080`)
- `METRICS_ENDPOINT_HOST`: The endpoint host to report metrics to (should accept UDP with StatsD / DataDog Line Protocol)
- `METRICS_ENDPOINT_PORT`: The endpoint port to report metrics to (usually `8125`)

Note: Metrics reporting is off by default, please provide both `METRICS_ENDPOINT_HOST` & `METRICS_ENDPOINT_PORT` to enable it.

## Infrastructure

All supporting infrastructure is expressed as code with `Pulumi`.

The default stack is `dev`.

## Getting Started

To get started, first install the Node.js dependencies by running:

```bash
$ npm install
```

You can use `yarn` if you prefer.

Then to create the stack run:

```bash
$ pulumi up
```

It will automatically create for you the following on AWS:

- VPC, Subnets, Routing Table, Security Groups, Internet Gateway
- Load Balancer (w/ Target Group & Listener)
- ECS Fargate Cluster, ECS Fargate Service, ECS Task Definition, ECR Registry
- CloudWatch Log Group (where you can view logs)

At the end, you will be provided with the `url` output, where you can access the service:

```
Outputs:
    url: "http-echo-alb-xxxxxxx-yyyyyyyyy.us-east-1.elb.amazonaws.com"
```