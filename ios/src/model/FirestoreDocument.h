//
// © 2026-present Firebase Team https://github.com/firebase-team
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FirestoreDocument : NSObject

/// Designated initialiser — builds the model from raw field values.
- (instancetype)initWithCollection:(NSString *)collection
						documentId:(NSString *)documentId
					  documentData:(nullable void *)documentData NS_DESIGNATED_INITIALIZER;

- (instancetype)init;

@property(nonatomic, copy) NSString *collection;
@property(nonatomic, copy) NSString *documentId;

/// Returns the document data as a Godot Dictionary pointer.
- (void *)documentData;
- (void)setDocumentData:(void *)documentData;

/// Returns the backing Dictionary.
- (void *)getRawData;

// -------------------------------------------------------------------------
// Swift / Firebase interop
// -------------------------------------------------------------------------

/// Returns the document_data field as a typed NSDictionary suitable for
/// passing directly to the Firebase SDK.  Godot Variant types are mapped:
///   String      → NSString
///   int         → NSNumber (longLong)
///   float       → NSNumber (double)
///   bool        → NSNumber (BOOL)
///   Dictionary  → NSDictionary<NSString *, id> (recursive)
///   Array       → NSArray                      (recursive)
///   nil / other → NSNull
///
/// The typed key forces Swift to infer [String : Any] rather than
/// [AnyHashable : Any], satisfying the Firebase SDK call-sites.
- (NSDictionary<NSString *, id> *)documentDataAsDictionary;

/// Populates the document_data field from a typed NSDictionary returned by
/// the Firebase SDK, performing the inverse type mapping.
///
/// Named `populateDocumentData:` (not `…FromDictionary:`) to avoid the
/// Swift 3 renaming rule that rewrites `setFoo:fromDictionary:` selectors.
- (void)populateDocumentData:(NSDictionary<NSString *, id> *)dictionary;

@end

NS_ASSUME_NONNULL_END
