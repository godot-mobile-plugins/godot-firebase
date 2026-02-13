//
// © 2026-present https://github.com/firebase-team
//

#ifndef firebase_plugin_h
#define firebase_plugin_h

#import <Foundation/Foundation.h>

#include "core/object/object.h"
#include "core/object/class_db.h"


@class Firebase;


extern const String TEMPLATE_READY_SIGNAL;
// TODO: Declare all signals


class FirebasePlugin : public Object {
	GDCLASS(FirebasePlugin, Object);

private:
	static FirebasePlugin* instance; // Singleton instance

	static void _bind_methods();

public:
	Array get_firebase();
	// TODO: Declare all methods

	FirebasePlugin();
	~FirebasePlugin();
};

#endif /* firebase_plugin_h */
