//
//  LookinArchiveCoding.swift
//  LookInside
//
//  Turns a `HierarchyFile` into the bytes of a `.lookin` file and back.
//  The format is the keyed archive Lookin has always written: the class
//  names and coding keys belong to the LookinCore model and must not change,
//  so files written by older hosts open here and files written here open in
//  older hosts.
//

import Foundation

enum LookinArchiveCoding {
    /// The document type `LookinArchiveDocument` reads and writes.
    static let typeIdentifier = "com.lookin.lookin"

    /// Archives `file` with secure coding, as the Objective-C reader did.
    static func data(of file: HierarchyFile) throws -> Data {
        try NSKeyedArchiver.archivedData(withRootObject: file, requiringSecureCoding: true)
    }

    /// Unarchives and verifies a `.lookin` file.
    ///
    /// Older archives are not secure-coding clean, so the unarchiver does
    /// not require it; that also keeps the "allowed classes" warnings out of
    /// the log. A root object of another class fails the same way as an
    /// unreadable archive. A file outside the supported server versions
    /// fails with the version error from `+verifyHierarchyFile:`.
    static func hierarchyFile(from data: Data) throws -> HierarchyFile {
        let unarchiver: NSKeyedUnarchiver
        do {
            unarchiver = try NSKeyedUnarchiver(forReadingFrom: data)
        } catch {
            throw innerError
        }
        unarchiver.requiresSecureCoding = false
        let root = unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey)
        unarchiver.finishDecoding()
        guard let file = root as? HierarchyFile else {
            throw innerError
        }
        if let verifyError = HierarchyFile.verifyHierarchyFile(file) {
            throw verifyError
        }
        return file
    }

    /// `LookinErr_Inner`.
    static var innerError: NSError {
        NSError(
            domain: LookinErrorDomain,
            code: LookinErrCode_Inner,
            userInfo: [NSLocalizedDescriptionKey: NSLocalizedString("The operation failed due to an inner error.", comment: "")]
        )
    }
}
