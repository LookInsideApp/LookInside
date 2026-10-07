import Foundation

extension LookInsideAuthenticatorAPIClient {
    func send<Response: Decodable>(
        path: String,
        method: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        let request = try makeRequest(
            path: path,
            method: method,
            queryItems: queryItems
        )
        return try await perform(request)
    }

    func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: String,
        body: Body,
        queryItems: [URLQueryItem] = []
    ) async throws -> Response {
        var request = try makeRequest(
            path: path,
            method: method,
            queryItems: queryItems
        )
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return try await perform(request)
    }

    private func makeRequest(
        path: String,
        method: String,
        queryItems: [URLQueryItem]
    ) throws -> URLRequest {
        let url = try makeURL(path: path, queryItems: queryItems)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func makeURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        guard
            var components = URLComponents(
                url: baseURL,
                resolvingAgainstBaseURL: false
            )
        else {
            throw LookInsideAuthenticatorAPIClientError.invalidURL(path)
        }

        components.path = (components.path as NSString).appendingPathComponent(path)
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw LookInsideAuthenticatorAPIClientError.invalidURL(path)
        }

        return url
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LookInsideAuthenticatorAPIClientError.invalidResponse
        }

        if (200 ..< 300).contains(httpResponse.statusCode) {
            return try JSONDecoder().decode(APIEnvelope<Response>.self, from: data).data
        }

        if let failure = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data) {
            throw LookInsideAuthenticatorAPIClientError.api(
                statusCode: httpResponse.statusCode,
                code: failure.error.code,
                message: failure.error.message
            )
        }

        throw LookInsideAuthenticatorAPIClientError.invalidResponse
    }
}
