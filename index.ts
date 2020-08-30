import * as awsx from "@pulumi/awsx";

// Based on the following tutorial: https://www.pulumi.com/blog/get-started-with-docker-on-aws-fargate-using-pulumi/

// Create a new VPC with public subnets, basic security groups and routing.
const vpc = new awsx.ec2.Vpc("http-echo-vpc", {
  cidrBlock: "10.0.0.0/16",
  subnets:   [{ type: "public" }],
  tags:      { Name: "http-echo-vpc" }
});

// Create an ECS Fargate cluster.
const cluster = new awsx.ecs.Cluster("http-echo-cluster", { vpc });

// Create an ALB for our service.
const alb = new awsx.lb.ApplicationLoadBalancer("http-echo-alb", {
  vpc,
  external: true,
  securityGroups: cluster.securityGroups
});

// Create an ALB target group that will be connected later to our Fargate Service.
const targetGroup = alb.createTargetGroup("http-echo-target-group", {
  protocol: "HTTP",
  port: 8080,  // Port 8080 is the default internal port for the service
  healthCheck: {
    protocol: "HTTP",
    path: "/",
    interval: 5,
    timeout: 3
  },
  deregistrationDelay: 30 // Sane default for connection draining
});

// Create an ALB listener that will be the fronend of the service.
const albListener = alb.createListener("http-echo-web-listener", {
  external: true,
  protocol: "HTTP",
  port: 80,
  targetGroup
});

// Build and publish a Docker image to a private ECR registry.
// If the registry does not exists, it will be created.
const dockerImage = awsx.ecs.Image.fromPath("http-echo-registry", "./app");

// Create a Fargate service task that can scale out.
const service = new awsx.ecs.FargateService("http-echo-service", {
    cluster,
    taskDefinitionArgs: {
        container: {
            environment: [
              { name: "BIND_ADDR", value: "0.0.0.0" },
              { name: "BIND_PORT", value: "8080" }
            ],
            image: dockerImage,
            cpu: 1024,
            memory: 256,
            portMappings: [albListener],
        },
    },
    desiredCount: 3,
});

// Export the URL of the service (ALB listener).
export const url = albListener.endpoint.hostname