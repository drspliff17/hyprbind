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
			"' | wofi -d -E -W 40% -p 'Select Submap' --column 3 --line ",
			wofi_smap_linecount,
		},
		"",
	)

	procDesc.command = []string{"sh", "-c", cmd}
	_, sel_submap_bytes, _, _ := os.process_exec(procDesc^, context.allocator)
	defer delete_slice(sel_submap_bytes)

	if len(sel_submap_bytes) == 0 do os.exit(0)
	sel_submap, sel_sub_changed := strings.remove_all(string(sel_submap_bytes), "\n")
	defer delete(sel_submap)

	if sel_submap == "default" {
		delete(sel_submap)
		sel_submap = ""
	}


	// Wofi Menu - Keybinds
	selected_submap_binds := Bind_Get_Map_Binds(binds, sel_submap)
	defer delete(selected_submap_binds)

	strings.builder_init(&builder)
	for b, i in selected_submap_binds {
		if i > 0 {
			strings.write_string(&builder, "\n")
		}
		str := fmt.aprintf("Modmask: %d - Key: %s - %s", b.modmask, b.key, b.description)
		strings.write_string(&builder, str)
		delete_string(str)
	}

	wofi_submap_binds := strings.to_string(builder)
	defer delete_string(wofi_submap_binds)

	delete_string(cmd)
	cmd = strings.join(
		{"printf '%s' '", wofi_submap_binds, "' | wofi -d -E -W 60% -H 40% --p ", sel_submap},
		"",
	)
	defer delete_string(cmd)


	procDesc.command = []string{"sh", "-c", cmd}
	_, sel_keybind_bytes, sel_keybind_err, _ := os.process_exec(procDesc^, context.allocator)
	defer delete_slice(sel_keybind_bytes)
	defer delete_slice(sel_keybind_err)

}
