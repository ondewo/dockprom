include packaging/example.env
-include packaging/.env  # Add all your private env vars into your custom .env file
export

start:
	docker-compose up -d

build_dev:
	docker build -t ${DEV_IMAGE_NAME} -f packaging/package.Dockerfile .

build_prod:
	docker build -t ${PROD_IMAGE_NAME} -f packaging/package.Dockerfile .

install_dev: build_dev
	docker run --mount "type=bind,source=`pwd`,target=/home/export" ${DEV_IMAGE_NAME}

install_prod: build_prod
	docker run --mount "type=bind,source=`pwd`,target=/home/export" ${PROD_IMAGE_NAME}

publish_dev: build_dev
	echo "Publishing ${DEV_IMAGE_NAME}..."
	docker push ${DEV_IMAGE_NAME}

publish_prod: build_prod
	echo "Publishing ${PROD_IMAGE_NAME}..."
	docker push ${PROD_IMAGE_NAME}

publish_dependencies_prod:
	docker pull ${ORIG_PROMETHEUS_IMAGE_NAME}
	docker tag ${ORIG_PROMETHEUS_IMAGE_NAME} ${PROD_PROMETHEUS_IMAGE_NAME}
	docker pull ${ORIG_ALERT_MANAGER_IMAGE_NAME}
	docker tag ${ORIG_ALERT_MANAGER_IMAGE_NAME} ${PROD_ALERT_MANAGER_IMAGE_NAME}
	docker pull ${ORIG_NODE_EXPORTER_IMAGE_NAME}
	docker tag ${ORIG_NODE_EXPORTER_IMAGE_NAME} ${PROD_NODE_EXPORTER_IMAGE_NAME}
	docker pull ${ORIG_CADVISOR_IMAGE_NAME}
	docker tag ${ORIG_CADVISOR_IMAGE_NAME} ${PROD_CADVISOR_IMAGE_NAME}
	docker pull ${ORIG_GRAFANA_IMAGE_NAME}
	docker tag ${ORIG_GRAFANA_IMAGE_NAME} ${PROD_GRAFANA_IMAGE_NAME}
	docker pull ${ORIG_PUSH_GATEWAY_IMAGE_NAME}
	docker tag ${ORIG_PUSH_GATEWAY_IMAGE_NAME} ${PROD_PUSH_GATEWAY_IMAGE_NAME}
	docker pull ${ORIG_CADDY_IMAGE_NAME}
	docker tag ${ORIG_CADDY_IMAGE_NAME} ${PROD_CADDY_IMAGE_NAME}

	echo "Images generated: "
	echo "\t - ${PROD_PROMETHEUS_IMAGE_NAME}"
	echo "\t - ${PROD_ALERT_MANAGER_IMAGE_NAME}"
	echo "\t - ${PROD_NODE_EXPORTER_IMAGE_NAME}"
	echo "\t - ${PROD_CADVISOR_IMAGE_NAME}"
	echo "\t - ${PROD_GRAFANA_IMAGE_NAME}"
	echo "\t - ${PROD_PUSH_GATEWAY_IMAGE_NAME}"
	echo "\t - ${PROD_CADDY_IMAGE_NAME}"

	echo "Are you sure? [y/N] " && read resp && if [ "$$resp" = "y" ] || [ "$$resp" = "yes" ]; then make checked_publish_dependencies_production; else make abort_publishing_dependencies; fi

checked_publish_dependencies_production:
	echo "Publishing into the defined docker-registry"
	docker push ${PROD_PROMETHEUS_IMAGE_NAME}
	docker push ${PROD_ALERT_MANAGER_IMAGE_NAME}
	docker push ${PROD_NODE_EXPORTER_IMAGE_NAME}
	docker push ${PROD_CADVISOR_IMAGE_NAME}
	docker push ${PROD_GRAFANA_IMAGE_NAME}
	docker push ${PROD_PUSH_GATEWAY_IMAGE_NAME}
	docker push ${PROD_CADDY_IMAGE_NAME}
	echo "All dependencies published!"

abort_publishing_dependencies:
	echo "Publishing aborted!"
	echo "Check your env files for customisation of your identifiers."
	echo "It is highly recommended for you to modify the 'packaging/.env' file instead of the 'packaging/example.env'."