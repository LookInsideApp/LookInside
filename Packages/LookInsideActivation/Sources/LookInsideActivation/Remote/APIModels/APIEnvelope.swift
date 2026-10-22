struct APIEnvelope<Payload: Decodable>: Decodable {
    let data: Payload
}
