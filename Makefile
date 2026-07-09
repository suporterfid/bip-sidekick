.DEFAULT_GOAL := help
COMPOSE := docker compose

.PHONY: help bootstrap up-core up-gate up-openwa down logs ps audit

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	 awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

bootstrap: ## One-shot VPS setup (Docker, vault git remote)
	./scripts/bootstrap.sh

up-core: ## Stage 1-2: senses + memory + brief + command inbox (read-only value)
	$(COMPOSE) --profile core up -d --build

up-gate: ## Stage 3: ensure the approval gate + audit sink are live
	$(COMPOSE) --profile core up -d --build telegram-bridge
	@echo ">> Gate active. Test: propose an 'act' and confirm it blocks until you reply."

up-openwa: ## Stage 4: WhatsApp read-only triage (scan QR with a SPARE number)
	$(COMPOSE) --profile openwa up -d --build
	@echo ">> Check logs for the QR: make logs SVC=openwa"

down: ## Stop everything
	$(COMPOSE) --profile core --profile openwa down

logs: ## Tail logs. Usage: make logs SVC=agent
	$(COMPOSE) logs -f $(SVC)

ps: ## Show running services
	$(COMPOSE) ps

audit: ## Tail the append-only action log
	docker exec bip-telegram-bridge tail -f /audit/actions.jsonl
