//
// © 2026-present Firebase Team https://github.com/firebase-team
//

import FirebaseAuth
import Foundation
import GoogleSignIn
import UIKit

// MARK: - AuthUserProviding

/// Abstracts the subset of FirebaseAuth.User that Authentication.swift reads.
///
/// A retroactive conformance extension on FirebaseAuth.User cannot be used here
/// because the SDK's @objc-bridged sendEmailVerification(completion:),
/// delete(completion:), and link(with:completion:) signatures do not match the
/// pure-Swift protocol requirements exactly, causing a compiler error.
/// FirebaseUserWrapper (below) is the production adapter; tests substitute
/// MockAuthUser directly.
public protocol AuthUserProviding: AnyObject {
	var uid: String { get }
	var displayName: String? { get }
	var email: String? { get }
	var photoURL: URL? { get }
	var isEmailVerified: Bool { get }
	var isAnonymous: Bool { get }
	func sendEmailVerification(completion: ((Error?) -> Void)?)
	func delete(completion: ((Error?) -> Void)?)
	func link(with credential: AuthCredential, completion: ((AuthDataResult?, Error?) -> Void)?)
}

// MARK: FirebaseUserWrapper

/// Production adapter that wraps the concrete FirebaseAuth.User and satisfies
/// AuthUserProviding by forwarding every call explicitly.  This sidesteps the
/// ObjC-bridging signature mismatch that prevents a direct retroactive
/// extension conformance.
public final class FirebaseUserWrapper: AuthUserProviding {

	private let user: FirebaseAuth.User

	public init(_ user: FirebaseAuth.User) {
		self.user = user
	}

	public var uid: String { user.uid }
	public var displayName: String? { user.displayName }
	public var email: String? { user.email }
	public var photoURL: URL? { user.photoURL }
	public var isEmailVerified: Bool { user.isEmailVerified }
	public var isAnonymous: Bool { user.isAnonymous }

	public func sendEmailVerification(completion: ((Error?) -> Void)?) {
		user.sendEmailVerification(completion: completion)
	}

	public func delete(completion: ((Error?) -> Void)?) {
		user.delete(completion: completion)
	}

	public func link(
		with credential: AuthCredential,
		completion: ((AuthDataResult?, Error?) -> Void)?
	) {
		user.link(with: credential, completion: completion)
	}
}

// MARK: - AuthProviding

/// Abstracts the subset of FirebaseAuth.Auth that Authentication.swift calls.
/// Production code uses FirebaseAuthWrapper (below); tests substitute MockAuth.
public protocol AuthProviding: AnyObject {
	/// The currently signed-in user, or nil if no user is signed in.
	var currentUser: AuthUserProviding? { get }

	func createUser(
		withEmail email: String,
		password: String,
		completion: ((AuthDataResult?, Error?) -> Void)?
	)

	func signIn(
		withEmail email: String,
		password: String,
		completion: ((AuthDataResult?, Error?) -> Void)?
	)

	func signInAnonymously(completion: ((AuthDataResult?, Error?) -> Void)?)

	func signIn(with credential: AuthCredential, completion: ((AuthDataResult?, Error?) -> Void)?)

	/// Throws if sign-out fails.
	func signOut() throws

	func sendPasswordReset(withEmail email: String, completion: ((Error?) -> Void)?)
}

// MARK: FirebaseAuthWrapper

/// Production wrapper that satisfies AuthProviding by delegating to the real
/// FirebaseAuth.Auth singleton.  currentUser wraps the raw FirebaseAuth.User
/// in FirebaseUserWrapper so the return type satisfies AuthUserProviding.
public final class FirebaseAuthWrapper: AuthProviding {

	private let auth: FirebaseAuth.Auth

	public init(_ auth: FirebaseAuth.Auth = FirebaseAuth.Auth.auth()) {
		self.auth = auth
	}

	public var currentUser: AuthUserProviding? {
		auth.currentUser.map { FirebaseUserWrapper($0) }
	}

	public func createUser(
		withEmail email: String,
		password: String,
		completion: ((AuthDataResult?, Error?) -> Void)?
	) {
		auth.createUser(withEmail: email, password: password, completion: completion)
	}

	public func signIn(
		withEmail email: String,
		password: String,
		completion: ((AuthDataResult?, Error?) -> Void)?
	) {
		auth.signIn(withEmail: email, password: password, completion: completion)
	}

	public func signInAnonymously(completion: ((AuthDataResult?, Error?) -> Void)?) {
		auth.signInAnonymously(completion: completion)
	}

	public func signIn(
		with credential: AuthCredential,
		completion: ((AuthDataResult?, Error?) -> Void)?
	) {
		auth.signIn(with: credential, completion: completion)
	}

	public func signOut() throws {
		try auth.signOut()
	}

	public func sendPasswordReset(withEmail email: String, completion: ((Error?) -> Void)?) {
		auth.sendPasswordReset(withEmail: email, completion: completion)
	}
}

// MARK: - GoogleSignInProviding

/// Abstracts the Google Sign-In flow, extracting only the two token strings
/// that Authentication.swift actually needs.  This means mock implementations
/// never need to construct or subclass the sealed GIDSignInResult type.
public protocol GoogleSignInProviding: AnyObject {
	/// Presents the Google Sign-In modal and delivers the resolved idToken and
	/// accessToken strings (or an error) to the completion handler.
	func signIn(
		withPresenting viewController: UIViewController,
		completion: @escaping (_ idToken: String?, _ accessToken: String, _ error: Error?) -> Void
	)
	func signOut()
}

// MARK: GIDSignInWrapper

/// Production wrapper that calls the real GIDSignIn singleton and extracts the
/// token strings before forwarding to the GoogleSignInProviding completion.
public final class GIDSignInWrapper: GoogleSignInProviding {

	private let signIn: GIDSignIn

	public init(_ signIn: GIDSignIn = GIDSignIn.sharedInstance) {
		self.signIn = signIn
	}

	public func signIn(
		withPresenting viewController: UIViewController,
		completion: @escaping (_ idToken: String?, _ accessToken: String, _ error: Error?) -> Void
	) {
		signIn.signIn(withPresenting: viewController) { result, error in
			if let error {
				completion(nil, "", error)
				return
			}
			let idToken = result?.user.idToken?.tokenString
			let accessToken = result?.user.accessToken.tokenString ?? ""
			completion(idToken, accessToken, nil)
		}
	}

	public func signOut() {
		signIn.signOut()
	}
}
