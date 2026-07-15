package main

// Mode for program's main execution
metaMode :: enum {
	CLI,
	MENU,
}

// Built-in Modes for Menu content
menuMode :: enum {
	SUBMAPS,
	BINDS,
}

State :: struct {
	mode:            metaMode,
	menuMode:        menuMode,
	selectedSubmap:  string,
	selectedKeybind: string,
}
