import Foundation
import AdaptiveCore

internal class AnalyticsRepository {

    func post(path: String, data: Data) async throws {
        guard let user = AdaptiveCore.shared.currentUser else {
            throw AdaptiveError("no_user", "Call AdaptiveCore.login() before logging events.")
        }

        let merged = injectBaseFields(user: user, data: data)
        let body   = String(data: merged, encoding: .utf8) ?? "{}"

        let result = await AdaptiveCore.shared.post(path: path, body: body)
        switch result {
        case .success(let response):
            AdaptiveLogger.log(tag: "Analytics", message: "Result: \(response)")
        case .failure(let error):
            AdaptiveLogger.log(tag: "Analytics", message: "[HTTP_ERROR]: Request \(path) failed: \(error)")
        }
    }

    private func injectBaseFields(user: AdaptiveUser, data: Data) -> Data {
        var dict = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
        dict["userId"]         = Int(user.userId) ?? 0
        dict["userEmail"]      = user.userEmail
        dict["userFullName"]   = user.userName
        dict["phoneNumber"]    = user.phoneNumber
        dict["clientId"]       = AdaptiveCore.shared.clientId ?? ""
        dict["eventTimestamp"] = Int(Date().timeIntervalSince1970)
        return (try? JSONSerialization.data(withJSONObject: dict)) ?? data
    }
}
