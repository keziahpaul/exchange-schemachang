IMAGE ?= pexa-one-data-snowflake-image
export DOCKER_IMAGE=pexa-one-data-snowflake-image
export AWS_REGION=ap-southeast-2
export GITHUB_ENV=GITHUB_ENV
export GITHUB_WORKFLOW ?= pexa_one_data
export GITHUB_ACTIONS_ID ?= GITHUB_ACTIONS_ID


build:
	docker build --no-cache -t ${IMAGE} .
.PHONY: build

image:
	docker image ls | grep ${DOCKER_IMAGE} || make build
PHONY: image

common_dry_run:
	DRY_RUN="--dry-run" make common_deploy
.PHONY: common_dry_run

common_deploy:
		schemachange deploy \
			--config-folder schemachange/config/${SF_ENV}/ \
			--change-history-table ${SF_ENV}_METADATA.SCHEMACHANGE.CHANGE_HISTORY \
			--create-change-history-table \
			${DRY_RUN}
.PHONY: common_deploy
