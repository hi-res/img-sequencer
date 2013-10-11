CS=node_modules/coffee-script/bin/coffee

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

tester:

	@echo 'Running exporter test'
	cd test && sh exporter.sh