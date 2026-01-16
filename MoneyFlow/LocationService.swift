//
//  LocationService.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/16.
//
//  Core Location Service for GPS tracking
//  - Request location permissions
//  - Get current location
//  - Reverse geocoding for address using MapKit
//

import Foundation
import CoreLocation
import MapKit
import SwiftUI

/// Location data structure
struct LocationData: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    let address: String?
    let city: String?
    let country: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Formatted display string
    var displayString: String {
        if let address = address {
            return address
        } else if let city = city, let country = country {
            return "\(city), \(country)"
        } else if let city = city {
            return city
        } else {
            return String(format: "%.4f, %.4f", latitude, longitude)
        }
    }
}

/// Location Service using Core Location and MapKit
@Observable
class LocationService: NSObject {
    
    // Singleton instance
    static let shared = LocationService()
    
    // Location Manager
    private let locationManager = CLLocationManager()
    
    // Published states
    var currentLocation: CLLocation?
    var currentLocationData: LocationData?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var isLoading: Bool = false
    var errorMessage: String?
    
    // Continuation for async/await
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
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
    
    /// Get current location (async)
    func getCurrentLocation() async -> LocationData? {
        guard isLocationEnabled else {
            requestPermission()
            return nil
        }
        
        isLoading = true
        errorMessage = nil
        
        // Request location
        let location = await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
        
        guard let location = location else {
            isLoading = false
            return nil
        }
        
        currentLocation = location
        
        // Reverse geocode using MapKit
        let locationData = await reverseGeocode(location: location)
        currentLocationData = locationData
        isLoading = false
        
        return locationData
    }
    
    /// Reverse geocode location to address using MKLocalSearch
    private func reverseGeocode(location: CLLocation) async -> LocationData {
        // Create a search request for addresses at this location
        let searchRequest = MKLocalSearch.Request()
        searchRequest.region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 50,
            longitudinalMeters: 50
        )
        searchRequest.resultTypes = .address
        
        let search = MKLocalSearch(request: searchRequest)
        
        do {
            let response = try await search.start()
            
            if let item = response.mapItems.first {
                // Use item.name as the address (simplified approach)
                // For iOS 26+, use MKAddress API
                var addressString: String? = nil
                var city: String? = nil
                var country: String? = nil
                
                if let address = item.address {
                    // Try to build address from MKAddress
                    addressString = item.name
                    // MKAddress has different properties, use what's available
                }
                
                // Fall back to placemark for detailed address info
                let placemark = item.placemark
                
                var addressComponents: [String] = []
                
                if let subThoroughfare = placemark.subThoroughfare {
                    addressComponents.append(subThoroughfare)
                }
                if let thoroughfare = placemark.thoroughfare {
                    addressComponents.append(thoroughfare)
                }
                if let subLocality = placemark.subLocality {
                    addressComponents.append(subLocality)
                }
                if let locality = placemark.locality {
                    addressComponents.append(locality)
                }
                
                if !addressComponents.isEmpty {
                    addressString = addressComponents.joined(separator: ", ")
                }
                
                city = placemark.locality
                country = placemark.country
                
                return LocationData(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    address: addressString ?? item.name,
                    city: city,
                    country: country
                )
            }
        } catch {
            print("Geocoding error: \(error.localizedDescription)")
        }
        
        // Return basic location data if geocoding fails
        return LocationData(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            address: nil,
            city: nil,
            country: nil
        )
    }
    
    /// Suggest currency based on country using CurrencyManager
    func suggestCurrency(for country: String?) -> String? {
        guard let country = country else { return nil }
        return CurrencyManager.shared.currencyCode(for: country)
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
        errorMessage = error.localizedDescription
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
        isLoading = false
    }
}
