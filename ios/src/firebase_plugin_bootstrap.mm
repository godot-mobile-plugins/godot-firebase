//
// © 2026-present https://github.com/firebase-team
//

#import <Foundation/Foundation.h>

#import "firebase_plugin_bootstrap.h"
#import "firebase_plugin.h"
#import "firebase_logger.h"

#import "core/config/engine.h"


FirebasePlugin *firebase_plugin;


void firebase_plugin_init() {
	os_log_debug(firebase_log, "FirebasePlugin: Initializing plugin at timestamp: %f", [[NSDate date] timeIntervalSince1970]);

	firebase_plugin = memnew(FirebasePlugin);
	Engine::get_singleton()->add_singleton(Engine::Singleton("FirebasePlugin", firebase_plugin));
	os_log_debug(firebase_log, "FirebasePlugin: Singleton registered");
}


void firebase_plugin_deinit() {
	os_log_debug(firebase_log, "FirebasePlugin: Deinitializing plugin");
	firebase_log = NULL; // Prevent accidental reuse

	if (firebase_plugin) {
		memdelete(firebase_plugin);
		firebase_plugin = nullptr;
	}
}
