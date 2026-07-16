package main

import "core:encoding/json"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:slice"
import "core:strings"


printHelp :: proc() {
	str := `
            Hyprbind
---------------------------------
-s | stat [submap name]
-m | menu [mode]

Modes:
-s | submap
-sk| subkey
-k | key
`
	fmt.print(str)
	os.exit(0)
}

main :: proc() {

	state := State {
		mode     = .CLI,
		menuMode = .SUBMAPS,
	}

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
		target = &config,
		default = {
			submap_menu_runner = Menu_Runner {
				program = "wofi",
				arguments = {"-d", "-E", "-W 40%", "-p Submap", "--column 3", "--line 6"},
			},
			subkey_menu_runner = Menu_Runner {
				program = "wofi",
				arguments = {"-d", "-E", "-W 60%", "-H 60%", "-p Keybinds"},
			},
			allkey_menu_runner = Menu_Runner {
				program = "wofi",
				arguments = {"-d", "-E", "-W 60%", "-H 60%", "-p All Keybinds"},
			},
		},
	}
	defer Config_Free(&config)

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

	if len(args) == 0 do printHelp()
	for len(args) > 0 {
		switch (args[0]) {

		case "-h", "--help", "help":
			printHelp()

		case "-s", "--stat", "stat":
			// Stat All
			if len(args) < 2 {
				Stat_All(binds, submap_types)
				os.exit(0)
			}

			// Stat Submap
			if !isValidSubmap(submap_types, args[1]) {
				fmt.eprintfln("[Error] Invalid value given: %s", args[1])
				fmt.println("Valid submaps are: ")
				for s in submap_types {
					fmt.printfln("%s", s)
				}
				os.exit(1)
			} else {
				Stat_Submap(binds, submap_types, args[1])
				os.exit(0)
			}

		case "-m", "--menu", "menu":
			if len(args) < 2 {
				fmt.eprintln("[Error] Expected value to set Mode")
				os.exit(1)
			}

			switch (args[1]) {
			case "-s", "--submap", "submap":
				state.menuMode = .SUBMAPS

			case "-sk", "--subkey", "subkey":
				state.menuMode = .BINDS

			case "-k", "--key", "key":
				state.menuMode = .ALL_BINDS

			case:
				fmt.eprintfln("[Error] Invalid value given: %s", args[1])
				os.exit(1)
			}

			state.mode = .MENU
			args = args[2:]

		case:
			str := strings.starts_with(args[0], "-") ? "argument" : "value"
			fmt.eprintfln("[Error] Invalid %s: %s", str, args[0])
			args = args[1:]
		}
	}


	switch (state.mode) {
	case .CLI:

	case .MENU:
		switch (state.menuMode) {
		case .SUBMAPS:
			pd := Construct_ProcDesc_From_Menu_Runner(config.submap_menu_runner)
			defer Menu_Runner_ProcDesc_Free(pd)

			selectedSubmap := Menu_Submap(&config, submap_types)
			defer delete_string(selectedSubmap)

			if len(selectedSubmap) == 0 do break
		// Stat_Submap(binds, submap_types, selectedSubmap)
		// Stat_All(binds, submap_types)

		case .BINDS:
			pd := Construct_ProcDesc_From_Menu_Runner(config.submap_menu_runner)
			defer Menu_Runner_ProcDesc_Free(pd)

			loop := true
			for loop {
				selectedSubmap := Menu_Submap(&config, submap_types)
				defer delete_string(selectedSubmap)

				if len(selectedSubmap) == 0 {
					break
				}

				selectedKeybind := Menu_Keybind(&config, binds, selectedSubmap)
				defer delete_string(selectedKeybind)

				if len(selectedKeybind) > 0 {
					fmt.printf(selectedKeybind)
					loop = false
				}
			}

		case .ALL_BINDS:
			pd := Construct_ProcDesc_From_Menu_Runner(config.allkey_menu_runner)
			defer Menu_Runner_ProcDesc_Free(pd)

			selectedKeybind := Menu_AllKey(&config, binds)
			defer delete_string(selectedKeybind)

			if len(selectedKeybind) == 0 {
				os.exit(0)
			}

			fmt.printf(selectedKeybind)

		}

	//TEST:

	// targ := Construct_ProcDesc_From_Menu_Runner(config.menu_runner)
	// defer Menu_Runner_ProcDesc_Free(targ)
	// state.selectedSubmap = Menu_Submap(&config, submap_types)
	// defer delete_string(state.selectedSubmap)
	//
	// state.selectedKeybind = Menu_Keybind(&config, binds, state.selectedSubmap)
	// defer delete_string(state.selectedKeybind)

	// fmt.println(state.selectedKeybind)

	//
	// Wofi Menu - Submap

	// state.selectedSubmap = Wofi_Menu_Submap(submap_types)
	// fmt.println(state.selectedSubmap)
	// defer delete_string(state.selectedSubmap)

	// Wofi Menu - Keybinds
	// state.selectedKeybind = Wofi_Menu_Keybind(binds, state.selectedSubmap)
	// fmt.println(state.selectedKeybind)
	// defer delete_string(state.selectedKeybind)

	}


}
