//
// © 2026-present https://github.com/firebase-team
//

// Only headers that are free of Godot/C++ types may appear here.
// FirebasePluginSignalEmitter.h is intentionally excluded: its .mm
// implementation uses Godot C++ types (MethodInfo, Variant, String) and is
// imported directly by firebase_plugin.mm, which is compiled as Objective-C++.
// Pulling it into the bridging header would expose those C++ types to the
// Swift compiler, which does not support them.
#import "FirestoreDocument.h"
#import "FirestoreError.h"
#import "FirestoreResult.h"
#import "GodotFirebaseUser.h"
#import "SignalEmitting.h"
