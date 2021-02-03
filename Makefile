default: all

all: build lint policies bom scan

build:
	@echo "Building Hugo Builder container..."
	@docker build \
		--build-arg CREATE_DATE=`date -u +'%Y-%m-%dT%H:%M:%SZ'` \
		--build-arg REVISION=`git rev-parse HEAD` \
		--build-arg BUILD_VERSION=1.0.0 \
		-t tgbenson/hugo-builder .
	@echo "Hugo Builder container built!"
	@docker images tgbenson/hugo-builder

lint:
	@echo "Linting the Hugo Builder container..."
	@docker run --rm -i hadolint/hadolint:v1.17.5-alpine \
		hadolint --ignore DL3018 - < Dockerfile
	@echo "Linting completed!"

#gov_policy:
#   @echo "Checking container policy..."
#   @docker run --rm -it --privileged -v $(PWD):/root/ \
#       projectatomic/dockerfile-lint \
#       dockerfile_lint -r policies/governance_rules.yml
#   @echo "Container policy checked!"

policies:
	@echo "Checking FinShare Container policies..."
	@docker run --rm -it --privileged -v $(PWD):/root/ \
		projectatomic/dockerfile-lint \
		dockerfile_lint -r policies/all_policy_rules.yml
	@echo "FinShare Container policies checked!"

hugo_build:
	@echo "Building the OrgDocs Hugo site..."
	@docker run --rm -it -v $(PWD)/orgdocs/OrgDocs:/src tgbenson/hugo-builder hugo
	@docker trust sign tgbenson/hugo-builder:$(BUILD_VERSION)
	@echo "OrgDocs Hugo site built!"

# hugo_build:
# 	@echo "Building the OrgDocs Hugo site..."
# 	@docker run --rm -it \
# 		--mount type=bind,src=${PWD}/orgdocs,dst=/src \
# 		tgbenson/hugo-builder hugo
# 	@echo "OrgDocs Hugo site built!"

start_server:
	@echo "Serving the OrgDocs Hugo site..."
	@docker run -d --rm -it -v $(PWD)/orgdocs/OrgDocs:/src -p 1313:1313 \
	    --name hugo_server tgbenson/hugo-builder hugo server -w --bind=0.0.0.0
	@echo "OrgDocs Hugo site being served!"
	@docker ps --filter name=hugo_server

# start_server:
# 	@echo "Serving the OrgDocs Hugo site..."
# 	@docker run -d --rm -it --name hugo_server \
# 		--mount type=bind,src=${PWD}/orgdocs,dst=/src \
# 		-p 1313:1313 tgbenson/hugo-builder hugo server -w --bind=0.0.0.0
# 	@echo "OrgDocs Hugo site being served!"
# 	@docker ps --filter name=hugo_server

check_health:
	@echo "Checking the health of the Hugo Server..."
	@docker inspect --format='{{json .State.Health}}' hugo_server

inspect:
	@echo "Inspecting Container..."
	@docker trust inspect --pretty tgbenson/hugo-builder

stop_server:
	@echo "Stopping the OrgDocs Hugo site..."
	@docker stop hugo_server
	@echo "OrgDocs Hugo site stopped!"

inspect_labels:
	@echo "Inspecting Hugo Server Container labels..."
	@echo "\nmaintainer set to..."
	@docker inspect --format '{{ index .Config.Labels "maintainer" }}' \
		hugo_server
	@echo "\ncreate date set to..."
	@docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.create_date" }}' \
        	hugo_server
	@echo "\nrevision set to..."
	@docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.revision" }}' \
        	hugo_server
	@echo "\nversion set to..."
	@docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version" }}' \
        	hugo_server
	@echo "\nHugo version set to..."
	@docker inspect --format '{{ index .Config.Labels "hugo_version"}}' \
        	hugo_server
	@echo "\nLabels inspected!"

scan:
	@echo "Scanning the Hugo Builder Container Image..."
# 	@docker run -p 5432:5432 -d --name db arminc/clair-db:latest
# 	@docker run -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan:latest
	~/github/clair-scanner/clair-scanner_darwin_amd64 --ip 192.168.0.3 tgbenson/hugo-builder
	@docker stop clair db
	@echo "Scan of the Hugo Builder Container completed!"

bom:
	@echo "Creating Bill of Materials..."
	@docker run --rm --privileged \
        	-v /var/run/docker.sock:/var/run/docker.sock \
        	--mount type=bind,source=$(PWD)/workdir,target=/hostmount \
        	ternd:latest report -f spdxtagvalue -i tgbenson/hugo-builder:latest > bom.spdx
	@ls -la bom.spdx
	@echo "Bill of Materials created!"

docker_clean:
	@docker image prune -f
	@docker container prune -f
	@docker volume prune -f

.PHONY: build lint gov_policies policies hugo_build \
  start_server check_health stop_server inspect_labels scan \
  docker_clean bom


#   Other Commands
#   DCT key generation command: docker trust key generate todd
#   Signing command: docker trust sign tgbenson/hugo-builder:latest
#   Run container with trust enabled: export DOCKER_CONTENT_TRUST=1
#   DCT add key to Dockerhub: docker trust signer add --key ~/todd.pub todd smarshops/security
