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
			fmt.println("No allocations")
		}

		if len(track.bad_free_array) > 0 {
			fmt.eprintf("%v incorrect free:\n", len(track.bad_free_array))
			for entry in track.bad_free_array {
				fmt.eprintf("- %v bytes @ %v\n", entry.memory, entry.location)
			}
		} else {
			fmt.println("No bad free")
		}

		mem.tracking_allocator_destroy(&track)
	}

	// Gather Binds
	procDesc, hyprctlErr := new(os.Process_Desc)
	defer free(procDesc)
	if hyprctlErr != nil do fmt.panicf("Failed to allocate hyprctl proc desc: %v", hyprctlErr)

	procDesc.command = []string{"hyprctl", "binds", "-j"}
	_, bindBytes, _, _ := os.process_exec(procDesc^, context.allocator)

	// Unmarshal data
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
	builder: strings.Builder
	strings.builder_init(&builder)

	// strings.builder_destroy(&builder)

	for s, i in submap_types {
		if i > 0 {
			strings.write_string(&builder, "\n")
		}
		strings.write_string(&builder, s)
	}

	wofi_submaps := strings.to_string(builder)
	defer delete_string(wofi_submaps)

	wofi_smap_linecount := fmt.aprintf("%d", ((len(submap_types) + 3 - 1) / 3))
	defer delete_string(wofi_smap_linecount)

	cmd := strings.join(
		{
			"printf '%s' '",
			wofi_submaps,
			"' | wofi -d -E -W 40% --column 3 --line ",
			wofi_smap_linecount,
		},
		"",
	)
	defer delete_string(cmd)

	procDesc.command = []string{"sh", "-c", cmd}
	_, selected_submap, _, _ := os.process_exec(procDesc^, context.allocator)
	defer delete_slice(selected_submap)

	// fmt.print(string(selected_submap))

}
