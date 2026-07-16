package main

import "core:fmt"
import "core:slice"

isValidSubmap :: proc(submap_types: [dynamic]string, submap: string) -> bool {
	return slice.contains(submap_types[:], submap)
}

Stat_All :: proc(binds: [dynamic]Bind_Json, submap_types: [dynamic]string) {
	c: int
	for s in submap_types {
		b := Bind_Get_Map_Binds(binds, s)
		defer delete(b)

		str := fmt.aprintf("Submap: %s - Bind Count: %d\n", s, len(b))
		defer delete_string(str)
		fmt.print(str)

		c += len(b)
	}
	fmt.printfln("Total Keybinds: %d", c)
	return
}

Stat_Submap :: proc(binds: [dynamic]Bind_Json, submap_types: [dynamic]string, submap: string) {
	for s in submap_types {
		if s == submap {
			count: int
			smap := submap == "default" ? "" : submap

			for b in binds {
				if b.submap == smap do count += 1
			}

			str := fmt.aprintf("Submap: %s\nBinds in map: %d\n", s, count)
			defer delete_string(str)
			fmt.print(str)
			return
		}
	}
}
