package main

import "core:fmt"
import "core:strconv"
import "core:strings"

Bind_Json :: struct {
	locked:           bool,
	mouse:            bool,
	release:          bool,
	repeat:           bool,
	longPress:        bool,
	non_consuming:    bool,
	auto_consuming:   bool,
	has_description:  bool,
	catch_all:        bool,
	modmask:          int,
	keycode:          int,
	submap:           string,
	submap_universal: string,
	key:              string,
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
	s := smap == "default" ? "" : smap
	result := make([dynamic]Bind_Json)

	for b in bl {
		if b.submap == s {
			append(&result, b)
		}
	}

	return result
}

// Returns the index of correct Bind struct for a given menu key string (Wofi_Menu_Keybind)
Bind_Get_From_List :: proc(
	bl: [dynamic]Bind_Json,
	submap, menu_key_sig: string,
) -> (
	idx: int,
	found: bool,
) {
	s := submap == "default" ? "" : submap
	for b, i in bl {
		if b.submap != s do continue
		raw_parts := strings.split(menu_key_sig, "-", context.allocator)

		mm := strings.trim_left(raw_parts[0], "Modmask: ")
		cm, cmErr := strconv.parse_int(mm)
		if !cmErr do fmt.panicf("Failed to parse Modmask to Int: %v", cmErr)

		k := strings.trim_left(raw_parts[1], "Key: ")

		if k == b.key && cm == b.modmask {
			delete(raw_parts)
			return i, true
		}

		// delete_string(mm)
		delete(raw_parts)
	}
	return -1, false
}

Bind_Modmask_To_String :: proc(mask: int, allocator := context.allocator) -> string {
	parts := make([dynamic]string, allocator)
	defer delete(parts)

	if mask == 0 do append(&parts, "NONE")
	if mask & 1 != 0 {append(&parts, "SHIFT")}
	if mask & 2 != 0 {append(&parts, "CAPS")}
	if mask & 4 != 0 {append(&parts, "CTRL")}
	if mask & 8 != 0 {append(&parts, "ALT")}
	if mask & 64 != 0 {append(&parts, "SUPER")}

	if len(parts) == 0 {
		return strings.clone("", allocator)
	}

	return strings.join(parts[:], " + ", allocator)
}
