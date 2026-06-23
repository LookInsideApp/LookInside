//
//  LKMCPNodeExporter.m
//  Lookin
//

#import "LKMCPNodeExporter.h"
#import <Cocoa/Cocoa.h>
#import "LookinDisplayItem.h"
#import "LookinDisplayItem+LookinClient.h"
#import "LookinObject.h"
#import "LookinAttributesGroup.h"
#import "LookinAttributesGroup+LookinClient.h"
#import "LookinAttributesSection.h"
#import "LookinAttribute.h"
#import "LookinAttrType.h"
#import "LookinDashboardBlueprint.h"

@implementation LKMCPNodeExporter

#pragma mark - Public

+ (NSDictionary *)mcpDictionaryForItem:(LookinDisplayItem *)item recursive:(BOOL)recursive {
    if (!item) {
        return @{};
    }
    return [self _nodeDictForItem:item recursive:recursive];
}

+ (NSData *)jsonDataForItem:(LookinDisplayItem *)item recursive:(BOOL)recursive error:(NSError **)error {
    NSDictionary *dict = [self mcpDictionaryForItem:item recursive:recursive];
    if (![NSJSONSerialization isValidJSONObject:dict]) {
        if (error) {
            *error = [NSError errorWithDomain:@"LKMCPNodeExporter"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Generated object is not valid JSON."}];
        }
        return nil;
    }
    return [NSJSONSerialization dataWithJSONObject:dict
                                           options:(NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys)
                                             error:error];
}

+ (NSString *)suggestedFileNameForItem:(LookinDisplayItem *)item recursive:(BOOL)recursive {
    NSString *className = [self _classNameForItem:item] ?: @"Node";
    // Keep only filename-safe characters.
    NSCharacterSet *illegal = [NSCharacterSet characterSetWithCharactersInString:@"/\\:*?\"<>|"];
    className = [[className componentsSeparatedByCharactersInSet:illegal] componentsJoinedByString:@"_"];
    unsigned long oid = [self _oidForItem:item];
    NSString *suffix = recursive ? @"analysis_tree" : @"analysis";
    if (oid) {
        return [NSString stringWithFormat:@"%@_%lu_%@.json", className, oid, suffix];
    }
    return [NSString stringWithFormat:@"%@_%@.json", className, suffix];
}

+ (NSString *)readableAttributesTextForItem:(LookinDisplayItem *)item {
    if (!item) {
        return @"";
    }
    NSMutableString *text = [NSMutableString string];

    NSString *className = [self _classNameForItem:item] ?: @"";
    unsigned long oid = [self _oidForItem:item];
    if (oid) {
        [text appendFormat:@"%@  (oid: %lu)\n", className, oid];
    } else {
        [text appendFormat:@"%@\n", className];
    }
    NSString *path = [self _breadcrumbForItem:item];
    if (path.length) {
        [text appendFormat:@"path: %@\n", path];
    }

    NSArray<LookinAttributesGroup *> *groups = [item queryAllAttrGroupList];
    for (LookinAttributesGroup *group in groups) {
        NSString *groupTitle = [self _titleForGroup:group];
        [text appendFormat:@"\n[%@]\n", groupTitle.length ? groupTitle : @"-"];

        for (LookinAttributesSection *section in group.attrSections) {
            NSString *sectionTitle = [self _titleForSection:section];
            if (sectionTitle.length) {
                [text appendFormat:@"  %@\n", sectionTitle];
            }
            for (LookinAttribute *attr in section.attributes) {
                NSString *attrTitle = [self _titleForAttribute:attr];
                NSString *valueString = [self _readableStringForAttribute:attr];
                NSString *indent = sectionTitle.length ? @"    " : @"  ";
                if (attrTitle.length) {
                    [text appendFormat:@"%@%@: %@\n", indent, attrTitle, valueString];
                } else {
                    [text appendFormat:@"%@%@\n", indent, valueString];
                }
            }
        }
    }
    return text.copy;
}

#pragma mark - Node assembly (MCP JSONShape.Node parity)

+ (NSDictionary *)_nodeDictForItem:(LookinDisplayItem *)item recursive:(BOOL)recursive {
    NSMutableDictionary *node = [NSMutableDictionary dictionary];

    node[@"oid"] = @([self _oidForItem:item]);
    NSString *className = [self _classNameForItem:item] ?: @"UnknownView";
    node[@"className"] = className;
    NSString *role = [self _roleForClassName:className];
    node[@"role"] = role ?: [NSNull null];
    node[@"frame"] = [self _rectDict:item.frame];
    node[@"bounds"] = [self _rectDict:item.bounds];
    node[@"alpha"] = [self _num:item.alpha];
    node[@"hidden"] = @(item.isHidden);

    NSString *text = [self _extractStringAttributeForItem:item identifiers:@[@"text", @"title", @"stringValue", @"attributedText"]];
    node[@"text"] = text.length ? text : [NSNull null];

    NSString *a11yID = [self _extractStringAttributeForItem:item identifiers:@[@"accessibilityIdentifier"]];
    node[@"accessibilityIdentifier"] = a11yID.length ? a11yID : [NSNull null];

    NSString *a11yLabel = [self _extractStringAttributeForItem:item identifiers:@[@"accessibilityLabel"]];
    node[@"accessibilityLabel"] = a11yLabel.length ? a11yLabel : [NSNull null];

    NSString *path = [self _breadcrumbForItem:item];
    node[@"path"] = path.length ? path : [NSNull null];

    // Full per-node attribute groups exactly as the dashboard panel renders them.
    node[@"attributes"] = [self _attributeGroupsArrayForItem:item];

    // Children.
    NSMutableArray *children = [NSMutableArray array];
    if (recursive) {
        for (LookinDisplayItem *sub in item.subitems) {
            [children addObject:[self _nodeDictForItem:sub recursive:YES]];
        }
    }
    node[@"children"] = children;

    return node;
}

/// JSON-safe number: non-finite (NaN/±Inf) values become NSNull so serialization can't fail.
+ (id)_num:(double)v {
    return isfinite(v) ? @(v) : (id)[NSNull null];
}

+ (NSDictionary *)_rectDict:(CGRect)r {
    return @{ @"x": [self _num:r.origin.x],
              @"y": [self _num:r.origin.y],
              @"width": [self _num:r.size.width],
              @"height": [self _num:r.size.height] };
}

+ (unsigned long)_oidForItem:(LookinDisplayItem *)item {
    // Matches HierarchyIndex.oid(of:): prefer view, then layer, then window.
    if (item.viewObject.oid) { return item.viewObject.oid; }
    if (item.layerObject.oid) { return item.layerObject.oid; }
    if (item.windowObject.oid) { return item.windowObject.oid; }
    return 0;
}

+ (NSString *)_classNameForItem:(LookinDisplayItem *)item {
    NSString *(^head)(LookinObject *) = ^NSString *(LookinObject *obj) {
        return obj.classChainList.firstObject;
    };
    NSString *name = head(item.viewObject) ?: head(item.layerObject) ?: head(item.windowObject);
    return name;
}

+ (NSString *)_roleForClassName:(NSString *)className {
    if (!className) { return nil; }
    static NSDictionary *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{ @"UIButton": @"button", @"NSButton": @"button",
                 @"UILabel": @"label", @"NSTextField": @"label",
                 @"UIImageView": @"image", @"NSImageView": @"image",
                 @"UITextField": @"textInput",
                 @"UITextView": @"textArea", @"NSTextView": @"textArea",
                 @"UISwitch": @"switch",
                 @"UISlider": @"slider",
                 @"UIScrollView": @"scroll", @"NSScrollView": @"scroll",
                 @"UITableView": @"table", @"NSTableView": @"table",
                 @"UICollectionView": @"collection", @"NSCollectionView": @"collection",
                 @"UIStackView": @"stack", @"NSStackView": @"stack",
                 @"UIWindow": @"window", @"NSWindow": @"window" };
    });
    NSString *role = map[className];
    if (role) { return role; }
    if ([className containsString:@"Button"]) { return @"button"; }
    if ([className containsString:@"Label"]) { return @"label"; }
    return nil;
}

+ (NSString *)_breadcrumbForItem:(LookinDisplayItem *)item {
    // Root -> self chain of class names joined by " ▸ ", mirroring HierarchyIndex.breadcrumb.
    NSMutableArray<NSString *> *chain = [NSMutableArray array];
    LookinDisplayItem *cur = item;
    while (cur) {
        NSString *label = [self _classNameForItem:cur] ?: @"UnknownView";
        [chain insertObject:label atIndex:0];
        cur = cur.superItem;
    }
    return [chain componentsJoinedByString:@" ▸ "];
}

#pragma mark - Attribute extraction

+ (NSString *)_extractStringAttributeForItem:(LookinDisplayItem *)item identifiers:(NSArray<NSString *> *)identifiers {
    // Parity with JSONShape.extractAttribute: scan attributesGroupList, match identifier substring.
    for (NSString *wanted in identifiers) {
        for (LookinAttributesGroup *group in item.attributesGroupList) {
            for (LookinAttributesSection *section in group.attrSections) {
                for (LookinAttribute *attr in section.attributes) {
                    if ([attr.identifier containsString:wanted]) {
                        if ([attr.value isKindOfClass:[NSString class]] && [(NSString *)attr.value length]) {
                            return attr.value;
                        }
                    }
                }
            }
        }
    }
    return nil;
}

+ (NSArray<NSDictionary *> *)_attributeGroupsArrayForItem:(LookinDisplayItem *)item {
    NSMutableArray *groupsArray = [NSMutableArray array];
    for (LookinAttributesGroup *group in [item queryAllAttrGroupList]) {
        NSMutableArray *sectionsArray = [NSMutableArray array];
        for (LookinAttributesSection *section in group.attrSections) {
            NSMutableArray *attrsArray = [NSMutableArray array];
            for (LookinAttribute *attr in section.attributes) {
                NSMutableDictionary *attrDict = [NSMutableDictionary dictionary];
                if (attr.identifier.length) { attrDict[@"id"] = attr.identifier; }
                NSString *title = [self _titleForAttribute:attr];
                if (title.length) { attrDict[@"title"] = title; }
                attrDict[@"value"] = [self _jsonValueForAttribute:attr] ?: [NSNull null];
                [attrsArray addObject:attrDict];
            }
            if (attrsArray.count == 0) { continue; }
            NSMutableDictionary *sectionDict = [NSMutableDictionary dictionary];
            NSString *secTitle = [self _titleForSection:section];
            if (secTitle.length) { sectionDict[@"title"] = secTitle; }
            sectionDict[@"attributes"] = attrsArray;
            [sectionsArray addObject:sectionDict];
        }
        if (sectionsArray.count == 0) { continue; }
        NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
        NSString *gTitle = [self _titleForGroup:group];
        if (gTitle.length) { groupDict[@"title"] = gTitle; }
        groupDict[@"sections"] = sectionsArray;
        [groupsArray addObject:groupDict];
    }
    return groupsArray;
}

#pragma mark - Titles

+ (NSString *)_titleForGroup:(LookinAttributesGroup *)group {
    NSString *title = [group queryDisplayTitle];
    return title;
}

+ (NSString *)_titleForSection:(LookinAttributesSection *)section {
    if (section.isUserCustom) {
        LookinAttribute *attr = section.attributes.firstObject;
        return attr.displayTitle;
    }
    return [LookinDashboardBlueprint sectionTitleWithSectionID:section.identifier];
}

+ (NSString *)_titleForAttribute:(LookinAttribute *)attr {
    if (attr.isUserCustom) {
        return attr.displayTitle;
    }
    NSString *title = [LookinDashboardBlueprint briefTitleWithAttrID:attr.identifier];
    if (!title.length) {
        title = [LookinDashboardBlueprint fullTitleWithAttrID:attr.identifier];
    }
    return title;
}

#pragma mark - Value formatting

+ (id)_jsonValueForAttribute:(LookinAttribute *)attr {
    id value = attr.value;
    if (!value) { return [NSNull null]; }

    switch (attr.attrType) {
        case LookinAttrTypeBOOL:
            return @([value boolValue]);

        case LookinAttrTypeCGRect: {
            if ([value isKindOfClass:[NSValue class]]) {
                CGRect r = [value rectValue];
                return [self _rectDict:r];
            }
            break;
        }
        case LookinAttrTypeCGPoint: {
            if ([value isKindOfClass:[NSValue class]]) {
                CGPoint p = [value pointValue];
                return @{ @"x": [self _num:p.x], @"y": [self _num:p.y] };
            }
            break;
        }
        case LookinAttrTypeCGSize: {
            if ([value isKindOfClass:[NSValue class]]) {
                CGSize s = [value sizeValue];
                return @{ @"width": [self _num:s.width], @"height": [self _num:s.height] };
            }
            break;
        }
        case LookinAttrTypeCGVector: {
            CGFloat b[4] = {0};
            if ([self _readDoubles:b count:2 fromValue:value]) {
                return @{ @"dx": [self _num:b[0]], @"dy": [self _num:b[1]] };
            }
            break;
        }
        case LookinAttrTypeUIEdgeInsets: {
            CGFloat b[4] = {0};
            if ([self _readDoubles:b count:4 fromValue:value]) {
                return @{ @"top": [self _num:b[0]], @"left": [self _num:b[1]], @"bottom": [self _num:b[2]], @"right": [self _num:b[3]] };
            }
            break;
        }
        case LookinAttrTypeUIOffset: {
            CGFloat b[4] = {0};
            if ([self _readDoubles:b count:2 fromValue:value]) {
                return @{ @"horizontal": [self _num:b[0]], @"vertical": [self _num:b[1]] };
            }
            break;
        }
        case LookinAttrTypeUIColor: {
            if ([value isKindOfClass:[NSArray class]]) {
                NSArray *rgba = value;
                if (rgba.count == 4) {
                    return @{ @"r": rgba[0], @"g": rgba[1], @"b": rgba[2], @"a": rgba[3] };
                }
                return [self _sanitizeJSONValue:rgba];
            }
            break;
        }
        case LookinAttrTypeJson: {
            if ([value isKindOfClass:[NSString class]]) {
                NSData *data = [(NSString *)value dataUsingEncoding:NSUTF8StringEncoding];
                id parsed = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
                if (parsed) { return parsed; }
                return value;
            }
            return [self _sanitizeJSONValue:value];
        }
        default:
            break;
    }
    return [self _sanitizeJSONValue:value];
}

/// Convert any object into a JSON-safe representation.
+ (id)_sanitizeJSONValue:(id)value {
    if (!value || value == [NSNull null]) { return [NSNull null]; }
    if ([value isKindOfClass:[NSString class]]) { return value; }
    if ([value isKindOfClass:[NSNumber class]]) {
        double d = [(NSNumber *)value doubleValue];
        if (!isfinite(d)) { return [NSNull null]; }
        return value;
    }
    if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *out = [NSMutableArray array];
        for (id v in (NSArray *)value) { [out addObject:[self _sanitizeJSONValue:v]]; }
        return out;
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *out = [NSMutableDictionary dictionary];
        [(NSDictionary *)value enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            out[[key description]] = [self _sanitizeJSONValue:obj];
        }];
        return out;
    }
    if ([value isKindOfClass:[NSValue class]]) {
        // Best-effort decode of common geometry structs by encoded type.
        const char *type = [(NSValue *)value objCType];
        if (type) {
            if (strcmp(type, @encode(CGRect)) == 0) { return [self _rectDict:[value rectValue]]; }
            if (strcmp(type, @encode(CGPoint)) == 0) { CGPoint p = [value pointValue]; return @{ @"x": @(p.x), @"y": @(p.y) }; }
            if (strcmp(type, @encode(CGSize)) == 0) { CGSize s = [value sizeValue]; return @{ @"width": @(s.width), @"height": @(s.height) }; }
        }
    }
    return [value description];
}

/// Reads `count` (<=4) CGFloat fields out of an NSValue-wrapped struct.
+ (BOOL)_readDoubles:(CGFloat *)buffer count:(NSUInteger)count fromValue:(id)value {
    if (![value isKindOfClass:[NSValue class]] || count == 0 || count > 4) { return NO; }
    CGFloat tmp[4] = {0};
    @try {
        [(NSValue *)value getValue:tmp];
    } @catch (__unused NSException *e) {
        return NO;
    }
    for (NSUInteger i = 0; i < count; i++) { buffer[i] = tmp[i]; }
    return YES;
}

+ (NSString *)_readableStringForAttribute:(LookinAttribute *)attr {
    id json = [self _jsonValueForAttribute:attr];
    return [self _readableStringFromJSONValue:json];
}

+ (NSString *)_readableStringFromJSONValue:(id)value {
    if (!value || value == [NSNull null]) { return @"nil"; }
    if ([value isKindOfClass:[NSString class]]) { return value; }
    if ([value isKindOfClass:[NSNumber class]]) {
        NSNumber *num = value;
        if (strcmp(num.objCType, @encode(BOOL)) == 0 || strcmp(num.objCType, @encode(char)) == 0) {
            // Heuristic: 0/1 chars are usually BOOL in this data model.
            if ([num intValue] == 0 || [num intValue] == 1) {
                return [num boolValue] ? @"true" : @"false";
            }
        }
        return num.stringValue;
    }
    if ([value isKindOfClass:[NSArray class]]) {
        NSMutableArray *parts = [NSMutableArray array];
        for (id v in (NSArray *)value) { [parts addObject:[self _readableStringFromJSONValue:v]]; }
        return [NSString stringWithFormat:@"[%@]", [parts componentsJoinedByString:@", "]];
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSMutableArray *parts = [NSMutableArray array];
        [(NSDictionary *)value enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [parts addObject:[NSString stringWithFormat:@"%@: %@", key, [self _readableStringFromJSONValue:obj]]];
        }];
        return [NSString stringWithFormat:@"{%@}", [parts componentsJoinedByString:@", "]];
    }
    return [value description];
}

@end
