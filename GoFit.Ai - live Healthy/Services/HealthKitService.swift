import Foundation
import HealthKit
import UIKit

@MainActor
class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var todaySteps: Int = 0
    @Published var todayActiveCalories: Double = 0
    @Published var restingHeartRate: Double = 0
    @Published var averageHeartRate: Double = 0
    
    // Use nonisolated(unsafe) for Task to allow access from deinit
    nonisolated(unsafe) private var periodicSyncTask: Task<Void, Never>?
    
    private init() {
        checkAuthorizationStatus()
        
        // Refresh authorization status when app comes to foreground
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkAuthorizationStatus()
            }
        }
    }
    
    deinit {
        // Cancel task directly - Task cancellation is thread-safe
        periodicSyncTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            isAuthorized = false
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        let stepStatus = healthStore.authorizationStatus(for: stepType)
        let caloriesStatus = healthStore.authorizationStatus(for: caloriesType)
        
        isAuthorized = (stepStatus == .sharingAuthorized) && (caloriesStatus == .sharingAuthorized)
    }
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .heartRate)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
        
        checkAuthorizationStatus()
        
        // Read data immediately after authorization
        if isAuthorized {
            await readTodayData()
        }
    }
    
    // MARK: - Data Reading
    
    func readTodayData() async {
        await readTodaySteps()
        await readTodayActiveCalories()
        await readHeartRate()
    }
    
    private func readTodaySteps() async {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            guard let self = self, let result = result, let sum = result.sumQuantity() else {
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            
            // Update daily log store
            LocalDailyLogStore.shared.updateSteps(steps)
            
            Task { @MainActor in
                self.todaySteps = steps
            }
        }
        
        healthStore.execute(query)
    }
    
    private func readTodayActiveCalories() async {
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: caloriesType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            guard let self = self, let result = result, let sum = result.sumQuantity() else {
                return
            }
            
            let calories = sum.doubleValue(for: HKUnit.kilocalorie())
            
            // Update daily log store
            LocalDailyLogStore.shared.updateCaloriesBurned(calories)
            
            Task { @MainActor in
                self.todayActiveCalories = calories
            }
        }
        
        healthStore.execute(query)
    }
    
    private func readHeartRate() async {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            guard let self = self,
                  let sample = samples?.first as? HKQuantitySample else {
                return
            }
            
            Task { @MainActor in
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                self.restingHeartRate = heartRate
                self.averageHeartRate = heartRate
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Backend Sync
    
    func syncToBackend() async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        guard let token = AuthService.shared.readToken()?.accessToken else {
            throw HealthKitError.notAuthenticated
        }
        
        let url = URL(string: "\(NetworkManager.shared.baseURL)/health/sync")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [
            "steps": todaySteps,
            "activeCalories": todayActiveCalories
        ]
        
        // Only include heartRate if it's greater than 0
        if restingHeartRate > 0 {
            body["heartRate"] = restingHeartRate
        }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw HealthKitError.syncFailed
        }
    }
    
    // MARK: - Periodic Sync
    
    func startPeriodicSync() {
        stopPeriodicSync()
        
        periodicSyncTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 15 * 60 * 1_000_000_000) // 15 minutes
                
                guard let self = self,
                      self.isAuthorized,
                      AuthService.shared.readToken() != nil else {
                    return
                }
                
                await self.readTodayData()
                try? await self.syncToBackend()
            }
        }
    }
    
    func stopPeriodicSync() {
        periodicSyncTask?.cancel()
        periodicSyncTask = nil
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case notAuthenticated
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit authorization not granted"
        case .notAuthenticated:
            return "User not authenticated"
        case .syncFailed:
            return "Failed to sync HealthKit data to backend"
        }
    }
}
