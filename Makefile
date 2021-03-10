install:
	cp -r ATMe/ $$WOW_ADDON_DIR
	cp -r ATAutoReactivateGoliath/ $$WOW_ADDON_DIR

update:
	cp -r $$WOW_ADDON_DIR/ATMe .
	cp -r $$WOW_ADDON_DIR/ATAutoReactivateGoliath .
