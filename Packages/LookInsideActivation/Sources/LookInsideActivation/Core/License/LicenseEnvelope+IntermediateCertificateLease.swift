public extension LicenseEnvelope {
    func applying(lease: IntermediateCertificateLease) -> LicenseEnvelope {
        LicenseEnvelope(
            licenseID: licenseID,
            audience: audience,
            licenseClass: licenseClass,
            lifecycleState: lifecycleState,
            issuedTo: issuedTo,
            issuedAt: issuedAt,
            expiresAt: expiresAt,
            serviceEndsAt: serviceEndsAt,
            nextCertificateRenewalAt: lease.renewAfter,
            deviceWarning: deviceWarning,
            certificateChain: CertificateChain(
                rootCertificateID: certificateChain.rootCertificateID,
                intermediateCertificateID: lease.certificateID,
                intermediateIssuedAt: lease.issuedAt,
                intermediateExpiresAt: lease.expiresAt,
                renewAfter: lease.renewAfter,
                boundUDID: lease.udid
            )
        )
    }
}
