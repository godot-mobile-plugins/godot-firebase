//
// © 2026-present Firebase Team https://github.com/firebase-team
//

#import "FirestoreDocument.h"

#include "core/object/class_db.h"
#include "core/variant/array.h"

// ---------------------------------------------------------------------------
// Data key constants
// ---------------------------------------------------------------------------

static const String GFBCollectionProperty = "collection";
static const String GFBDocumentIdProperty = "document_id";
static const String GFBDocumentDataProperty = "document_data";

// ---------------------------------------------------------------------------
// Variant ↔ NSObject conversion helpers (file-scope only)
// ---------------------------------------------------------------------------

/// Recursively converts a Godot Variant to an NSObject compatible with
/// NSDictionary / Firebase SDK.
static id VariantToNSObject(const Variant &v) {
	switch (v.get_type()) {
		case Variant::STRING:
			return [NSString stringWithUTF8String:((String)v).utf8().get_data()];

		case Variant::INT:
			return [NSNumber numberWithLongLong:(int64_t)v];

		case Variant::FLOAT:
			return [NSNumber numberWithDouble:(double)v];

		case Variant::BOOL:
			return [NSNumber numberWithBool:(bool)v];

		case Variant::DICTIONARY: {
			Dictionary dict = v;
			Array keys = dict.keys();
			NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:keys.size()];
			for (int i = 0; i < keys.size(); i++) {
				NSString *key = [NSString stringWithUTF8String:((String)keys[i]).utf8().get_data()];
				result[key] = VariantToNSObject(dict[keys[i]]);
			}
			return result;
		}

		case Variant::ARRAY: {
			Array arr = v;
			NSMutableArray *result = [NSMutableArray arrayWithCapacity:arr.size()];
			for (int i = 0; i < arr.size(); i++) {
				[result addObject:VariantToNSObject(arr[i])];
			}
			return result;
		}

		default:
			return [NSNull null];
	}
}

/// Recursively converts an NSObject (NSDictionary, NSArray, NSString, NSNumber)
/// to a Godot Variant.
static Variant NSObjectToVariant(id obj) {
	if (!obj || obj == [NSNull null]) {
		return Variant();
	}

	if ([obj isKindOfClass:[NSString class]]) {
		return String([(NSString *)obj UTF8String]);
	}

	if ([obj isKindOfClass:[NSNumber class]]) {
		NSNumber *n = (NSNumber *)obj;
		// BOOL is encoded as 'c' (char) on Apple platforms.
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
		NSDictionary *nsDict = (NSDictionary *)obj;
		for (NSString *key in nsDict) {
			dict[String([key UTF8String])] = NSObjectToVariant(nsDict[key]);
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

@interface FirestoreDocument ()
@property(nonatomic, assign) Dictionary data;
@end

@implementation FirestoreDocument

- (instancetype)initWithCollection:(NSString *)collection
						documentId:(NSString *)documentId
					  documentData:(nullable void *)documentData {
	self = [super init];
	if (self) {
		_data = Dictionary();
		self.collection = collection;
		self.documentId = documentId;
		if (documentData != nullptr) {
			_data[GFBDocumentDataProperty] = *(Dictionary *)documentData;
		}
	}
	return self;
}

- (instancetype)initWithDictionary:(Dictionary)dictionary {
	// Route through the designated initialiser so the object is fully
	// initialised before we overwrite _data directly.
	self = [self initWithCollection:@"" documentId:@"" documentData:nullptr];
	if (self) {
		_data = dictionary;
	}
	return self;
}

- (instancetype)init {
	return [self initWithCollection:@"" documentId:@"" documentData:nullptr];
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

- (NSString *)documentId {
	return _data.has(GFBDocumentIdProperty)
			? [NSString stringWithUTF8String:((String)_data[GFBDocumentIdProperty]).utf8().get_data()]
			: @"";
}

- (void)setDocumentId:(NSString *)documentId {
	if (documentId != nil) {
		_data[GFBDocumentIdProperty] = String([documentId UTF8String]);
	}
}

- (void *)documentData {
	if (!_data.has(GFBDocumentDataProperty)) {
		_data[GFBDocumentDataProperty] = Dictionary();
	}
	return (void *)&_data[GFBDocumentDataProperty];
}

- (void)setDocumentData:(void *)documentData {
	if (documentData != nullptr) {
		_data[GFBDocumentDataProperty] = *(Dictionary *)documentData;
	}
}

- (void *)getRawData {
	return (void *)&_data;
}

// ---------------------------------------------------------------------------
// Swift / Firebase interop
// ---------------------------------------------------------------------------

- (NSDictionary<NSString *, id> *)documentDataAsDictionary {
	if (!_data.has(GFBDocumentDataProperty)) {
		return @{};
	}
	id result = VariantToNSObject(_data[GFBDocumentDataProperty]);
	return [result isKindOfClass:[NSDictionary class]] ? result : @{};
}

- (void)populateDocumentData:(NSDictionary<NSString *, id> *)dictionary {
	if (dictionary != nil) {
		_data[GFBDocumentDataProperty] = NSObjectToVariant(dictionary);
	}
}

@end
