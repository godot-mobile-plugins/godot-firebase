//
// © 2026-present Firebase Team https://github.com/firebase-team
//

@testable import firebase_plugin    // adjust to your actual module name
import XCTest

// MARK: - GodotFirebaseUserTests

final class GodotFirebaseUserTests: XCTestCase {

	// -----------------------------------------------------------------------
	// MARK: Designated initialiser
	// -----------------------------------------------------------------------

	func test_init_setsUserId() {
		let user = GodotFirebaseUser(
			userId: "uid-001", name: nil, email: nil, photoUrl: nil,
			isEmailVerified: false, isAnonymous: false
		)
		XCTAssertEqual(user.userId, "uid-001")
	}

	func test_init_setsName_whenProvided() {
		let user = GodotFirebaseUser(
			userId: "", name: "Alice", email: nil, photoUrl: nil,
			isEmailVerified: false, isAnonymous: false
		)
		XCTAssertEqual(user.name, "Alice")
	}

	func test_init_setsName_toEmptyString_whenNameIsNil() {
		let user = GodotFirebaseUser(
			userId: "", name: nil, email: nil, photoUrl: nil,
			isEmailVerified: false, isAnonymous: false
		)
		XCTAssertEqual(user.name, "")
	}

	func test_init_setsEmail_whenProvided() {
		let user = GodotFirebaseUser(
			userId: "", name: nil, email: "alice@example.com", photoUrl: nil,
			isEmailVerified: false, isAnonymous: false
		)
		XCTAssertEqual(user.email, "alice@example.com")
	}

	func test_init_setsEmail_toEmptyString_whenEmailIsNil() {
		let user = GodotFirebaseUser(
			userId: "", name: nil, email: nil, photoUrl: nil,
			isEmailVerified: false, isAnonymous: false
		)
		XCTAssertEqual(user.email, "")
	}

	func test_init_setsPhotoUrl_whenProvided() {
		let user = GodotFirebaseUser(
			userId: "", name: nil, email: nil,
			photoUrl: "https://example.com/photo.jpg",
			isEmailVerified: false, isAnonymous: false
		)
		XCTAssertEqual(user.photoUrl, "https://example.com/photo.jpg")
	}

	func test_init_setsPhotoUrl_toEmptyString_whenPhotoUrlIsNil() {
		let user = GodotFirebaseUser(
			userId: "", name: nil, email: nil, photoUrl: nil,
			isEmailVerified: false, isAnonymous: false
		)
		XCTAssertEqual(user.photoUrl, "")
	}

	func test_init_setsIsEmailVerified_true() {
		let user = GodotFirebaseUser(
			userId: "", name: nil, email: nil, photoUrl: nil,
			isEmailVerified: true, isAnonymous: false
		)
		XCTAssertTrue(user.isEmailVerified)
	}

	func test_init_setsIsEmailVerified_false() {
		let user = GodotFirebaseUser(
			userId: "", name: nil, email: nil, photoUrl: nil,
			isEmailVerified: false, isAnonymous: false
		)
		XCTAssertFalse(user.isEmailVerified)
	}

	func test_init_setsIsAnonymous_true() {
		let user = GodotFirebaseUser(
			userId: "anon-uid", name: nil, email: nil, photoUrl: nil,
			isEmailVerified: false, isAnonymous: true
		)
		XCTAssertTrue(user.isAnonymous)
	}

	func test_init_setsIsAnonymous_false() {
		let user = GodotFirebaseUser(
			userId: "", name: nil, email: nil, photoUrl: nil,
			isEmailVerified: false, isAnonymous: false
		)
		XCTAssertFalse(user.isAnonymous)
	}

	// -----------------------------------------------------------------------
	// MARK: Default (no-arg) initialiser
	// -----------------------------------------------------------------------

	func test_defaultInit_userId_isEmpty() {
		XCTAssertEqual(GodotFirebaseUser().userId, "")
	}

	func test_defaultInit_name_isEmpty() {
		XCTAssertEqual(GodotFirebaseUser().name, "")
	}

	func test_defaultInit_email_isEmpty() {
		XCTAssertEqual(GodotFirebaseUser().email, "")
	}

	func test_defaultInit_photoUrl_isEmpty() {
		XCTAssertEqual(GodotFirebaseUser().photoUrl, "")
	}

	func test_defaultInit_isEmailVerified_isFalse() {
		XCTAssertFalse(GodotFirebaseUser().isEmailVerified)
	}

	func test_defaultInit_isAnonymous_isFalse() {
		XCTAssertFalse(GodotFirebaseUser().isAnonymous)
	}

	// -----------------------------------------------------------------------
	// MARK: Property setters
	// -----------------------------------------------------------------------

	func test_setUserId_updatesValue() {
		let user = GodotFirebaseUser()
		user.userId = "updated-uid"
		XCTAssertEqual(user.userId, "updated-uid")
	}

	func test_setName_updatesValue() {
		let user = GodotFirebaseUser()
		user.name = "Bob"
		XCTAssertEqual(user.name, "Bob")
	}

	func test_setEmail_updatesValue() {
		let user = GodotFirebaseUser()
		user.email = "bob@example.com"
		XCTAssertEqual(user.email, "bob@example.com")
	}

	func test_setPhotoUrl_updatesValue() {
		let user = GodotFirebaseUser()
		user.photoUrl = "https://cdn.example.com/pic.png"
		XCTAssertEqual(user.photoUrl, "https://cdn.example.com/pic.png")
	}

	func test_setIsEmailVerified_toTrue_updatesValue() {
		let user = GodotFirebaseUser()
		user.isEmailVerified = true
		XCTAssertTrue(user.isEmailVerified)
	}

	func test_setIsAnonymous_toTrue_updatesValue() {
		let user = GodotFirebaseUser()
		user.isAnonymous = true
		XCTAssertTrue(user.isAnonymous)
	}

	// -----------------------------------------------------------------------
	// MARK: rawDataDictionary
	//
	// GodotFirebaseUser.getRawData() returns a void * to a Godot C++ Dictionary,
	// which cannot be bridged to Swift.  The rawDataDictionary extension
	// (GodotFirebaseUser+Testing.swift) builds a plain [String: Any] from the
	// six ObjC properties, giving tests a type-safe way to assert on the
	// dictionary representation without C++ pointer arithmetic.
	// -----------------------------------------------------------------------

	func test_rawDataDictionary_isNotNil() {
		XCTAssertFalse(GodotFirebaseUser().rawDataDictionary.isEmpty == false
					&& GodotFirebaseUser().rawDataDictionary.isEmpty == true)
		XCTAssertNotNil(GodotFirebaseUser().rawDataDictionary as [String: Any]?)
	}

	func test_rawDataDictionary_containsUserId() {
		let user = GodotFirebaseUser(
			userId: "raw-uid", name: nil, email: nil,
			photoUrl: nil, isEmailVerified: false, isAnonymous: false
		)
		XCTAssertEqual(user.rawDataDictionary["user_id"] as? String, "raw-uid")
	}

	func test_rawDataDictionary_containsName() {
		let user = GodotFirebaseUser(
			userId: "", name: "Carol", email: nil,
			photoUrl: nil, isEmailVerified: false, isAnonymous: false
		)
		XCTAssertEqual(user.rawDataDictionary["name"] as? String, "Carol")
	}

	func test_rawDataDictionary_containsEmail() {
		let user = GodotFirebaseUser(
			userId: "", name: nil, email: "carol@example.com",
			photoUrl: nil, isEmailVerified: false, isAnonymous: false
		)
		XCTAssertEqual(user.rawDataDictionary["email"] as? String, "carol@example.com")
	}

	func test_rawDataDictionary_containsPhotoUrl() {
		let user = GodotFirebaseUser(
			userId: "", name: nil, email: nil,
			photoUrl: "https://example.com/img.png",
			isEmailVerified: false, isAnonymous: false
		)
		XCTAssertEqual(user.rawDataDictionary["photo_url"] as? String, "https://example.com/img.png")
	}

	func test_rawDataDictionary_containsIsEmailVerified_true() {
		let user = GodotFirebaseUser(
			userId: "", name: nil, email: nil,
			photoUrl: nil, isEmailVerified: true, isAnonymous: false
		)
		XCTAssertEqual(user.rawDataDictionary["is_email_verified"] as? Bool, true)
	}

	func test_rawDataDictionary_containsIsAnonymous_true() {
		let user = GodotFirebaseUser(
			userId: "anon", name: nil, email: nil,
			photoUrl: nil, isEmailVerified: false, isAnonymous: true
		)
		XCTAssertEqual(user.rawDataDictionary["is_anonymous"] as? Bool, true)
	}

	func test_rawDataDictionary_reflectsMutations() {
		let user = GodotFirebaseUser()
		user.userId = "mutated-uid"
		user.email = "mutated@example.com"
		user.isEmailVerified = true

		let data = user.rawDataDictionary
		XCTAssertEqual(data["user_id"] as? String, "mutated-uid")
		XCTAssertEqual(data["email"] as? String, "mutated@example.com")
		XCTAssertEqual(data["is_email_verified"] as? Bool, true)
	}

	// -----------------------------------------------------------------------
	// MARK: rawDataDictionary via Authentication.getCurrentUser
	// -----------------------------------------------------------------------

	func test_getCurrentUser_rawDataDictionary_hasCorrectKeys() {
		let mockUser = MockAuthUser(
			uid: "map-uid",
			displayName: "Map User",
			email: "map@example.com",
			photoURL: URL(string: "https://example.com/p.png"),
			isEmailVerified: true,
			isAnonymous: false
		)
		let auth = MockAuth()
		auth.currentUser = mockUser
		let sut = Authentication(
			emitter: MockAuthenticationEmitter(),
			auth: auth,
			googleSignIn: MockGoogleSignIn()
		)

		let data = sut.getCurrentUser()?.rawDataDictionary

		XCTAssertEqual(data?["user_id"] as? String, "map-uid")
		XCTAssertEqual(data?["name"] as? String, "Map User")
		XCTAssertEqual(data?["email"] as? String, "map@example.com")
		XCTAssertEqual(data?["photo_url"] as? String, "https://example.com/p.png")
		XCTAssertEqual(data?["is_email_verified"] as? Bool, true)
		XCTAssertEqual(data?["is_anonymous"] as? Bool, false)
	}

	func test_getCurrentUser_rawDataDictionary_hasEmptyStringsForNilFields() {
		let anonUser = MockAuthUser(
			uid: "anon-map",
			displayName: nil,
			email: nil,
			photoURL: nil,
			isEmailVerified: false,
			isAnonymous: true
		)
		let auth = MockAuth()
		auth.currentUser = anonUser
		let sut = Authentication(
			emitter: MockAuthenticationEmitter(),
			auth: auth,
			googleSignIn: MockGoogleSignIn()
		)

		let data = sut.getCurrentUser()?.rawDataDictionary

		XCTAssertEqual(data?["name"] as? String, "")
		XCTAssertEqual(data?["email"] as? String, "")
		XCTAssertEqual(data?["photo_url"] as? String, "")
		XCTAssertEqual(data?["is_anonymous"] as? Bool, true)
	}
}
