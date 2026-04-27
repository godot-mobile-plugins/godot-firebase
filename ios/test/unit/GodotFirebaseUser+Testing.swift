//
// © 2026-present Firebase Team https://github.com/firebase-team
//

@testable import firebase_plugin    // adjust to your actual module name
import Foundation

/// Swift-only extension on GodotFirebaseUser that exposes user data as a plain
/// [String: Any] dictionary.
///
/// GodotFirebaseUser.getRawData() returns a void * pointing to a Godot C++
/// Dictionary, which cannot be bridged to Swift.  This extension reads the six
/// ObjC properties directly and builds a native Swift dictionary, giving tests
/// a safe, type-checked way to assert on dictionary contents without any
/// C++ pointer arithmetic.
extension GodotFirebaseUser {
	var rawDataDictionary: [String: Any] {
		var d: [String: Any] = [:]
		d["user_id"]            = userId
		d["name"]               = name
		d["email"]              = email
		d["photo_url"]          = photoUrl
		d["is_email_verified"]  = isEmailVerified
		d["is_anonymous"]       = isAnonymous
		return d
	}
}
