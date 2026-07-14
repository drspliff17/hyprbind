package main

// NOTE: 6 spare bits in u16 bitset

BIND_FLAGS :: enum {
	LOCKED,
	MOUSE,
	RELEASE,
	REPEAT,
	LONGPRESS,
	NON_CONSUME,
	AUTO_CONSUME,
	HAS_DESC,
	UNIVERSAL,
	CATCH_ALL,
}

Bind_Flag_Set :: proc(flags: ^u16, flag: BIND_FLAGS) {
	flags^ |= 1 << u16(flag)
}

Bind_Flag_Clear :: proc(flags: ^u16, flag: BIND_FLAGS) {
	flags^ &= ~(1 << u16(flag))
}

Bind_Flag_Has :: proc(flags: u16, flag: BIND_FLAGS) -> bool {
	return (flags & (1 << u16(flag))) != 0
}
