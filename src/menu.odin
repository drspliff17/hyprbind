package main

import "core:fmt"
import "core:os"
import "core:slice"
import "core:strings"

// Loaded from config file, encapsulates the menu program of choice, and any arguments that should be passed
Menu_Runner :: struct {
	program:   string,
	arguments: []string,
}

// Free memory allocated when loading m from config file
Menu_Runner_Free :: proc(m: ^Menu_Runner) {
	delete_string(m.program)
	for s in m.arguments {
		delete_string(s)
	}
	delete_slice(m.arguments)
}

// Returns ptr to os.Process_Desc, with command filled from p properties
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

// Returns stringified arguments from given Menu_Runner
Menu_Runner_To_String :: proc(p: Menu_Runner) -> string {
	str := make([dynamic]string)
	defer delete(str)

	append(&str, p.program)
	for a in p.arguments {
		append(&str, a)
	}

	cstr := strings.join(str[:], " ", context.allocator)
	defer delete(cstr)
	return strings.clone(cstr, context.allocator)
}

// Free Menu_Runner os.Process_Desc
Menu_Runner_ProcDesc_Free :: proc(pd: ^os.Process_Desc) {
	delete_slice(pd.command)
	free(pd)
}

// Free all Menu_Runners
Config_Free :: proc(c: ^Config) {
	Menu_Runner_Free(&c.submap_menu_runner)
	Menu_Runner_Free(&c.subkey_menu_runner)
	Menu_Runner_Free(&c.allkey_menu_runner)
}

// Run config.submap_menu_runner
Menu_Submap :: proc(config: ^Config, submap_types: [dynamic]string) -> string {
	builder: strings.Builder
	strings.builder_init(&builder)
	procDesc: os.Process_Desc

	for s, i in submap_types {
		if i > 0 {
			strings.write_string(&builder, "\n")
		}
		strings.write_string(&builder, s)
	}

	submaps := strings.to_string(builder)
	defer delete_string(submaps)

	menuDesc := Construct_ProcDesc_From_Menu_Runner(config.submap_menu_runner)
	defer Menu_Runner_ProcDesc_Free(menuDesc)

	menuArgs := Menu_Runner_To_String(config.submap_menu_runner)
	defer delete_string(menuArgs)

	cmd := strings.join({"printf '%s' '", submaps, "' | ", menuArgs}, "")
	defer delete_string(cmd)

	procDesc.command = []string{"sh", "-c", cmd}
	_, sel_submap_bytes, _, _ := os.process_exec(procDesc, context.allocator)
	defer delete_slice(sel_submap_bytes)

	if len(sel_submap_bytes) == 0 {
		return ""
	}

	str := string(sel_submap_bytes)
	sel_submap, _ := strings.remove_all(string(sel_submap_bytes), "\n")
	return sel_submap
}

// Run config.subkey_menu_runner
Menu_Keybind :: proc(
	config: ^Config,
	binds: [dynamic]Bind_Json,
	sel_submap: string,
) -> (
	key_sig: string,
) {

	selected_submap_binds := Bind_Get_Map_Binds(binds, sel_submap)
	defer delete(selected_submap_binds)

	builder: strings.Builder
	strings.builder_init(&builder)

	for b, i in selected_submap_binds {
		if i > 0 {
			strings.write_string(&builder, "\n")
		}

		modmaskString := Bind_Modmask_To_String(b.modmask)
		defer delete_string(modmaskString)

		str := fmt.aprintf("Modmask: %s - Key: %s - %s", modmaskString, b.key, b.description)
		strings.write_string(&builder, str)
		delete_string(str)
	}

	submap_binds := strings.to_string(builder)
	defer delete_string(submap_binds)

	procDesc: os.Process_Desc

	menuDesc := Construct_ProcDesc_From_Menu_Runner(config.subkey_menu_runner)
	defer Menu_Runner_ProcDesc_Free(menuDesc)

	menuArgs := Menu_Runner_To_String(config.subkey_menu_runner)
	defer delete_string(menuArgs)

	cmd := strings.join({"printf '%s' '", submap_binds, "' | ", menuArgs}, "")
	defer delete_string(cmd)

	procDesc.command = []string{"sh", "-c", cmd}
	_, sel_keybind_bytes, sel_keybind_err, _ := os.process_exec(procDesc, context.allocator)
	defer delete_slice(sel_keybind_bytes)
	defer delete_slice(sel_keybind_err)
	return strings.clone(string(sel_keybind_bytes), context.allocator)
}

// Run config.subkey_menu_runner
Menu_AllKey :: proc(config: ^Config, binds: [dynamic]Bind_Json) -> (key_sig: string) {

	builder: strings.Builder
	strings.builder_init(&builder)

	for b, i in binds {
		if i > 0 {
			strings.write_string(&builder, "\n")
		}

		modmaskString := Bind_Modmask_To_String(b.modmask)
		defer delete_string(modmaskString)

		sm := b.submap == "" ? "default" : b.submap
		str := fmt.aprintf(
			"[Submap: %s]  Modmask: %s  -  Key: %s  -  %s",
			sm,
			modmaskString,
			b.key,
			b.description,
		)
		strings.write_string(&builder, str)
		delete_string(str)
	}

	submap_binds := strings.to_string(builder)
	defer delete_string(submap_binds)

	procDesc: os.Process_Desc

	menuDesc := Construct_ProcDesc_From_Menu_Runner(config.subkey_menu_runner)
	defer Menu_Runner_ProcDesc_Free(menuDesc)

	menuArgs := Menu_Runner_To_String(config.allkey_menu_runner)
	defer delete_string(menuArgs)

	cmd := strings.join({"printf '%s' '", submap_binds, "' | ", menuArgs}, "")
	defer delete_string(cmd)

	procDesc.command = []string{"sh", "-c", cmd}
	_, sel_keybind_bytes, sel_keybind_err, _ := os.process_exec(procDesc, context.allocator)
	defer delete_slice(sel_keybind_bytes)
	defer delete_slice(sel_keybind_err)
	return strings.clone(string(sel_keybind_bytes), context.allocator)
}
