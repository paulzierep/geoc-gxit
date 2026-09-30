# These must produce the image the tool XML asks for
# (<container type="docker">paulzierep/gtn-gxit:latest</container>), otherwise
# Galaxy pulls the old published image from the registry instead of using the
# image you just built locally.
docker_name=gtn-gxit
docker_repo=paulzierep
# Must match <port> in interactivetool_tabulator.xml and ARG PORT in the Dockerfile
internal_port=8765
# Host port : container port. The container only ever listens on
# internal_port, so publishing that same port keeps one number for everything.
# Change the host side (e.g. 3838:$(internal_port)) if it clashes with
# something already running locally, or to run two instances side by side.
port=-p 127.0.0.1:$(internal_port):$(internal_port)
WEB_TAG=1.0.0
WEB_TARGET=${docker_repo}/${docker_name}:${WEB_TAG}
WEB_LATEST=${docker_repo}/${docker_name}:latest

re:clean docker

push_hub: docker hub_login do_push remove_hub_credentials

do_push:
	docker push ${WEB_TARGET}
	docker push ${WEB_LATEST}

hub_login:
	cat .password | docker login --username=${USERNAME} --password-stdin

remove_hub_credentials:hub_logout
	rm ~/.docker/config.json

hub_logout:
	docker logout

docker_logout:
	docker logout

docker:
	@docker build --build-arg PORT=${internal_port} -t $(docker_name) .
	@docker tag ${docker_name}:latest ${WEB_TARGET}
	@docker tag ${docker_name}:latest ${WEB_LATEST}


clean:
	docker kill `docker ps | grep -Poe '[a-z0-9]{12}'` || true
	docker container prune
	docker rmi $(docker_name) || true


it:
	docker run -it $(port) $(docker_name)

d:
	docker run -d $(port) $(docker_name)

sh:
	docker exec -i `docker ps | grep -Poe '^[a-z0-9]{12}'` bash

log:
	docker logs -f `docker ps -q --filter ancestor=$(docker_name) | head -1`


.PHONY:log R
