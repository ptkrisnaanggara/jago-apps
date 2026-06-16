.PHONY: tidy build run worker vet test up down logs

tidy:
	go mod tidy

build:
	go build ./...

run:        ## run the API server
	go run ./cmd/api

worker:     ## run the event worker
	go run ./cmd/worker

vet:
	go vet ./...

test:
	go test ./...

up:         ## start postgres + redis + rabbitmq + api + worker
	docker compose up --build -d

down:
	docker compose down

logs:
	docker compose logs -f api worker
