package main

import "core:fmt"
import "core:os"
import "core:slice"

Menu_Runner :: struct {
	program:   string,
	arguments: []string,
}

Construct_ProcDesc_From_Menu_Runner :: proc(p: Menu_Runner) -> ^os.Process_Desc {
	pd, err := new(os.Process_Desc)
	if err != nil do fmt.panicf("Failed to allocate Process_Desc: %v", err)

	str := make([dynamic]string)
	defer delete(str)

	append(&str, p.program)
	for a in p.arguments {
		append(&str, a)
	}

	pd.command = slice.clone(str[:], context.allocator)

	return pd
}

Menu_Runner_Free :: proc(m: ^Menu_Runner) {
	for s in m.arguments {
		delete(s)
	}
	delete(m.arguments)
	delete(m.program)
}

Config_Free :: proc(c: ^Config) {
	Menu_Runner_Free(&c.menu_runner)
}
