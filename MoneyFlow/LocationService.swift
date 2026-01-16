//
//  LocationService.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/16.
//
//  Core Location Service for GPS tracking
//  - Get current country for currency suggestion
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

/// Location Service - Only for detecting country to suggest currency
@Observable
class LocationService: NSObject {
    
    // Singleton instance
    static let shared = LocationService()
    
    // Location Manager
    private let locationManager = CLLocationManager()
    
    // Published states
    var currentCountry: String?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isLoading: Bool = false
    
    // Continuation for async/await
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // Low accuracy is enough for country
        authorizationStatus = locationManager.authorizationStatus
    }
    
    /// Request location permission
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Check if location services are enabled
    var isLocationEnabled: Bool {
        CLLocationManager.locationServicesEnabled() &&
        (authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways)
    }
    
    /// Get current country (async) - for currency suggestion only
    func getCurrentCountry() async -> String? {
        // Return mock data for simulator (Apple Park)
        #if targetEnvironment(simulator)
        currentCountry = "United States"
        return "United States"
        // The actual device uses the real GPS location.
        #else
        guard isLocationEnabled else {
            requestPermission()
            return nil
        }
        
        isLoading = true
        
        // Request location
        let location = await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
        
        guard let location = location else {
            isLoading = false
            return nil
        }
        
        // Get country from location
        let country = await getCountry(from: location)
        currentCountry = country
        isLoading = false
        
        return country
        #endif
    }
    
    /// Get country from location using MKLocalSearch
    private func getCountry(from location: CLLocation) async -> String? {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        searchRequest.resultTypes = .address
        
        let search = MKLocalSearch(request: searchRequest)
        
        do {
            let response = try await search.start()
            
            if let item = response.mapItems.first {
                let placemark = item.placemark
                return placemark.country
            }
        } catch {
            print("Geocoding error: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    /// Suggest currency based on country using CurrencyManager
    func suggestCurrency(for country: String?) -> String? {
        guard let country = country else { return nil }
        return CurrencyManager.shared.currencyCode(for: country)
    }
    
    /// Get suggested currency for current location
    func getSuggestedCurrency() async -> String? {
        let country = await getCurrentCountry()
        return suggestCurrency(for: country)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
        isLoading = false
    }
}
