# Baggage Transfers iOS App

A native iOS application for managing baggage transfers between incoming and outgoing flights at airports. This app replicates the functionality of the web application with a native iOS interface and Firebase integration.

## Features

### 🏠 Dashboard
- Real-time overview of baggage transfer operations
- Statistics cards showing incoming flights, outgoing flights, total bags, and workflow status
- Recent flights lists with status indicators
- Quick access to pending collections and deliveries

### ✈️ Flights Management
- **Incoming Flights**: Track flights arriving with baggage
  - Flight number, terminal, origin
  - Scheduled and actual arrival times
  - Bag available time and carousel information
  - Collection and delivery status tracking
  
- **Outgoing Flights**: Manage flights receiving baggage
  - Flight number, terminal, destination
  - Scheduled and actual departure times
  - Bag distribution tracking

### 🔄 Transfers
- Create and manage baggage transfers between flights
- Multi-select flight pairing with visual feedback
- MAG transfer support for special handling
- Transfer statistics and grouping by incoming flight
- Real-time transfer status updates

### 📋 Workflow Operations
- **Pending Collections**: Bags ready for collection from carousels
- **Pending Deliveries**: Collected bags awaiting delivery to outgoing flights
- One-tap status updates (Mark Collected/Delivered)
- Today's operational summary with completion statistics

### ⚙️ Settings
- Anonymous authentication status
- Data management options
- App statistics and version information
- Web import feature (coming soon)

## Technical Architecture

### Firebase Integration
- **Firebase Auth**: Anonymous authentication for seamless user experience
- **Firebase Firestore**: Real-time database for flight and transfer data
- **Firestore Combine**: Reactive data binding with SwiftUI

### Data Models
- `IncomingFlight`: Complete flight arrival data with baggage tracking
- `OutgoingFlight`: Departure flight information with bag distribution
- `BaggageTransfer`: Transfer relationships between flights
- `WorkflowStats`: Operational statistics and metrics

### SwiftUI Architecture
- **MVVM Pattern**: Clean separation of data and presentation
- **Environment Objects**: Shared state management across views
- **Combine Integration**: Reactive data flow and updates
- **Modular Views**: Reusable components and consistent UI

## Setup Instructions

### 1. Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- Firebase project with Firestore enabled

### 2. Firebase Configuration
1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable **Authentication** with Anonymous sign-in
3. Enable **Firestore Database** in test mode
4. Download `GoogleService-Info.plist` and add to the project

### 3. Xcode Setup
1. Open `Transfers.xcodeproj` in Xcode
2. Add Firebase SDK via Swift Package Manager:
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Select: `FirebaseCore`, `FirebaseAuth`, `FirebaseFirestore`, `FirebaseFirestoreCombine-Community`
3. Add `GoogleService-Info.plist` to the project
4. Build and run

### 4. Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all users under any document
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

## Data Structure

### Collections
- `incomingFlights`: Arriving flights with baggage
- `outgoingFlights`: Departing flights receiving baggage  
- `baggageTransfers`: Transfer relationships between flights

### Key Fields
- **Timestamps**: All dates stored as Firestore timestamps
- **Status Tracking**: Collection and delivery times for workflow
- **Relationships**: Flight IDs linking transfers to flights
- **Metadata**: Creation and update timestamps

## Web Import Feature (Coming Soon)

The app includes a placeholder for web import functionality that will allow:
- Direct import from Manchester Airport website
- Multi-select flight choosing with visual feedback
- Batch import of arrivals and departures
- Existing flight detection and highlighting

**JavaScript Injection**: The same flight selection logic used in the iOS app can be implemented as a browser extension or service worker for the web application.

## Development Notes

### Real-time Updates
- Firestore listeners automatically sync data across devices
- UI updates immediately when data changes
- Offline support with automatic sync when reconnected

### Performance
- Efficient data queries with proper indexing
- Lazy loading of flight lists
- Optimized UI updates using SwiftUI's reactive system

### Security
- Anonymous authentication for simplicity
- Firestore security rules for data protection
- No sensitive data stored locally

## Future Enhancements

- [ ] Web import with JavaScript injection
- [ ] Push notifications for status changes
- [ ] PDF report generation
- [ ] Advanced filtering and search
- [ ] Multi-airport support
- [ ] Team collaboration features

## Support

For issues or questions:
1. Check Firebase Console for authentication and database status
2. Verify `GoogleService-Info.plist` is properly configured
3. Ensure Firestore security rules allow read/write access
4. Check Xcode console for detailed error messages

---

**Built with SwiftUI and Firebase** 🚀 