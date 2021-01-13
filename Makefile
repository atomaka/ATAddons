install:
	cp MyAddon.lua $$WOW_ADDON_DIR/MyAddon/
	cp MyAddon.toc $$WOW_ADDON_DIR/MyAddon/

update:
	cp -r $$WOW_ADDON_DIR/MyAddon/* .
