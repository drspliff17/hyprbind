package main

import "core:fmt"

Bind_List_Create :: proc() -> [dynamic]^Bind {
	bl, err := make([dynamic]^Bind)
	if err != nil do fmt.panicf("Failed to allocate [dynamic]^Bind: %v", err)
	return bl
}

Bind_List_Delete :: proc(bl: [dynamic]^Bind) {
	for bind in bl {
		Bind_Delete(bind)
	}
	delete(bl)
}
