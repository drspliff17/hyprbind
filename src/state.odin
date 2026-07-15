package main

metaMode :: enum {
	CLI,
	WOFI,
}

State :: struct {
	mode: metaMode,
}
