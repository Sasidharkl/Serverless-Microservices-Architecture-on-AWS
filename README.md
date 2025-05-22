# Serverless-Microservices-Architecture-on-AWS
# Serverless User Service (AWS Lambda + API Gateway)

This microservice allows creating and retrieving user data via HTTP requests using a fully serverless architecture on AWS.

## Features
- AWS Lambda (Python)
- DynamoDB for data persistence
- REST API via API Gateway
- Infrastructure managed by Terraform

## Endpoints
- `POST /users` – Create a new user
- `GET /users/{id}` – Fetch user by ID

## Deploy
1. Zip the Lambda:
```bash
zip -r lambdas/user_service.zip lambdas/user_service
