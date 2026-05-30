import CoreLocation

/// Best-effort coordinates for meetup check-in — Android `MeetupCheckInLocation`.
enum MeetupCheckInLocation {
    static func peekLastKnownLatLng() -> (lat: Double, lng: Double)? {
        let manager = CLLocationManager()
        guard CLLocationManager.authorizationStatus() == .authorizedWhenInUse
            || CLLocationManager.authorizationStatus() == .authorizedAlways
        else { return nil }

        guard let location = manager.location else { return nil }
        let lat = location.coordinate.latitude
        let lng = location.coordinate.longitude
        guard lat.isFinite, lng.isFinite else { return nil }
        return (lat, lng)
    }
}
