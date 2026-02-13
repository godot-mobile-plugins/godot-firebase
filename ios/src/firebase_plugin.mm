//
// © 2026-present https://github.com/firebase-team
//

#import "firebase_plugin.h"

#import "firebase_plugin-Swift.h"

#import "firebase_logger.h"


const String TEMPLATE_READY_SIGNAL = "template_ready";
// TODO: Define all signals


FirebasePlugin* FirebasePlugin::instance = NULL;


void FirebasePlugin::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_firebase"), &FirebasePlugin::get_firebase);
	// TODO: Register all methods

	ADD_SIGNAL(MethodInfo(TEMPLATE_READY_SIGNAL, PropertyInfo(Variant::DICTIONARY, "a_dict")));
	// TODO: Register all signals
}

Array FirebasePlugin::get_firebase() {
	os_log_debug(firebase_log, "::get_firebase()");

	Array godot_array = Array();

	return godot_array;
}

FirebasePlugin::FirebasePlugin() {
	os_log_debug(firebase_log, "Plugin singleton constructor");

	ERR_FAIL_COND(instance != NULL);

	instance = this;
}

FirebasePlugin::~FirebasePlugin() {
	os_log_debug(firebase_log, "Plugin singleton destructor");

	if (instance == this) {
		instance = nullptr;
	}
}
