import Foundation
import Security

public enum CertificateSigningRequestError: Error, Equatable {
    case unsupportedKeyType
    case publicKeyExportFailed(String)
    case signingFailed(String)
    /// `SecKeyCreateSignature` failed with this keychain status.
    case signingFailedWithStatus(Int32, String)
}

public enum CertificateSigningRequestBuilder {
    public static func makePKCS10PEM(
        privateKey: SecKey,
        commonName: String
    ) throws -> String {
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw CertificateSigningRequestError.publicKeyExportFailed("Public key lookup failed.")
        }
        var exportError: Unmanaged<CFError>?
        guard let publicKeyBytes = SecKeyCopyExternalRepresentation(publicKey, &exportError) as Data? else {
            let message =
                (exportError?.takeRetainedValue() as Error?)?.localizedDescription
                    ?? "Public key export failed."
            throw CertificateSigningRequestError.publicKeyExportFailed(message)
        }

        let subject = DER.encodeSequence([
            DER.encodeSet([
                DER.encodeSequence([
                    DER.encodeOID(ASN1OID.commonName),
                    DER.encodeUTF8String(commonName),
                ]),
            ]),
        ])

        let spki = DER.encodeSequence([
            DER.encodeSequence([
                DER.encodeOID(ASN1OID.rsaEncryption),
                Data([0x05, 0x00]),
            ]),
            DER.encodeBitString(publicKeyBytes),
        ])

        let attributes = Data([0xA0, 0x00])

        let certificationRequestInfo = DER.encodeSequence([
            DER.encodeInteger(0),
            subject,
            spki,
            attributes,
        ])

        var signError: Unmanaged<CFError>?
        guard
            let signature = SecKeyCreateSignature(
                privateKey,
                .rsaSignatureMessagePKCS1v15SHA256,
                certificationRequestInfo as CFData,
                &signError
            ) as Data?
        else {
            let error = signError?.takeRetainedValue() as Error?
            let message = error?.localizedDescription ?? "Signature generation failed."
            if let error, (error as NSError).domain == NSOSStatusErrorDomain {
                throw CertificateSigningRequestError.signingFailedWithStatus(Int32((error as NSError).code), message)
            }
            throw CertificateSigningRequestError.signingFailed(message)
        }

        let signatureAlgorithm = DER.encodeSequence([
            DER.encodeOID(ASN1OID.sha256WithRSAEncryption),
            Data([0x05, 0x00]),
        ])

        let csrDER = DER.encodeSequence([
            certificationRequestInfo,
            signatureAlgorithm,
            DER.encodeBitString(signature),
        ])

        return PEM.encode(csrDER, label: "CERTIFICATE REQUEST")
    }
}

enum ASN1OID {
    static let commonName: [UInt64] = [2, 5, 4, 3]
    static let rsaEncryption: [UInt64] = [1, 2, 840, 113_549, 1, 1, 1]
    static let sha256WithRSAEncryption: [UInt64] = [1, 2, 840, 113_549, 1, 1, 11]
}

enum DER {
    static func encodeSequence(_ elements: [Data]) -> Data {
        encodeTLV(tag: 0x30, value: elements.reduce(Data(), +))
    }

    static func encodeSet(_ elements: [Data]) -> Data {
        encodeTLV(tag: 0x31, value: elements.reduce(Data(), +))
    }

    static func encodeInteger(_ value: Int) -> Data {
        var bytes: [UInt8] = []
        var remaining = value
        if remaining == 0 {
            bytes = [0]
        } else {
            while remaining > 0 {
                bytes.insert(UInt8(remaining & 0xFF), at: 0)
                remaining >>= 8
            }
            if bytes[0] & 0x80 != 0 {
                bytes.insert(0, at: 0)
            }
        }
        return encodeTLV(tag: 0x02, value: Data(bytes))
    }

    static func encodeUTF8String(_ value: String) -> Data {
        encodeTLV(tag: 0x0C, value: Data(value.utf8))
    }

    static func encodeBitString(_ data: Data) -> Data {
        var value = Data([0x00])
        value.append(data)
        return encodeTLV(tag: 0x03, value: value)
    }

    static func encodeOID(_ components: [UInt64]) -> Data {
        precondition(components.count >= 2)
        var bytes: [UInt8] = []
        bytes.append(UInt8(components[0] * 40 + components[1]))
        for component in components.dropFirst(2) {
            bytes.append(contentsOf: base128(component))
        }
        return encodeTLV(tag: 0x06, value: Data(bytes))
    }

    private static func base128(_ value: UInt64) -> [UInt8] {
        if value == 0 {
            return [0x00]
        }
        var buffer: [UInt8] = []
        var remaining = value
        while remaining > 0 {
            buffer.insert(UInt8(remaining & 0x7F), at: 0)
            remaining >>= 7
        }
        for index in 0 ..< (buffer.count - 1) {
            buffer[index] |= 0x80
        }
        return buffer
    }

    private static func encodeTLV(tag: UInt8, value: Data) -> Data {
        var result = Data([tag])
        result.append(encodeLength(value.count))
        result.append(value)
        return result
    }

    private static func encodeLength(_ length: Int) -> Data {
        if length < 0x80 {
            return Data([UInt8(length)])
        }
        var bytes: [UInt8] = []
        var remaining = length
        while remaining > 0 {
            bytes.insert(UInt8(remaining & 0xFF), at: 0)
            remaining >>= 8
        }
        return Data([0x80 | UInt8(bytes.count)] + bytes)
    }
}

enum PEM {
    static func encode(_ data: Data, label: String) -> String {
        let base64 = data.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
        return "-----BEGIN \(label)-----\n\(base64)\n-----END \(label)-----\n"
    }
}
