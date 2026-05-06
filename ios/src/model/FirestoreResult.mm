//
// © 2026-present Firebase Team https://github.com/firebase-team
//

#import "FirestoreResult.h"

#include "core/object/class_db.h"
#include "core/variant/array.h"

// ---------------------------------------------------------------------------
// Data key constants
// ---------------------------------------------------------------------------

static const String GFBCollectionProperty = "collection";
static const String GFBDocumentsProperty = "documents";

// ---------------------------------------------------------------------------
// Variant ← NSObject conversion (file-scope only)
// FirestoreResult is write-only from Swift — we only need NSObject → Variant.
// Keep in sync with FirestoreDocument.mm.
// ---------------------------------------------------------------------------

static Variant NSObjectToVariant(id obj) {
	if (!obj || obj == [NSNull null]) {
		return Variant();
	}

	if ([obj isKindOfClass:[NSString class]]) {
		return String([(NSString *)obj UTF8String]);
	}

	if ([obj isKindOfClass:[NSNumber class]]) {
		NSNumber *n = (NSNumber *)obj;
		if (strcmp([n objCType], @encode(BOOL)) == 0) {
			return (bool)[n boolValue];
		}
		if (strcmp([n objCType], @encode(double)) == 0 || strcmp([n objCType], @encode(float)) == 0) {
			return (double)[n doubleValue];
		}
		return (int64_t)[n longLongValue];
	}

	if ([obj isKindOfClass:[NSDictionary class]]) {
		Dictionary dict;
		for (NSString *key in (NSDictionary *)obj) {
			dict[String([key UTF8String])] = NSObjectToVariant([(NSDictionary *)obj objectForKey:key]);
		}
		return dict;
	}

	if ([obj isKindOfClass:[NSArray class]]) {
		Array arr;
		for (id item in (NSArray *)obj) {
			arr.append(NSObjectToVariant(item));
		}
		return arr;
	}

	return Variant();
}

// ---------------------------------------------------------------------------

@interface FirestoreResult ()
@property(nonatomic, assign) Dictionary data;
@end

@implementation FirestoreResult

- (instancetype)initWithCollection:(NSString *)collection documents:(nullable void *)documents {
	self = [super init];
	if (self) {
		_data = Dictionary();
		self.collection = collection;
		if (documents != nullptr) {
			_data[GFBDocumentsProperty] = *(Dictionary *)documents;
		}
	}
	return self;
}

- (instancetype)init {
	return [self initWithCollection:@"" documents:nullptr];
}

// ---------------------------------------------------------------------------
// Properties
// ---------------------------------------------------------------------------

- (NSString *)collection {
	return _data.has(GFBCollectionProperty)
			? [NSString stringWithUTF8String:((String)_data[GFBCollectionProperty]).utf8().get_data()]
			: @"";
}

- (void)setCollection:(NSString *)collection {
	if (collection != nil) {
		_data[GFBCollectionProperty] = String([collection UTF8String]);
	}
}

- (void *)documents {
	if (!_data.has(GFBDocumentsProperty)) {
		_data[GFBDocumentsProperty] = Dictionary();
	}
	return (void *)&_data[GFBDocumentsProperty];
}

- (void)setDocuments:(void *)documents {
	if (documents != nullptr) {
		_data[GFBDocumentsProperty] = *(Dictionary *)documents;
	}
}

- (void *)getRawData {
	return (void *)&_data;
}

// ---------------------------------------------------------------------------
// Swift / Firebase interop
// ---------------------------------------------------------------------------

- (void)populateDocuments:(NSDictionary<NSString *, id> *)dictionary {
	if (dictionary != nil) {
		_data[GFBDocumentsProperty] = NSObjectToVariant(dictionary);
	}
}

@end
