import Foundation

enum PlanType {
    case monthly
    case yearly

    var id: String {
        switch self {
        case .monthly:
            return "com.gofitai.premium.monthlyy"
        case .yearly:
            return "com.gofitai.premium.yearlyy"
        }
    }

    var title: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        }
    }

    var savings: String? {
        switch self {
        case .monthly: return nil
        case .yearly: return "Save 20%"
        }
    }

    var periodText: String {
        switch self {
        case .monthly: return "month"
        case .yearly: return "year"
        }
    }
}
