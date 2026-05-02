//
// © 2026-present Firebase Team https://github.com/firebase-team
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FirestoreResult : NSObject

- (instancetype)initWithCollection:(NSString *)collection
                         documents:(nullable void *)documents NS_DESIGNATED_INITIALIZER;

- (instancetype)init;

@property(nonatomic, copy) NSString *collection;

/// Returns the documents field as a Godot Dictionary pointer.
- (void *)documents;
- (void)setDocuments:(void *)documents;

/// Returns the backing Dictionary.
- (void *)getRawData;

// -------------------------------------------------------------------------
// Swift / Firebase interop
// -------------------------------------------------------------------------

/// Populates the documents field from a typed NSDictionary keyed by Firestore
/// document ID (value type: NSDictionary<NSString *, id>).
///
/// Named `populateDocuments:` (not `…FromDictionary:`) to avoid the Swift 3
/// renaming rule that rewrites `setFoo:fromDictionary:` selectors.
- (void)populateDocuments:(NSDictionary<NSString *, id> *)dictionary;

@end

NS_ASSUME_NONNULL_END
