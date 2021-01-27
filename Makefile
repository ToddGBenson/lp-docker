default: build

static: Dockerfile
	@echo "Performing static analysis"
	@docker run --rm -i hadolint/hadolint hadolint --ignore DL3018 - < Dockerfile

build: static
	@echo "Building Hugo Builder container..."
	@docker build -t lp/hugo-builder .
	@echo "Hugo Builder container built!"
	@docker images lp/hugo-builder

start: build
	@docker run -d --rm -i -p 1313:1313 --name hugo lp/hugo-builder

deploy: start
	@echo "Creating web site"
	@docker exec -d -w /src hugo hugo new site OrgDocs
	@echo "Adding theme"
	@docker exec -d -w /src/OrgDocs hugo git init
	@docker exec -d -w /src/OrgDocs hugo git submodule add https://github.com/budparr/gohugo-theme-ananke.git themes/ananke
	@docker exec -d -w /src/OrgDocs hugo /bin/sh -c "echo 'theme = \"ananke\"' >> /src/OrgDocs/config.toml"
	@docker exec -d -w /src/OrgDocs hugo hugo new posts/my-first-post.md
	@echo "Running Docker container"
	sleep 5
	@docker exec -d -w /src/OrgDocs hugo hugo server -w --bind=0.0.0.0

health:
	@echo "Performing health check"
	@docker inspect --format='{{json .State.Health}}' hugo

stop:
	@docker stop hugo
