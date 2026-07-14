package main

import "core:fmt"

Bind :: struct {
	submap:  string,
	desc:    string,
	key:     string,
  arg:     string,
	flags:   u16,
	modmask: u16,
}

Bind_Create :: proc() -> ^Bind {
	b, err := new(Bind)
	if err != nil do fmt.panicf("Failed to allocate [Bind]: %v", err)
	return b
}

Bind_Delete :: proc(b: ^Bind) {
	free(b)
}
