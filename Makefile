CWD := $(shell readlink -en $(dir $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))))
PLUGIN_NAME := rizzi-guestbook
SHELL := /bin/bash

.PHONY: all
all: clean fetch_dependancies

.PHONY: start
start: clean install
	@make database &
	@sleep 5
	@make wordpress &
	@make sql_client &

.PHONY: wordpress
wordpress:
	@docker run --name some-instant-wordpress --rm --link some-mariadb:mysql -p 8888:80 -e DEBUG=true -v $(CWD)/$(PLUGIN_NAME):/var/www/html/wp-content/plugins/$(PLUGIN_NAME) jamrizzi/instant-wordpress:latest

.PHONY: database
database:
	@docker run --name some-mariadb --rm -e MYSQL_ROOT_PASSWORD=hellodocker -e MYSQL_DATABASE=wordpress -e MYSQL_USER=admin -e MYSQL_PASSWORD=hellowordpress mariadb:latest

.PHONY: sql_client
sql_client:
	@docker run --name some-phpmyadmin --rm --link some-mariadb:db -p 8889:80 phpmyadmin/phpmyadmin:latest

.PHONY: install
install:
	@composer install

.PHONY: package
package: install
	@zip -r $(PLUGIN_NAME).zip $(PLUGIN_NAME)

.PHONY: init
init:
	@docker run --name some-php --rm -it -v $(CWD):/app/ -w /app/ php:7.0-cli bash -c "php tools.php init"

.PHONY: stop
stop:
	@docker stop some-instant-wordpress &
	@docker stop some-mariadb &
	@docker stop some-phpmyadmin &
	@echo stopped

.PHONY: clean
clean:
	-@rm -rf ./$(PLUGIN_NAME).zip ./i18n-tools
	@echo cleaned

.PHONY: ssh
ssh:
	@dockssh -e some-instant-wordpress

.PHONY: pot
pot: i18n-tools
	@php ./i18n-tools/makepot.php wp-plugin ./rizzi-guestbook/
	@mv ./rizzi-guestbook.pot ./rizzi-guestbook/languages/rizzi-guestbook.pot

i18n-tools:
	@svn checkout http://i18n.svn.wordpress.org/tools/trunk/ i18n-tools

.PHONY: fetch_dependancies
fetch_dependancies: docker
	@echo fetched dependancies
.PHONY: docker
docker:
ifeq ($(shell whereis docker), $(shell echo docker:))
	@curl -L https://get.docker.com/ | bash
endif
	@echo fetched docker
