# Platform Permissions

## Android (AndroidManifest.xml)
Add the following inside `<manifest>`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

Add Google Maps API key inside `<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_MAPS_KEY" />
```

## iOS (Info.plist)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show the school bus on the map.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need background location to share the bus location.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need background location to share the bus location.</string>
```

Add Google Maps key in AppDelegate (iOS):

```swift
GMSServices.provideAPIKey("YOUR_IOS_MAPS_KEY")
```
