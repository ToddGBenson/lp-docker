default: build

static: Dockerfile
	@echo "Performing static analysis"
	@docker run --rm -i hadolint/hadolint hadolint --ignore DL3018 - < Dockerfile
	@docker run -it --rm -v $(PWD):/root/ projectatomic/dockerfile-lint dockerfile_lint -r policies/security_rules.yml

test: build
	@docker start clair
	@docker start db
	~/github/clair-scanner/clair-scanner_darwin_amd64 --ip 192.168.0.3 lp/hugo-builder

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

bofm:
	~/github/tern/docker_run.sh ternd "report -f spdxtagvalue -i lp/hugo-builder:latest" > hugo-bofm.json
	cat hugo-bofm.json

inspect:
	@docker inspect hugo
