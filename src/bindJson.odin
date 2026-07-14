package main

Bind_JSON :: struct {
	locked:           bool,
	mouse:            bool,
	release:          bool,
	repeat:           bool,
	longPress:        bool,
	non_consuming:    bool,
	auto_consuming:   bool,
	has_description:  bool,
	modmask:          u16,
	submap:           string,
	submap_universal: string,
	key:              string,
	keycode:          int,
	catch_all:        bool,
	description:      string,
	dispatcher:       string,
	arg:              string,
}

Bind_From_JSON :: proc(inBind: Bind_JSON) {
	b := Bind_Create()
	flags: u16 = 0

	if inBind.locked do Bind_Flag_Set(&flags, .LOCKED)
	if inBind.mouse do Bind_Flag_Set(&flags, .MOUSE)
	if inBind.release do Bind_Flag_Set(&flags, .RELEASE)
	if inBind.repeat do Bind_Flag_Set(&flags, .REPEAT)
	if inBind.longPress do Bind_Flag_Set(&flags, .LONGPRESS)
	if inBind.non_consuming do Bind_Flag_Set(&flags, .NON_CONSUME)
	if inBind.auto_consuming do Bind_Flag_Set(&flags, .AUTO_CONSUME)
	if inBind.has_description do Bind_Flag_Set(&flags, .HAS_DESC)
	if inBind.catch_all do Bind_Flag_Set(&flags, .CATCH_ALL)
	if inBind.submap_universal == "true" do Bind_Flag_Set(&flags, .UNIVERSAL)

	b.flags = flags
	b.modmask = inBind.modmask
	b.submap = inBind.submap
	b.key = inBind.key
	b.desc = inBind.description
	b.arg = inBind.arg
}
