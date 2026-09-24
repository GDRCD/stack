.PHONY: test

TEST_IMAGE ?= alpine:3.22

test:
	docker run --rm \
		--volume "$(CURDIR):/workspace:ro" \
		--workdir /workspace \
		$(TEST_IMAGE) \
		sh -eu -c 'apk add --no-cache bash bats git shellcheck zsh >/dev/null; \
			rm -rf /tmp/gdrcd-stack-tests; \
			mkdir -p /tmp/gdrcd-stack-tests/www /tmp/gdrcd-stack-tests/logs; \
			cp -R /workspace/stack /workspace/boot.sh /workspace/bin /workspace/tests /workspace/sample.env /tmp/gdrcd-stack-tests/; \
			printf "%s\n" \
				"PROJECT=gdrcd-tests" \
				"SERVICE_PORT=8080" \
				"PMA_PORT=8081" \
				"MAILHOG_PORT=8025" \
				"DB_PORT=3306" \
				"PHP_VERSION=php84" \
				"PHP_UID=1000" \
				"MYSQL_ROOT_PASSWORD=root" \
				"MYSQL_USER=gdrcd" \
				"MYSQL_PASSWORD=gdrcd" \
				"MYSQL_DATABASE=gdrcd" \
				> /tmp/gdrcd-stack-tests/.env; \
			cd /tmp/gdrcd-stack-tests; \
			bash tests/run.sh'
