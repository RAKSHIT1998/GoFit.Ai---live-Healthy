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
            print("⚠️ HealthKit is not available on this device")
            throw HealthKitError.notAvailable
        }
        
        // Check if HealthKit entitlement is available
        // If not, fail gracefully without crashing
        do {
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
        } catch {
            print("⚠️ HealthKit authorization error: \(error.localizedDescription)")
            // If entitlement is missing, log but don't crash
            if (error as NSError).domain == "com.apple.healthkit" && (error as NSError).code == 4 {
                print("⚠️ HealthKit entitlement is missing. Please enable HealthKit capability in Xcode.")
            }
            throw error
        }
    }
    
    // Check authorization status
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            isAuthorized = false
            return
        }
        
        // Check if HealthKit is properly configured
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            isAuthorized = false
            return
        }
        
        // Check authorization status - handle gracefully if entitlement is missing
        // authorizationStatus doesn't throw, but we check for proper setup
        let status = healthStore.authorizationStatus(for: stepType)
        // Accept both sharingAuthorized and notDetermined (user hasn't been asked yet)
        isAuthorized = status == .sharingAuthorized || status == .notDetermined
    }
    
    // Read today's steps
    func readTodaySteps() async throws {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.invalidType
        }
        
        // Check authorization status before reading
        let authStatus = healthStore.authorizationStatus(for: stepType)
        guard authStatus == .sharingAuthorized else {
            if authStatus == .notDetermined {
                throw HealthKitError.authorizationNotDetermined
            }
            // If denied, silently fail (user has explicitly denied)
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
                if let error = error {
                    print("Error reading steps: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let self = self, let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: ())
                    return
                }
                
                Task { @MainActor in
                    self.todaySteps = Int(sum.doubleValue(for: HKUnit.count()))
                }
                continuation.resume(returning: ())
            }
            
            healthStore.execute(query)
        }
    }
    
    // Read today's active calories
    func readTodayActiveCalories() async throws {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.invalidType
        }
        
        // Check authorization status before reading
        let authStatus = healthStore.authorizationStatus(for: energyType)
        guard authStatus == .sharingAuthorized else {
            if authStatus == .notDetermined {
                throw HealthKitError.authorizationNotDetermined
            }
            // If denied, silently fail (user has explicitly denied)
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
                if let error = error {
                    print("Error reading active calories: \(error)")
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let self = self, let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: ())
                    return
                }
                
                Task { @MainActor in
                    self.todayActiveCalories = sum.doubleValue(for: HKUnit.kilocalorie())
                }
                continuation.resume(returning: ())
            }
            
            healthStore.execute(query)
        }
    }
    
    // Read heart rate
    func readHeartRate() async throws {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.invalidType
        }
        
        // Check authorization status before reading
        let authStatus = healthStore.authorizationStatus(for: heartRateType)
        guard authStatus == .sharingAuthorized else {
            if authStatus == .notDetermined {
                throw HealthKitError.authorizationNotDetermined
            }
            // If denied, silently fail (user has explicitly denied)
            return
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let group = DispatchGroup()
            var queryError: Error?
            
            // Read average heart rate
            group.enter()
            let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
                defer { group.leave() }
                
                if let error = error {
                    queryError = error
                    return
                }
                
                if let self = self, let sample = samples?.first as? HKQuantitySample {
                    Task { @MainActor in
                        self.averageHeartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    }
                }
            }
            
            healthStore.execute(query)
            
            // Read resting heart rate
            if let restingType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
                group.enter()
                let restingQuery = HKSampleQuery(sampleType: restingType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
                    defer { group.leave() }
                    
                    if let error = error {
                        queryError = error
                        return
                    }
                    
                    if let self = self, let sample = samples?.first as? HKQuantitySample {
                        Task { @MainActor in
                            self.restingHeartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                        }
                    }
                }
                
                healthStore.execute(restingQuery)
            }
            
            // Wait for both queries to complete
            group.notify(queue: .main) {
                if let error = queryError {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
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
    case authorizationNotDetermined
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .invalidType:
            return "Invalid HealthKit type"
        case .authorizationDenied:
            return "HealthKit authorization denied"
        case .authorizationNotDetermined:
            return "HealthKit authorization not determined. Please request authorization first."
        }
    }
}

