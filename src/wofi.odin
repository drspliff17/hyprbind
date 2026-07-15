package main

import "core:fmt"
import "core:os"
import "core:strings"

Wofi_Menu_Submap :: proc(submap_types: [dynamic]string) -> string {
	builder: strings.Builder
	strings.builder_init(&builder)
	procDesc: os.Process_Desc

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
	defer delete_string(cmd)

	procDesc.command = []string{"sh", "-c", cmd}
	_, sel_submap_bytes, _, _ := os.process_exec(procDesc, context.allocator)
	defer delete_slice(sel_submap_bytes)

	if len(sel_submap_bytes) == 0 {
		delete_slice(sel_submap_bytes)
		os.exit(0)
	}

	sel_submap, sel_sub_changed := strings.remove_all(string(sel_submap_bytes), "\n")
	defer delete(sel_submap)
	return strings.clone(sel_submap, context.allocator)
}

Wofi_Menu_Keybind :: proc(binds: [dynamic]Bind_Json, sel_submap: string) {

	selected_submap_binds := Bind_Get_Map_Binds(binds, sel_submap)
	defer delete(selected_submap_binds)

	builder: strings.Builder
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

	procDesc: os.Process_Desc
	cmd := strings.join(
		{"printf '%s' '", wofi_submap_binds, "' | wofi -d -E -W 60% -H 40% -p ", sel_submap},
		"",
	)
	defer delete_string(cmd)


	procDesc.command = []string{"sh", "-c", cmd}
	_, sel_keybind_bytes, sel_keybind_err, _ := os.process_exec(procDesc, context.allocator)
	defer delete_slice(sel_keybind_bytes)
	defer delete_slice(sel_keybind_err)

}
