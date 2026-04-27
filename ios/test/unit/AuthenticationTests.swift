//
// © 2026-present Firebase Team https://github.com/firebase-team
//

@testable import firebase_plugin    // adjust to your actual module name
import FirebaseAuth
import XCTest

// MARK: - AuthenticationTests

final class AuthenticationTests: XCTestCase {

	// -----------------------------------------------------------------------
	// MARK: Shared fixtures — recreated before every test
	// -----------------------------------------------------------------------

	private var emitter: MockAuthenticationEmitter!
	private var auth: MockAuth!
	private var googleSignIn: MockGoogleSignIn!
	private var sut: Authentication!

	override func setUp() {
		super.setUp()
		emitter = MockAuthenticationEmitter()
		auth = MockAuth()
		googleSignIn = MockGoogleSignIn()
		sut = Fixtures.makeAuthentication(
			emitter: emitter,
			auth: auth,
			googleSignIn: googleSignIn
		)
	}

	override func tearDown() {
		sut = nil
		auth = nil
		googleSignIn = nil
		emitter = nil
		super.tearDown()
	}

	// -----------------------------------------------------------------------
	// MARK: isSignedIn
	// -----------------------------------------------------------------------

	func test_isSignedIn_returnsTrue_whenCurrentUserIsSet() {
		auth.currentUser = Fixtures.makeVerifiedUser()
		XCTAssertTrue(sut.isSignedIn())
	}

	func test_isSignedIn_returnsFalse_whenNoCurrentUser() {
		auth.currentUser = nil
		XCTAssertFalse(sut.isSignedIn())
	}

	// -----------------------------------------------------------------------
	// MARK: getCurrentUser
	// -----------------------------------------------------------------------

	func test_getCurrentUser_returnsNil_whenNoCurrentUser() {
		auth.currentUser = nil
		XCTAssertNil(sut.getCurrentUser())
	}

	func test_getCurrentUser_mapsAllFieldsCorrectly() {
		let mockUser = Fixtures.makeVerifiedUser(uid: "uid-123", email: "alice@example.com")
		auth.currentUser = mockUser

		let godotUser = sut.getCurrentUser()

		XCTAssertNotNil(godotUser)
		XCTAssertEqual(godotUser?.userId, "uid-123")
		XCTAssertEqual(godotUser?.email, "alice@example.com")
		XCTAssertEqual(godotUser?.name, "Verified User")
		XCTAssertTrue(godotUser?.isEmailVerified ?? false)
		XCTAssertFalse(godotUser?.isAnonymous ?? true)
	}

	func test_getCurrentUser_mapsPhotoUrl_whenPresent() {
		let user = Fixtures.makeVerifiedUser()
		user.photoURL = URL(string: "https://example.com/avatar.png")
		auth.currentUser = user

		XCTAssertEqual(sut.getCurrentUser()?.photoUrl, "https://example.com/avatar.png")
	}

	func test_getCurrentUser_hasEmptyPhotoUrl_whenPhotoUrlIsNil() {
		let user = Fixtures.makeVerifiedUser()
		user.photoURL = nil
		auth.currentUser = user

		XCTAssertEqual(sut.getCurrentUser()?.photoUrl, "")
	}

	func test_getCurrentUser_anonymousUser_hasEmptyNameAndEmail() {
		auth.currentUser = Fixtures.makeAnonymousUser()

		let godotUser = sut.getCurrentUser()

		XCTAssertEqual(godotUser?.name, "")
		XCTAssertEqual(godotUser?.email, "")
		XCTAssertTrue(godotUser?.isAnonymous ?? false)
		XCTAssertFalse(godotUser?.isEmailVerified ?? true)
	}

	// -----------------------------------------------------------------------
	// MARK: createUser
	// -----------------------------------------------------------------------

	func test_createUser_emitsAuthSuccess_onSuccess() {
		auth.currentUser = Fixtures.makeVerifiedUser(uid: "new-uid")

		sut.createUser("new@example.com", password: "password123")

		XCTAssertEqual(emitter.authSuccessUsers.count, 1)
		XCTAssertEqual(emitter.authSuccessUsers.first?.userId, "new-uid")
		XCTAssertTrue(emitter.authFailureErrors.isEmpty)
	}

	func test_createUser_emitsAuthFailure_onFirebaseError() {
		auth.createUserError = Fixtures.makeError("Email already in use")

		sut.createUser("taken@example.com", password: "password123")

		XCTAssertEqual(emitter.authFailureErrors.first, "Email already in use")
		XCTAssertTrue(emitter.authSuccessUsers.isEmpty)
	}

	func test_createUser_emitsAuthFailure_whenUserIsNilAfterSuccess() {
		auth.currentUser = nil   // remains nil after the completion fires

		sut.createUser("ghost@example.com", password: "password123")

		XCTAssertEqual(emitter.authFailureErrors.first, "User creation succeeded but user is null.")
		XCTAssertTrue(emitter.authSuccessUsers.isEmpty)
	}

	// -----------------------------------------------------------------------
	// MARK: signIn (email + password)
	// -----------------------------------------------------------------------

	func test_signIn_emitsAuthSuccess_onSuccess() {
		auth.currentUser = Fixtures.makeVerifiedUser(uid: "signed-in-uid")

		sut.signIn("user@example.com", password: "secret")

		XCTAssertEqual(emitter.authSuccessUsers.count, 1)
		XCTAssertEqual(emitter.authSuccessUsers.first?.userId, "signed-in-uid")
		XCTAssertTrue(emitter.authFailureErrors.isEmpty)
	}

	func test_signIn_emitsAuthFailure_onFirebaseError() {
		auth.signInError = Fixtures.makeError("Wrong password")

		sut.signIn("user@example.com", password: "wrong")

		XCTAssertEqual(emitter.authFailureErrors.first, "Wrong password")
		XCTAssertTrue(emitter.authSuccessUsers.isEmpty)
	}

	func test_signIn_emitsAuthFailure_whenUserIsNilAfterSuccess() {
		auth.currentUser = nil

		sut.signIn("user@example.com", password: "secret")

		XCTAssertEqual(emitter.authFailureErrors.first, "Authentication succeeded but user is null.")
		XCTAssertTrue(emitter.authSuccessUsers.isEmpty)
	}

	// -----------------------------------------------------------------------
	// MARK: signInAnonymously
	// -----------------------------------------------------------------------

	func test_signInAnonymously_emitsAuthSuccess_onSuccess() {
		// currentUser must be nil when signInAnonymously() is called so the
		// "already signed in" guard passes.  MockAuthSettingUserOnSignIn sets
		// currentUser to anonUser *inside* the completion handler — after the
		// guard but before Authentication calls getCurrentUser().
		let anonUser = Fixtures.makeAnonymousUser(uid: "anon-uid")
		let settingAuth = MockAuthSettingUserOnSignIn(userToSet: anonUser)
		let localEmitter = MockAuthenticationEmitter()
		let localSut = Fixtures.makeAuthentication(emitter: localEmitter, auth: settingAuth)

		localSut.signInAnonymously()

		XCTAssertEqual(localEmitter.authSuccessUsers.count, 1)
		XCTAssertEqual(localEmitter.authSuccessUsers.first?.userId, "anon-uid")
		XCTAssertTrue(localEmitter.authFailureErrors.isEmpty)
	}

	func test_signInAnonymously_emitsAuthFailure_whenUserAlreadySignedIn() {
		auth.currentUser = Fixtures.makeVerifiedUser()

		sut.signInAnonymously()

		XCTAssertEqual(emitter.authFailureErrors.first, "User is already signed in.")
		XCTAssertTrue(emitter.authSuccessUsers.isEmpty)
	}

	func test_signInAnonymously_emitsAuthFailure_onFirebaseError() {
		auth.currentUser = nil
		auth.signInAnonymouslyError = Fixtures.makeError("Network error")

		sut.signInAnonymously()

		XCTAssertEqual(emitter.authFailureErrors.first, "Network error")
		XCTAssertTrue(emitter.authSuccessUsers.isEmpty)
	}

	func test_signInAnonymously_emitsAuthFailure_whenUserIsNilAfterSuccess() {
		// currentUser stays nil after completion — triggers the defensive branch
		auth.currentUser = nil
		auth.signInAnonymouslyError = nil

		sut.signInAnonymously()

		XCTAssertEqual(emitter.authFailureErrors.first, "Anonymous sign-in succeeded but user is null.")
		XCTAssertTrue(emitter.authSuccessUsers.isEmpty)
	}

	// -----------------------------------------------------------------------
	// MARK: signInWithGoogle
	//
	// MockGoogleSignIn calls its completion synchronously.
	// MockAuth.signIn(with:credential:) also calls its completion synchronously.
	// Authentication.authWithGoogle then calls getCurrentUser() which reads
	// auth.currentUser — so tests must set currentUser BEFORE calling
	// signInWithGoogle(), not after.
	// -----------------------------------------------------------------------

	func test_signInWithGoogle_emitsAuthSuccess_onSuccess() {
		// Set the user that getCurrentUser() will see after credential sign-in
		auth.currentUser = Fixtures.makeVerifiedUser(uid: "google-uid")
		googleSignIn.idToken = "valid-id-token"

		sut.signInWithGoogle()

		XCTAssertEqual(emitter.authSuccessUsers.count, 1)
		XCTAssertEqual(emitter.authSuccessUsers.first?.userId, "google-uid")
		XCTAssertTrue(emitter.authFailureErrors.isEmpty)
	}

	func test_signInWithGoogle_emitsAuthFailure_whenViewControllerIsNil() {
		let noVCSut = Authentication(
			emitter: emitter,
			auth: auth,
			googleSignIn: googleSignIn,
			viewController: nil
		)

		noVCSut.signInWithGoogle()

		XCTAssertEqual(emitter.authFailureErrors.first, "Google Sign-In not initialized.")
		XCTAssertTrue(emitter.authSuccessUsers.isEmpty)
	}

	func test_signInWithGoogle_emitsAuthFailure_onGoogleSignInError() {
		googleSignIn.signInError = Fixtures.makeError("Google error")

		sut.signInWithGoogle()

		XCTAssertEqual(emitter.authFailureErrors.first, "Google error")
		XCTAssertTrue(emitter.authSuccessUsers.isEmpty)
	}

	func test_signInWithGoogle_emitsAuthFailure_whenIdTokenIsNil() {
		googleSignIn.idToken = nil

		sut.signInWithGoogle()

		XCTAssertEqual(emitter.authFailureErrors.first, "Google Sign-In: missing ID token.")
		XCTAssertTrue(emitter.authSuccessUsers.isEmpty)
	}

	func test_signInWithGoogle_emitsAuthFailure_onCredentialSignInError() {
		googleSignIn.idToken = "valid-id-token"
		auth.signInWithCredentialError = Fixtures.makeError("Credential rejected")

		sut.signInWithGoogle()

		XCTAssertEqual(emitter.authFailureErrors.first, "Credential rejected")
		XCTAssertTrue(emitter.authSuccessUsers.isEmpty)
	}

	func test_signInWithGoogle_emitsAuthFailure_whenUserIsNilAfterCredentialSignIn() {
		googleSignIn.idToken = "valid-id-token"
		auth.signInWithCredentialError = nil
		auth.currentUser = nil   // no user available after credential sign-in

		sut.signInWithGoogle()

		XCTAssertEqual(
			emitter.authFailureErrors.first,
			"Authentication with Google succeeded but user is null."
		)
		XCTAssertTrue(emitter.authSuccessUsers.isEmpty)
	}

	// -----------------------------------------------------------------------
	// MARK: linkAnonymousWithGoogle
	//
	// The link flow is:
	//   linkAnonymousWithGoogle()
	//     → presentGoogleSignInForLinking()          (MockGoogleSignIn fires sync)
	//     → linkWithGoogle(idToken:accessToken:)
	//     → auth.currentUser.link(with:completion:)  (MockAuthUser.link fires sync)
	//     → getCurrentUser()                         (reads auth.currentUser)
	//
	// Tests therefore set auth.currentUser to the anonymous MockAuthUser, and
	// set anonUser.linkError to control success/failure of the link step.
	// -----------------------------------------------------------------------

	func test_linkAnonymousWithGoogle_emitsLinkFailure_whenNoUserSignedIn() {
		auth.currentUser = nil

		sut.linkAnonymousWithGoogle()

		XCTAssertEqual(emitter.linkFailureErrors.first, "No user signed in.")
		XCTAssertTrue(emitter.linkSuccessUsers.isEmpty)
	}

	func test_linkAnonymousWithGoogle_emitsLinkFailure_whenUserIsNotAnonymous() {
		auth.currentUser = Fixtures.makeVerifiedUser()   // isAnonymous = false

		sut.linkAnonymousWithGoogle()

		XCTAssertEqual(emitter.linkFailureErrors.first, "Current user is not anonymous.")
		XCTAssertTrue(emitter.linkSuccessUsers.isEmpty)
	}

	func test_linkAnonymousWithGoogle_emitsLinkSuccess_onSuccess() {
		// Arrange: an anonymous user whose link() mutates auth.currentUser to a
		// verified user before calling completion, so that getCurrentUser() returns
		// a valid GodotFirebaseUser and linkSuccess is emitted.
		let linkingAuth = MockAuth()
		let verifiedUser = Fixtures.makeVerifiedUser(uid: "anon-link-uid")
		let anonUser = Fixtures.makeAnonymousUser(uid: "anon-link-uid")
		anonUser.linkError = nil
		// When link fires, swap to the verified user so getCurrentUser() succeeds.
		anonUser.onLinkCallback = { linkingAuth.currentUser = verifiedUser }
		linkingAuth.currentUser = anonUser
		googleSignIn.idToken = "valid-token"

		let localEmitter = MockAuthenticationEmitter()
		let localSut = Authentication(
			emitter: localEmitter,
			auth: linkingAuth,
			googleSignIn: googleSignIn,
			viewController: UIViewController()
		)

		localSut.linkAnonymousWithGoogle()

		XCTAssertEqual(localEmitter.linkSuccessUsers.count, 1)
		XCTAssertTrue(localEmitter.linkFailureErrors.isEmpty)
	}

	func test_linkAnonymousWithGoogle_emitsLinkFailure_onGoogleSignInError() {
		auth.currentUser = Fixtures.makeAnonymousUser()
		googleSignIn.signInError = Fixtures.makeError("Google link error")

		sut.linkAnonymousWithGoogle()

		XCTAssertEqual(emitter.linkFailureErrors.first, "Google link error")
		XCTAssertTrue(emitter.linkSuccessUsers.isEmpty)
	}

	func test_linkAnonymousWithGoogle_emitsLinkFailure_whenIdTokenIsNil() {
		auth.currentUser = Fixtures.makeAnonymousUser()
		googleSignIn.idToken = nil

		sut.linkAnonymousWithGoogle()

		XCTAssertEqual(emitter.linkFailureErrors.first, "Google Sign-In: missing ID token.")
		XCTAssertTrue(emitter.linkSuccessUsers.isEmpty)
	}

	func test_linkAnonymousWithGoogle_emitsLinkFailure_onLinkCredentialError() {
		let anonUser = Fixtures.makeAnonymousUser()
		anonUser.linkError = Fixtures.makeError("Link credential rejected")
		auth.currentUser = anonUser
		googleSignIn.idToken = "valid-token"

		sut.linkAnonymousWithGoogle()

		XCTAssertEqual(emitter.linkFailureErrors.first, "Link credential rejected")
		XCTAssertTrue(emitter.linkSuccessUsers.isEmpty)
	}

	func test_linkAnonymousWithGoogle_emitsLinkFailure_whenViewControllerIsNil() {
		auth.currentUser = Fixtures.makeAnonymousUser()
		let noVCSut = Authentication(
			emitter: emitter,
			auth: auth,
			googleSignIn: googleSignIn,
			viewController: nil
		)

		noVCSut.linkAnonymousWithGoogle()

		XCTAssertEqual(emitter.linkFailureErrors.first, "Google Sign-In not initialized.")
		XCTAssertTrue(emitter.linkSuccessUsers.isEmpty)
	}

	func test_linkAnonymousWithGoogle_emitsLinkFailure_whenUserIsNilAfterLinkSucceeds() {
		// link() succeeds but currentUser becomes nil immediately after, so
		// getCurrentUser() returns nil and triggers "Link succeeded but user is null."
		// MockAuthUser.onLinkCallback clears the auth's currentUser before the
		// completion fires, so Authentication sees nil when it calls getCurrentUser().
		let nullAuth = MockAuth()
		let anonUser = Fixtures.makeAnonymousUser()
		anonUser.linkError = nil
		anonUser.onLinkCallback = { nullAuth.currentUser = nil }
		nullAuth.currentUser = anonUser
		googleSignIn.idToken = "valid-token"

		let localEmitter = MockAuthenticationEmitter()
		let localSut = Authentication(
			emitter: localEmitter,
			auth: nullAuth,
			googleSignIn: googleSignIn,
			viewController: UIViewController()
		)

		localSut.linkAnonymousWithGoogle()

		XCTAssertEqual(localEmitter.linkFailureErrors.first, "Link succeeded but user is null.")
		XCTAssertTrue(localEmitter.linkSuccessUsers.isEmpty)
	}

	// -----------------------------------------------------------------------
	// MARK: signOut
	// -----------------------------------------------------------------------

	func test_signOut_emitsSignOutSuccess_true_onSuccess() {
		sut.signOut()

		XCTAssertEqual(emitter.signOutSuccessValues.first, true)
		XCTAssertTrue(googleSignIn.didSignOut)
		XCTAssertTrue(emitter.authFailureErrors.isEmpty)
	}

	func test_signOut_emitsSignOutSuccess_false_andAuthFailure_onError() {
		auth.signOutError = Fixtures.makeError("Sign-out failed")

		sut.signOut()

		XCTAssertEqual(emitter.signOutSuccessValues.first, false)
		XCTAssertFalse(googleSignIn.didSignOut)
		XCTAssertTrue(emitter.authFailureErrors.first?.hasPrefix("Failed to sign out:") ?? false)
	}

	// -----------------------------------------------------------------------
	// MARK: sendVerificationEmail
	// -----------------------------------------------------------------------

	func test_sendVerificationEmail_emitsTrue_onSuccess() {
		let user = Fixtures.makeUnverifiedUser()
		auth.currentUser = user

		sut.sendVerificationEmail()

		XCTAssertEqual(emitter.emailVerificationSentValues.first, true)
		XCTAssertTrue(emitter.authFailureErrors.isEmpty)
	}

	func test_sendVerificationEmail_emitsFalseAndAuthFailure_onError() {
		let user = Fixtures.makeUnverifiedUser()
		user.sendEmailVerificationError = Fixtures.makeError("Rate limit exceeded")
		auth.currentUser = user

		sut.sendVerificationEmail()

		XCTAssertEqual(emitter.emailVerificationSentValues.first, false)
		XCTAssertTrue(
			emitter.authFailureErrors.first?.hasPrefix("Failed to send verification email:") ?? false
		)
	}

	func test_sendVerificationEmail_isNoOp_whenNoUserSignedIn() {
		auth.currentUser = nil

		sut.sendVerificationEmail()

		XCTAssertTrue(emitter.emailVerificationSentValues.isEmpty)
		XCTAssertTrue(emitter.authFailureErrors.isEmpty)
	}

	// -----------------------------------------------------------------------
	// MARK: sendPasswordResetEmail
	// -----------------------------------------------------------------------

	func test_sendPasswordResetEmail_emitsTrue_onSuccess() {
		sut.sendPasswordResetEmail("user@example.com")

		XCTAssertEqual(emitter.passwordResetSentValues.first, true)
		XCTAssertTrue(emitter.authFailureErrors.isEmpty)
	}

	func test_sendPasswordResetEmail_emitsFalseAndAuthFailure_onError() {
		auth.sendPasswordResetError = Fixtures.makeError("Invalid email")

		sut.sendPasswordResetEmail("bad@example.com")

		XCTAssertEqual(emitter.passwordResetSentValues.first, false)
		XCTAssertTrue(
			emitter.authFailureErrors.first?.hasPrefix("Failed to send password reset email:") ?? false
		)
	}

	// -----------------------------------------------------------------------
	// MARK: deleteCurrentUser
	// -----------------------------------------------------------------------

	func test_deleteCurrentUser_emitsUserDeletedTrue_onSuccess() {
		auth.currentUser = Fixtures.makeVerifiedUser()

		sut.deleteCurrentUser()

		XCTAssertEqual(emitter.userDeletedValues.first, true)
		XCTAssertTrue(emitter.authFailureErrors.isEmpty)
	}

	func test_deleteCurrentUser_emitsUserDeletedFalseAndAuthFailure_onError() {
		let user = Fixtures.makeVerifiedUser()
		user.deleteError = Fixtures.makeError("Requires recent login")
		auth.currentUser = user

		sut.deleteCurrentUser()

		XCTAssertEqual(emitter.userDeletedValues.first, false)
		XCTAssertTrue(emitter.authFailureErrors.first?.hasPrefix("Delete failed:") ?? false)
	}

	func test_deleteCurrentUser_isNoOp_whenNoUserSignedIn() {
		auth.currentUser = nil

		sut.deleteCurrentUser()

		XCTAssertTrue(emitter.userDeletedValues.isEmpty)
		XCTAssertTrue(emitter.authFailureErrors.isEmpty)
	}
}

// MARK: - MockAuthSettingUserOnSignIn

/// MockAuth that sets currentUser to a given user *inside* signInAnonymously's
/// completion handler, after the "already signed in" guard has passed (which
/// sees currentUser == nil) but before Authentication reads currentUser in
/// getCurrentUser().  This is the only correct way to test the success path
/// because Authentication's guard and getCurrentUser() both read currentUser,
/// which must be nil then non-nil in that exact order.
private final class MockAuthSettingUserOnSignIn: AuthProviding {

	private let userToSet: AuthUserProviding
	var currentUser: AuthUserProviding?

	init(userToSet: AuthUserProviding) {
		self.userToSet = userToSet
	}

	func signInAnonymously(completion: ((AuthDataResult?, Error?) -> Void)?) {
		currentUser = userToSet   // set before completion so getCurrentUser() sees it
		completion?(nil, nil)
	}

	func createUser(
		withEmail: String, password: String,
		completion: ((AuthDataResult?, Error?) -> Void)?
	) { completion?(nil, nil) }

	func signIn(
		withEmail: String, password: String,
		completion: ((AuthDataResult?, Error?) -> Void)?
	) { completion?(nil, nil) }

	func signIn(with: AuthCredential,
				completion: ((AuthDataResult?, Error?) -> Void)?) { completion?(nil, nil) }

	func signOut() throws {}

	func sendPasswordReset(
		withEmail: String, completion: ((Error?) -> Void)?
	) { completion?(nil) }
}
