CS=node_modules/coffee-script/bin/coffee
MOCHA=node_modules/mocha/bin/mocha

MVERSION=node_modules/mversion/bin/version
VERSION=0.0.1

setup:

	npm install

watch:
	@$(CS) -bwo lib src

build:
	@$(CS) -bco lib src	


bump.minor:
	@$(MVERSION) minor

bump.major:
	@$(MVERSION) major

bump.patch:
	@$(MVERSION) patch

publish:
	git tag $(VERSION)
	git push origin $(VERSION)
	git push origin master
	npm publish

re-publish:
	git tag -d $(VERSION)
	git tag $(VERSION)
	git push origin :$(VERSION)
	git push origin $(VERSION)
	git push origin master -f
	npm publish -f


test:
	@$(MOCHA) --compilers coffee:coffee-script \
		--ui bdd \
		--reporter spec \
		--timeout 600000 \
		tests/runner.coffee --env='local'

test-server:
 
	python -m SimpleHTTPServer 8080

test-exporter:

	@echo 'Running exporter test'
	cd test && sh exporter.sh