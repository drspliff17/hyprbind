package main

import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"

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


	// Wofi Menu - Submap
	sel_submap := Wofi_Menu_Submap(submap_types)
	fmt.println(sel_submap)
	defer delete_string(sel_submap)

	// Wofi Menu - Keybinds
	Wofi_Menu_Keybind(binds, sel_submap)

}
