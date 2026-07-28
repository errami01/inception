NAME = inception
LOGIN    = aberrami
DATA_DIR = /home/$(LOGIN)/data
COMPOSE = docker compose -f srcs/docker-compose.yml

all: setup up

setup:
	echo "Creating data directories on the host..."
	@sudo mkdir -p /home/$(LOGIN)/data/wordpress
	@sudo mkdir -p /home/$(LOGIN)/data/mariadb
	@sudo chown -R $(USER):$(USER) /home/$(LOGIN)/data

up:
	$(COMPOSE) up --build

down:
	$(COMPOSE) down

start:
	$(COMPOSE) start

stop:
	$(COMPOSE) stop

logs:
	$(COMPOSE) logs -f

ps:
	$(COMPOSE) ps

clean:
	$(COMPOSE) down --volumes

fclean:
	$(COMPOSE) down --volumes --rmi all
	docker system prune -af

re: fclean all

.PHONY: all up down start stop logs ps clean fclean re