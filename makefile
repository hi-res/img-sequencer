CS=node_modules/coffee-script/bin/coffee
MOCHA=node_modules/mocha/bin/mocha

MVERSION=node_modules/mversion/bin/version
VERSION=0.0.3

setup:
	npm install
	npm install -g shelljs
	npm install -g image-size
	brew install imagemagick

watch:
	@$(CS) -w -b -cj lib/index.js src/*.coffee

build:
	@$(CS) -b -cj lib/index.js src/*.coffee


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
	cd test && shjs exporter