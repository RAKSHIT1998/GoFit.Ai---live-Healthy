import Foundation
import HealthKit

@MainActor
class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var todaySteps: Int = 0
    @Published var todayActiveCalories: Double = 0
    @Published var restingHeartRate: Double = 0
    @Published var averageHeartRate: Double = 0
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // Request authorization
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .height)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .dietaryWater)!
        ]
        
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
        checkAuthorizationStatus()
    }
    
    // Check authorization status
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            isAuthorized = false
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let status = healthStore.authorizationStatus(for: stepType)
        isAuthorized = status == .sharingAuthorized
    }
    
    // Read today's steps
    func readTodaySteps() async throws {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.invalidType
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(throwing: HealthKitError.invalidType)
                    return
                }
                
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                
                Task { @MainActor [weak self] in
                    self?.todaySteps = steps
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    // Read today's active calories
    func readTodayActiveCalories() async throws {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.invalidType
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(throwing: HealthKitError.invalidType)
                    return
                }
                
                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                
                Task { @MainActor [weak self] in
                    self?.todayActiveCalories = calories
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
    }
    
    // Read heart rate
    func readHeartRate() async throws {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.invalidType
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Read average heart rate
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume()
                    return
                }
                
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                
                Task { @MainActor [weak self] in
                    self?.averageHeartRate = heartRate
                    continuation.resume()
                }
            }
            
            healthStore.execute(query)
        }
        
        // Read resting heart rate
        if let restingType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            try await withCheckedThrowingContinuation { continuation in
                let restingQuery = HKSampleQuery(sampleType: restingType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let sample = samples?.first as? HKQuantitySample else {
                        continuation.resume()
                        return
                    }
                    
                    let restingRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    
                    Task { @MainActor [weak self] in
                        self?.restingHeartRate = restingRate
                        continuation.resume()
                    }
                }
                
                healthStore.execute(restingQuery)
            }
        }
    }
    
    // Sync data to backend
    func syncToBackend() async throws {
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        
        // Read all today's data
        try await readTodaySteps()
        try await readTodayActiveCalories()
        try await readHeartRate()
        
        // Prepare sync data
        let syncData: [String: Any] = [
            "steps": todaySteps,
            "activeCalories": todayActiveCalories,
            "heartRate": [
                "resting": restingHeartRate > 0 ? restingHeartRate : nil,
                "average": averageHeartRate > 0 ? averageHeartRate : nil
            ],
            "date": ISO8601DateFormatter().string(from: startOfDay)
        ]
        
        // Send to backend
        let url = URL(string: "\(NetworkManager.shared.baseURL)/health/sync")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let token = AuthService.shared.readToken()?.accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: syncData)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "HealthKitSync", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to sync health data"])
        }
    }
    
    // Write water intake
    func writeWater(amount: Double) async throws {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            throw HealthKitError.invalidType
        }
        
        let quantity = HKQuantity(unit: HKUnit.literUnit(with: .milli), doubleValue: amount * 1000) // Convert liters to milliliters
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: Date(), end: Date())
        
        try await healthStore.save(sample)
    }
}

enum HealthKitError: LocalizedError {
    case notAvailable
    case invalidType
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .invalidType:
            return "Invalid HealthKit type"
        case .authorizationDenied:
            return "HealthKit authorization denied"
        }
    }
}

