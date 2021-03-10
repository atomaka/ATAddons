install:
	cp -r ATMe/ $$WOW_ADDON_DIR
	cp -r ATAutoReactivateGoliath/ $$WOW_ADDON_DIR

update:
	cp -r $$WOW_ADDON_DIR/ATMe .
	cp -r $$WOW_ADDON_DIR/ATAutoReactivateGoliath .

clean:
	rm -f ATAutoReactivateGoliath.zip

archive: clean
	zip -r ATAutoReactivateGoliath ATAutoReactivateGoliath

upload: archive
	test $$WOW_GAME_VERSION
	curl -H "X-Api-Token: $$CURSEFORGE_TOKEN" \
		-F metadata='{changelog: "Initial upload", gameVersions: [$$WOW_GAME_VERSION], releaseType: "release"}' \
		-F file=@ATAutoReactivateGoliath.zip \
		https://wow.curseforge.com/api/projects/$$CURSEFORGE_PROJECT_ID/upload-file

version:
	@curl -s -H "X-Api-Token: $$CURSEFORGE_TOKEN" \
		https://wow.curseforge.com/api/game/versions | \
		jq ".[-1] | .id"
