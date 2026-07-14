package main

import "core:fmt"
import "core:os"
import "core:strings"

main :: proc() {

	BIND_LIST := Bind_List_Create()
	defer Bind_List_Delete(BIND_LIST)

	hyprctlDesc, hyprctlErr := new(os.Process_Desc)
	defer free(hyprctlDesc)
	if hyprctlErr != nil do fmt.panicf("Failed to allocate hyprctl proc desc: %v", hyprctlErr)
	hyprctlDesc.command = []string{"hyprctl", "binds"}

	_, stdout, _, _ := os.process_exec(hyprctlDesc^, context.allocator)

	// testFlag: 16 = 0
	//
	// Bind_Flag_Set(&testFlag, .LOCKED)
	// Bind_Flag_Set(&testFlag, .RELEASE)
	//
	// fmt.printfln("Flag is %02b", testFlag)

}
