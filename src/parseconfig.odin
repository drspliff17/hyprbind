package main

import "core:encoding/json"
import "core:fmt"
import "core:os"

Config :: struct {
	menu_runner: Menu_Runner,
}

CFile :: struct(T: typeid) {
	filepath: string,
	default:  T,
	target:   ^T,
}

// Returns true if new (values = c.default) is created, bool is false
Create_Config :: proc(c: ^CFile($T)) -> bool {
	if os.exists(c.filepath) {
		return false
	}

	config_dir := os.dir(c.filepath)
	if !os.exists(config_dir) {
		os.make_directory(config_dir)
		fmt.printfln("Created config directory at: %s", config_dir)
	}

	json_text, err := json.marshal(c.default, allocator = context.allocator)
	defer delete(json_text)

	if err != nil {
		panic("Failed to marshal default config")
	}

	werr := os.write_entire_file(c.filepath, json_text)
	if werr != nil {
		panic("Failed to write default config")
	}

	return true
}

Load_Config :: proc(c: ^CFile($T)) -> bool {
	if c.target == nil {
		panic("Target to unmarshal unset")
	}

	data, err := os.read_entire_file(c.filepath, context.allocator)
	defer delete(data)
	if err != nil {
		panic("Error when attempting to read config file")
	}

	ok := json.unmarshal(data, c.target) == nil
	// if ok {
	// 	fmt.println("Loaded Config")
	// }
	return ok
}
