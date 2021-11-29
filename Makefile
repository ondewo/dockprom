include packaging/example.env
-include packaging/.env  # Add all your private env vars into your custom .env file
export

start:
	docker-compose --env-file packaging/example.env up -d

stop:
	docker-compose --env-file packaging/example.env down

save_container_dependencies:
	-mkdir container_dependencies
	-rm container_dependencies/dependencies.tar.gz
	docker-compose pull
	docker save ${ORIG_PROMETHEUS_IMAGE_NAME} ${ORIG_ALERT_MANAGER_IMAGE_NAME} ${ORIG_NODE_EXPORTER_IMAGE_NAME} ${ORIG_CADVISOR_IMAGE_NAME} ${ORIG_GRAFANA_IMAGE_NAME} ${ORIG_PUSH_GATEWAY_IMAGE_NAME} ${ORIG_CADDY_IMAGE_NAME} | gzip > container_dependencies/dependencies.tar.gz

build_internal:
	docker build -t ${INTERNAL_IMAGE_NAME} -f packaging/package.Dockerfile .

build_external:
	docker build -t ${EXTERNAL_IMAGE_NAME} -f packaging/package.Dockerfile .

publish_internal: build_internal
	echo "Publishing ${INTERNAL_IMAGE_NAME}..."
	docker push ${INTERNAL_IMAGE_NAME}

publish_external: build_external
	echo "Publishing ${EXTERNAL_IMAGE_NAME}..."
	docker push ${EXTERNAL_IMAGE_NAME}

install_internal:
	docker run --mount "type=bind,source=`pwd`,target=/home/export" ${INTERNAL_IMAGE_NAME}
	docker run --mount "type=bind,source=`pwd`,target=/home/export" ${INTERNAL_IMAGE_NAME} chmod -R 777 /home/export/ondewo_monitoring
	gunzip -c ondewo_monitoring/container_dependencies/dependencies.tar.gz | docker load

install_external:
	docker run --mount "type=bind,source=`pwd`,target=/home/export" ${EXTERNAL_IMAGE_NAME}
	docker run --mount "type=bind,source=`pwd`,target=/home/export" ${EXTERNAL_IMAGE_NAME} chmod -R 777 /home/export/ondewo_monitoring
	gunzip -c ondewo_monitoring/container_dependencies/dependencies.tar.gz | docker load

# Optional: Only necessary if one desires to push all dependencies to a docker-registry
start_with_published_dependencies:
	docker-compose -f docker-compose.published_dependencies.yml --env-file packaging/example.env up -d

publish_dependencies_external:
	docker pull ${ORIG_PROMETHEUS_IMAGE_NAME}
	docker tag ${ORIG_PROMETHEUS_IMAGE_NAME} ${EXTERNAL_PROMETHEUS_IMAGE_NAME}
	docker pull ${ORIG_ALERT_MANAGER_IMAGE_NAME}
	docker tag ${ORIG_ALERT_MANAGER_IMAGE_NAME} ${EXTERNAL_ALERT_MANAGER_IMAGE_NAME}
	docker pull ${ORIG_NODE_EXPORTER_IMAGE_NAME}
	docker tag ${ORIG_NODE_EXPORTER_IMAGE_NAME} ${EXTERNAL_NODE_EXPORTER_IMAGE_NAME}
	docker pull ${ORIG_CADVISOR_IMAGE_NAME}
	docker tag ${ORIG_CADVISOR_IMAGE_NAME} ${EXTERNAL_CADVISOR_IMAGE_NAME}
	docker pull ${ORIG_GRAFANA_IMAGE_NAME}
	docker tag ${ORIG_GRAFANA_IMAGE_NAME} ${EXTERNAL_GRAFANA_IMAGE_NAME}
	docker pull ${ORIG_PUSH_GATEWAY_IMAGE_NAME}
	docker tag ${ORIG_PUSH_GATEWAY_IMAGE_NAME} ${EXTERNAL_PUSH_GATEWAY_IMAGE_NAME}
	docker pull ${ORIG_CADDY_IMAGE_NAME}
	docker tag ${ORIG_CADDY_IMAGE_NAME} ${EXTERNAL_CADDY_IMAGE_NAME}

	echo "Images generated: "
	echo "\t - ${EXTERNAL_PROMETHEUS_IMAGE_NAME}"
	echo "\t - ${EXTERNAL_ALERT_MANAGER_IMAGE_NAME}"
	echo "\t - ${EXTERNAL_NODE_EXPORTER_IMAGE_NAME}"
	echo "\t - ${EXTERNAL_CADVISOR_IMAGE_NAME}"
	echo "\t - ${EXTERNAL_GRAFANA_IMAGE_NAME}"
	echo "\t - ${EXTERNAL_PUSH_GATEWAY_IMAGE_NAME}"
	echo "\t - ${EXTERNAL_CADDY_IMAGE_NAME}"

	echo "Are you sure? [y/n] " && read resp && if [ "$$resp" = "y" ] || [ "$$resp" = "yes" ]; then make checked_publish_dependencies_external; else make abort_publishing_dependencies; fi

checked_publish_dependencies_external:
	echo "Publishing into the defined docker-registry"
	docker push ${EXTERNAL_PROMETHEUS_IMAGE_NAME}
	docker push ${EXTERNAL_ALERT_MANAGER_IMAGE_NAME}
	docker push ${EXTERNAL_NODE_EXPORTER_IMAGE_NAME}
	docker push ${EXTERNAL_CADVISOR_IMAGE_NAME}
	docker push ${EXTERNAL_GRAFANA_IMAGE_NAME}
	docker push ${EXTERNAL_PUSH_GATEWAY_IMAGE_NAME}
	docker push ${EXTERNAL_CADDY_IMAGE_NAME}
	echo "All dependencies published!"

abort_publishing_dependencies:
	echo "Publishing aborted!"
	echo "Check your env files for customisation of your identifiers."
	echo "It is highly recommended for you to modify the 'packaging/.env' file instead of the 'packaging/example.env'."
