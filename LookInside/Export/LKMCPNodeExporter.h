//
//  LKMCPNodeExporter.h
//  Lookin
//
//  Exports a LookinDisplayItem (and optionally its whole subtree) into the same
//  JSON shape the `lookinside-mcp` tools emit (see Sources/LookinMCPCore/JSONShape.swift:
//  oid / className / role / frame / bounds / alpha / hidden / text /
//  accessibilityIdentifier / accessibilityLabel / path / children), enriched with the
//  full per-node `attributes` groups exactly as the GUI dashboard panel shows them.
//
//  The macOS client does NOT link the Swift MCP target, so this is a faithful ObjC
//  re-implementation of the same schema. Keep the field names in sync with JSONShape.Node.
//

#import <Foundation/Foundation.h>

@class LookinDisplayItem;

NS_ASSUME_NONNULL_BEGIN

@interface LKMCPNodeExporter : NSObject

/// Build the MCP-format dictionary for `item`. When `recursive` is YES the returned
/// dictionary's `children` key holds the full subtree; when NO, `children` is an empty array.
+ (NSDictionary *)mcpDictionaryForItem:(LookinDisplayItem *)item recursive:(BOOL)recursive;

/// Pretty-printed UTF-8 JSON data for `mcpDictionaryForItem:recursive:`.
+ (nullable NSData *)jsonDataForItem:(LookinDisplayItem *)item
                            recursive:(BOOL)recursive
                                error:(NSError *_Nullable *_Nullable)error;

/// A suggested file name (without directory) for the exported JSON, e.g.
/// `UILabel_140234_analysis.json` or `UIView_140234_analysis_tree.json`.
+ (NSString *)suggestedFileNameForItem:(LookinDisplayItem *)item recursive:(BOOL)recursive;

/// Human-readable text of the node's dashboard attribute data (grouped, "Title: value"),
/// suitable for placing on the pasteboard. Mirrors what the GUI panel displays.
+ (NSString *)readableAttributesTextForItem:(LookinDisplayItem *)item;

@end

NS_ASSUME_NONNULL_END
