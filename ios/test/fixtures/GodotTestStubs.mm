//
// © 2026-present Firebase Team https://github.com/firebase-team
//

// GodotTestStubs.mm
//
// libgodot.ios.template_debug.arm64.simulator.a contains object files that
// reference four symbols normally provided by the Godot iOS host application:
//
//   _SDL_IsAppleTV                         (SDL.o)
//   _SDL_IsIPad                            (SDL.o)
//   godot_apple_embedded_plugins_initialize()   (api.o)
//   godot_apple_embedded_plugins_deinitialize() (api.o)
//
// The XCTest bundle has no host application, so the linker cannot resolve
// them.  This file provides no-op stubs so the test binary links cleanly.
// None of these functions are called during unit tests — they are only
// referenced by Godot's startup/shutdown paths which never execute in the
// test process.
//
// This file must be a member of the firebase_plugin_tests target ONLY.

#include <stdbool.h>

// ---------------------------------------------------------------------------
// SDL device-type queries
// ---------------------------------------------------------------------------

extern "C" bool SDL_IsAppleTV(void) { return false; }
extern "C" bool SDL_IsIPad(void)    { return false; }

// ---------------------------------------------------------------------------
// Godot Apple Embedded plugin lifecycle
// ---------------------------------------------------------------------------

// The real implementations live in the Godot plugin bootstrap (registered via
// GDNATIVE_INIT / GDNATIVE_TERMINATE macros).  In the test process we simply
// do nothing.
void godot_apple_embedded_plugins_initialize()   {}
void godot_apple_embedded_plugins_deinitialize() {}
