package main

Bind_Json :: struct {
	locked:           bool,
	mouse:            bool,
	release:          bool,
	repeat:           bool,
	longPress:        bool,
	non_consuming:    bool,
	auto_consuming:   bool,
	has_description:  bool,
	modmask:          int,
	submap:           string,
	submap_universal: string,
	key:              string,
	keycode:          int,
	catch_all:        bool,
	description:      string,
	dispatcher:       string,
	arg:              string,
}

Bind_Free :: proc(bl: [dynamic]Bind_Json) {
	for b in bl {
		delete_string(b.submap)
		delete_string(b.submap_universal)
		delete_string(b.key)
		delete_string(b.description)
		delete_string(b.dispatcher)
		delete_string(b.arg)
	}
	delete(bl)
}

Bind_Get_Map_Binds :: proc(bl: [dynamic]Bind_Json, smap: string) -> [dynamic]Bind_Json {
	result := make([dynamic]Bind_Json)

	for b in bl {
		if b.submap == smap {
			append(&result, b)
		}
	}

	return result
}
