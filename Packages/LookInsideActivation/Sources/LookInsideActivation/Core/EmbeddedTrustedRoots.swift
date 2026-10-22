import Foundation

public struct TrustedRootPublicKey: Sendable, Equatable {
    public let certificateID: String
    public let publicKeyPEM: String
    public let publicKeySHA256: String

    public init(
        certificateID: String,
        publicKeyPEM: String,
        publicKeySHA256: String
    ) {
        self.certificateID = certificateID
        self.publicKeyPEM = publicKeyPEM
        self.publicKeySHA256 = publicKeySHA256
    }
}

public enum EmbeddedTrustedRoots {
    public static let rootProd2026 = TrustedRootPublicKey(
        certificateID: "root_prod_2026",
        publicKeyPEM: """
        -----BEGIN PUBLIC KEY-----
        MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEApc0UUibWzZv3pgAulN2G
        kihWoLCl0KnSBLdzh3ku+IhFGxV9Vj/YcO36KeLQGiNptpNUWsM5W9N5AcH7Waa8
        fXzEuaMSo/Cjo0sQdthiJ9TH7WH9nZ9AoXrDFszrdjbdGHDdAkLAwEClR45Q2d7s
        NqY1p5E2At0193si/I9wWumKPgmbE2XnFpT7kqdNw5geiAo5lDZX3CK0nxE9n9Vq
        DmViglQEoWFdPhQa/HD1ry/1vocBoHmvZAE0hDPHxa+Hf6XTZoW62RmalcT2A50H
        TuAY3xCcDPuHl93fWgNT1rG4DIUzaJEuaxX9/UvBX7jw+DJ+xH63z/nGuxmoLObq
        Dve57W0To5mtaYSNgolXJuZSd+Ju79g0Y+je+/B+Ave+TQiHqwWlVghan2qz+vN7
        CShMgIcBkqAy7XI2i/wzotfagT10OYTfXsIuT0stsScAdd5nyXN8sUu11trJkBIJ
        wF/nOMDi8b08bKbMhkUlclrItJQYXl76nOw3umw2oCYuo164bd94uJkwsaN1m7GD
        zsArlPlfIqPvzvlAyUPJrHvD5ug1hid0bxu7Vk7eR0MO68H2MEolRZDKAcfYvkl4
        zXo8b6nThTHEF25o/pn3wb3+Dp7rxCQHrMxWKTwNP6zrYxaT4agbSs4cj39OwHxl
        nBuxlRY5RfQT0XJm756vnOsCAwEAAQ==
        -----END PUBLIC KEY-----
        """,
        publicKeySHA256: "e67c0e0635447377fa53a894e6547104a33747eab74c25fde4cd2a2742882631"
    )

    /// Roots the client trusts. Release builds trust only `rootProd2026`;
    /// DEBUG builds add `ActivationDebugOverrides.additionalTrustedRoot`.
    public static var trusted: [TrustedRootPublicKey] {
        #if DEBUG
            if let additional = ActivationDebugOverrides.additionalTrustedRoot {
                return [rootProd2026, additional]
            }
        #endif
        return [rootProd2026]
    }

    public static var all: [String: TrustedRootPublicKey] {
        Dictionary(trusted.map { ($0.certificateID, $0) }, uniquingKeysWith: { first, _ in first })
    }

    public static func publicKey(for certificateID: String) -> TrustedRootPublicKey? {
        all[certificateID]
    }
}
