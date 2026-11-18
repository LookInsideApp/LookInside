//
//  KeyedArchiveClassAllowList.swift
//  LookInside
//
//  Checks the classes a keyed archive names before an unarchiver that does
//  not require secure coding decodes it. Such an unarchiver instantiates any
//  class this process has that the archive names and runs its
//  -initWithCoder:, so a crafted file could reach code that no document of
//  its kind ever needs. Two documents still need that unarchiver: older
//  `.lookin` files are not secure-coding clean, and the layer archives inside
//  a `.viewhierarchy` decode differently through QuartzCore's secure reader
//  (`CAPackage` drops the position of a text layer whose font is an
//  `NSFont`). Both read their bytes through this check first, so what they
//  decode is unchanged for every file they are meant to open.
//
//  Only classes this process has matter: a name it lacks cannot be
//  instantiated. Every name in every class record is checked, the archived
//  superclass chain included, so a fallback to a superclass is covered too.
//  Classes are looked up and walked through the runtime without being sent
//  a message, so a class is never initialized before it is admitted.
//

import Foundation
import ObjectiveC

struct KeyedArchiveClassAllowList {
    /// Classes admitted by name.
    let classNames: Set<String>
    /// Classes admitted together with every subclass.
    let rootClasses: [AnyClass]
    /// Class name prefixes admitted, for a model whose classes share one.
    let classNamePrefixes: [String]
    /// Path fragments of the binaries whose classes are all admitted.
    let imagePathFragments: [String]

    init(
        classNames: Set<String>,
        rootClasses: [AnyClass] = [],
        classNamePrefixes: [String] = [],
        imagePathFragments: [String] = []
    ) {
        self.classNames = classNames
        self.rootClasses = rootClasses
        self.classNamePrefixes = classNamePrefixes
        self.imagePathFragments = imagePathFragments
    }

    /// Foundation's collection and value classes, which keyed archives name
    /// for their containers and scalars. `NSObject` heads every archived
    /// superclass chain; it cannot be decoded itself.
    static let foundationValueClassNames: Set<String> = [
        "NSObject",
        "NSArray", "NSMutableArray",
        "NSDictionary", "NSMutableDictionary",
        "NSSet", "NSMutableSet",
        "NSOrderedSet", "NSMutableOrderedSet",
        "NSString", "NSMutableString",
        "NSNumber", "NSDecimalNumber", "NSValue",
        "NSData", "NSMutableData",
        "NSDate", "NSNull", "NSURL", "NSUUID",
    ]

    /// Whether every class `archiveData` names that this process has is
    /// admitted. False for data that is not a keyed archive.
    func admitsEveryClass(in archiveData: Data) -> Bool {
        guard let archive = try? PropertyListSerialization.propertyList(from: archiveData, format: nil) as? [String: Any],
              let archivedObjects = archive["$objects"] as? [Any]
        else { return false }
        for archivedObject in archivedObjects {
            guard let classRecord = archivedObject as? [String: Any] else { continue }
            var archivedClassNames = classRecord["$classes"] as? [String] ?? []
            if let className = classRecord["$classname"] as? String {
                archivedClassNames.append(className)
            }
            for className in archivedClassNames {
                guard let archivedClass = NSClassFromString(className) else { continue }
                guard admits(archivedClass, named: className) else { return false }
            }
        }
        return true
    }

    /// Whether `archivedClass`, found under `className`, may be decoded.
    func admits(_ archivedClass: AnyClass, named className: String) -> Bool {
        if classNames.contains(className) {
            return true
        }
        if classNamePrefixes.contains(where: { className.hasPrefix($0) }) {
            return true
        }
        if let imageName = class_getImageName(archivedClass) {
            let imagePath = String(cString: imageName)
            if imagePathFragments.contains(where: { imagePath.contains($0) }) {
                return true
            }
        }
        var ancestorClass: AnyClass? = archivedClass
        while let currentClass = ancestorClass {
            if rootClasses.contains(where: { ObjectIdentifier($0) == ObjectIdentifier(currentClass) }) {
                return true
            }
            ancestorClass = class_getSuperclass(currentClass)
        }
        return false
    }
}
