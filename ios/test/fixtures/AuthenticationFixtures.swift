//
// © 2026-present Firebase Team https://github.com/firebase-team
//

@testable import firebase_plugin    // adjust to your actual module name
import FirebaseAuth
import Foundation
import UIKit

// MARK: - MockAuthenticationEmitter

/// Captures every signal emitted by Authentication so tests can assert on it
/// without needing a live Godot object.
final class MockAuthenticationEmitter: NSObject, SignalEmitting {

	private(set) var authSuccessUsers: [GodotFirebaseUser] = []
	private(set) var authFailureErrors: [String] = []
	private(set) var linkSuccessUsers: [GodotFirebaseUser] = []
	private(set) var linkFailureErrors: [String] = []
	private(set) var signOutSuccessValues: [Bool] = []
	private(set) var passwordResetSentValues: [Bool] = []
	private(set) var emailVerificationSentValues: [Bool] = []
	private(set) var userDeletedValues: [Bool] = []

	var lastAuthSuccess: GodotFirebaseUser? { authSuccessUsers.last }
	var lastAuthFailure: String? { authFailureErrors.last }
	var lastLinkSuccess: GodotFirebaseUser? { linkSuccessUsers.last }
	var lastLinkFailure: String? { linkFailureErrors.last }
	var lastSignOutSuccess: Bool? { signOutSuccessValues.last }
	var lastPasswordResetSent: Bool? { passwordResetSentValues.last }
	var lastEmailVerificationSent: Bool? { emailVerificationSentValues.last }
	var lastUserDeleted: Bool? { userDeletedValues.last }

	func reset() {
		authSuccessUsers = []
		authFailureErrors = []
		linkSuccessUsers = []
		linkFailureErrors = []
		signOutSuccessValues = []
		passwordResetSentValues = []
		emailVerificationSentValues = []
		userDeletedValues = []
	}

	func emitAuthSuccess(_ user: GodotFirebaseUser) { authSuccessUsers.append(user) }
	func emitAuthFailure(_ error: String) { authFailureErrors.append(error) }
	func emitLinkSuccess(_ user: GodotFirebaseUser) { linkSuccessUsers.append(user) }
	func emitLinkFailure(_ error: String) { linkFailureErrors.append(error) }
	func emitSignOutSuccess(_ success: Bool) { signOutSuccessValues.append(success) }
	func emitPasswordResetSent(_ success: Bool) { passwordResetSentValues.append(success) }
	func emitEmailVerificationSent(_ success: Bool) { emailVerificationSentValues.append(success) }
	func emitUserDeleted(_ success: Bool) { userDeletedValues.append(success) }

	// Firestore signals — no-ops; MockAuthenticationEmitter is used only in
	// auth tests and does not need to capture Firestore signals.
	func emitDocumentWritten(_ document: FirestoreDocument) {}
	func emitDocumentWriteFailed(_ error: FirestoreError) {}
	func emitDocumentUpdated(_ document: FirestoreDocument) {}
	func emitDocumentUpdateFailed(_ error: FirestoreError) {}
	func emitDocumentDeleted(_ document: FirestoreDocument) {}
	func emitDocumentDeleteFailed(_ error: FirestoreError) {}
	func emitDocumentChanged(_ result: FirestoreDocument) {}
	func emitDocumentQueryCompleted(_ result: FirestoreDocument) {}
	func emitDocumentQueryFailed(_ error: FirestoreError) {}
	func emitCollectionQueryCompleted(_ result: FirestoreResult) {}
	func emitCollectionQueryFailed(_ error: FirestoreError) {}
}

// MARK: - MockAuthUser

/// In-memory implementation of AuthUserProviding.
/// All completion handlers are called synchronously with pre-configured results.
final class MockAuthUser: AuthUserProviding {

	var uid: String
	var displayName: String?
	var email: String?
	var photoURL: URL?
	var isEmailVerified: Bool
	var isAnonymous: Bool

	/// Set before the test calls sendVerificationEmail.
	var sendEmailVerificationError: Error?

	/// Set before the test calls deleteCurrentUser.
	var deleteError: Error?

	/// Set before the test exercises a Google linking flow.
	/// nil = link succeeds; non-nil = link fails with this error.
	var linkError: Error?

	init(
		uid: String = "uid-default",
		displayName: String? = "Test User",
		email: String? = "test@example.com",
		photoURL: URL? = nil,
		isEmailVerified: Bool = true,
		isAnonymous: Bool = false
	) {
		self.uid = uid
		self.displayName = displayName
		self.email = email
		self.photoURL = photoURL
		self.isEmailVerified = isEmailVerified
		self.isAnonymous = isAnonymous
	}

	func sendEmailVerification(completion: ((Error?) -> Void)?) {
		completion?(sendEmailVerificationError)
	}

	func delete(completion: ((Error?) -> Void)?) {
		completion?(deleteError)
	}

	/// Called by Authentication.linkWithGoogle(idToken:accessToken:).
	/// Authentication ignores the AuthDataResult and calls getCurrentUser()
	/// immediately after, so we always pass nil for the result object.
	///
	/// onLinkCallback fires before the completion, allowing the owning MockAuth
	/// to update currentUser so that Authentication.getCurrentUser() sees the
	/// correct state (either a valid linked user or nil) when it runs.
	var onLinkCallback: (() -> Void)?

	func link(with credential: AuthCredential, completion: ((AuthDataResult?, Error?) -> Void)?) {
		onLinkCallback?()
		completion?(nil, linkError)
	}
}

// MARK: - MockAuth

/// In-memory implementation of AuthProviding.
/// All async operations invoke their completion synchronously so tests remain
/// single-threaded and need no XCTestExpectation.
final class MockAuth: AuthProviding {

	/// The user returned by currentUser.
	///
	/// For the Google sign-in and link flows, Authentication calls
	/// getCurrentUser() (which reads this property) inside the credential
	/// completion handler.  Tests must therefore set currentUser to the
	/// desired post-sign-in user *before* triggering signInWithGoogle() or
	/// linkAnonymousWithGoogle(), not after.
	var currentUser: AuthUserProviding?

	var createUserError: Error?
	var signInError: Error?
	var signInAnonymouslyError: Error?

	/// When nil, signIn(with:credential:) succeeds (completion called with
	/// nil error).  Authentication then calls getCurrentUser() immediately,
	/// so currentUser must already reflect the post-sign-in state.
	var signInWithCredentialError: Error?

	var signOutError: Error?
	var sendPasswordResetError: Error?

	func createUser(
		withEmail email: String,
		password: String,
		completion: ((AuthDataResult?, Error?) -> Void)?
	) {
		completion?(nil, createUserError)
	}

	func signIn(
		withEmail email: String,
		password: String,
		completion: ((AuthDataResult?, Error?) -> Void)?
	) {
		completion?(nil, signInError)
	}

	func signInAnonymously(completion: ((AuthDataResult?, Error?) -> Void)?) {
		completion?(nil, signInAnonymouslyError)
	}

	func signIn(with credential: AuthCredential, completion: ((AuthDataResult?, Error?) -> Void)?) {
		completion?(nil, signInWithCredentialError)
	}

	func signOut() throws {
		if let error = signOutError { throw error }
	}

	func sendPasswordReset(withEmail email: String, completion: ((Error?) -> Void)?) {
		completion?(sendPasswordResetError)
	}
}

// MARK: - MockGoogleSignIn

/// In-memory implementation of GoogleSignInProviding.
final class MockGoogleSignIn: GoogleSignInProviding {

	/// The token delivered to the completion.  Set to nil to simulate a
	/// missing-ID-token failure.
	var idToken: String? = "mock-id-token"
	var accessToken: String = "mock-access-token"

	/// When non-nil, delivers this error instead of tokens.
	var signInError: Error?

	private(set) var didSignOut = false

	func signIn(
		withPresenting viewController: UIViewController,
		completion: @escaping (_ idToken: String?, _ accessToken: String, _ error: Error?) -> Void
	) {
		if let error = signInError {
			completion(nil, "", error)
		} else {
			completion(idToken, accessToken, nil)
		}
	}

	func signOut() {
		didSignOut = true
	}
}

// MARK: - Fixtures

enum Fixtures {

	// MARK: Users

	static func makeVerifiedUser(
		uid: String = "uid-verified-001",
		email: String = "verified@example.com"
	) -> MockAuthUser {
		MockAuthUser(
			uid: uid,
			displayName: "Verified User",
			email: email,
			photoURL: URL(string: "https://example.com/photo.jpg"),
			isEmailVerified: true,
			isAnonymous: false
		)
	}

	static func makeAnonymousUser(uid: String = "uid-anon-002") -> MockAuthUser {
		MockAuthUser(
			uid: uid,
			displayName: nil,
			email: nil,
			photoURL: nil,
			isEmailVerified: false,
			isAnonymous: true
		)
	}

	static func makeUnverifiedUser(
		uid: String = "uid-unverified-003",
		email: String = "unverified@example.com"
	) -> MockAuthUser {
		MockAuthUser(
			uid: uid,
			displayName: "Unverified User",
			email: email,
			isEmailVerified: false,
			isAnonymous: false
		)
	}

	// MARK: Authentication SUT factory

	/// auth and googleSignIn are typed as protocols so callers can pass any
	/// conforming type — e.g. MockAuthSettingUserOnSignIn — without a cast.
	static func makeAuthentication(
		emitter: MockAuthenticationEmitter = MockAuthenticationEmitter(),
		auth: any AuthProviding = MockAuth(),
		googleSignIn: any GoogleSignInProviding = MockGoogleSignIn(),
		viewController: UIViewController? = UIViewController()
	) -> Authentication {
		Authentication(
			emitter: emitter,
			auth: auth,
			googleSignIn: googleSignIn,
			viewController: viewController
		)
	}

	// MARK: Errors

	static func makeError(_ message: String = "Test error") -> NSError {
		NSError(domain: "com.test.firebase", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
	}
}
