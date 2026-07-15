package main

import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strings"

main :: proc() {

	//TEST:
	track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	defer {
		if len(track.allocation_map) > 0 {
			fmt.eprintf("%v allocations not feed:\n", len(track.allocation_map))
			for _, entry in track.allocation_map {
				fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
			}
		} else {
			fmt.println("TEST: No unfreed allocations")
		}

		if len(track.bad_free_array) > 0 {
			fmt.eprintf("%v incorrect free:\n", len(track.bad_free_array))
			for entry in track.bad_free_array {
				fmt.eprintf("- %v bytes @ %v\n", entry.memory, entry.location)
			}
		} else {
			fmt.println("TEST: No bad free")
		}

		mem.tracking_allocator_destroy(&track)
	}

	// Config
	homePath, homePathErr := os.user_home_dir(context.allocator)
	defer delete_string(homePath)
	if homePathErr != nil do fmt.panicf("Failed to allocate User Home Directory: %v", homePathErr)

	config: Config
	cfgPath, cfgPathErr := os.join_path(
		{homePath, ".config", "hyprbind", "config.json"},
		context.allocator,
	)
	defer delete_string(cfgPath)
	if cfgPathErr != nil do fmt.panicf("Failed to allocate Config Filepath: %v", cfgPathErr)

	cfile := CFile(Config) {
		filepath = cfgPath,
		target   = &config,
		default  = {},
	}

	Create_Config(&cfile)
	Load_Config(&cfile)


	// Gather Binds
	procDesc, hyprctlErr := new(os.Process_Desc)
	defer free(procDesc)
	if hyprctlErr != nil do fmt.panicf("Failed to allocate hyprctl proc desc: %v", hyprctlErr)

	procDesc.command = []string{"hyprctl", "binds", "-j"}
	_, bindBytes, _, _ := os.process_exec(procDesc^, context.allocator)


	// Unmarshal bind data
	binds := make([dynamic]Bind_Json)
	defer Bind_Free(binds)

	json_err := json.unmarshal(bindBytes, &binds)
	if json_err != nil do fmt.panicf("Failed to unmarshal results: %v", json_err)

	delete_slice(bindBytes)

	// Get submap types
	submap_types := make([dynamic]string)
	defer delete(submap_types)
	for b in binds {
		smap := b.submap == "" ? "default" : b.submap
		if slice.contains(submap_types[:], smap) do continue
		append(&submap_types, smap)
	}

	assert(
		len(submap_types) > 0,
		"Could not find any submaps, and failed to capture default?!? oopsies",
	)

	// Parse Args
	args := os.args[1:]
	for len(args) > 0 {
		switch (args) {
		case:
			str := strings.starts_with(args[0], "-") ? "argument" : "value"
			fmt.eprintfln("Invalid %s: %s", str, args[0])
			args = args[1:]
		}
	}

	// Wofi Menu - Submap
	sel_submap := Wofi_Menu_Submap(submap_types)
	fmt.println(sel_submap)
	defer delete_string(sel_submap)

	// Wofi Menu - Keybinds
	Wofi_Menu_Keybind(binds, sel_submap)

}
