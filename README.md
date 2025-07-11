# Manchester Airport Transfers

A simple, intuitive iOS app designed to help the transfer team at Manchester Airport prioritize and manage passenger transfers efficiently.

## Features

### 🎯 **Priority-Based Management**
- Automatic sorting by priority level (Urgent → High → Medium → Low)
- Visual priority indicators with color-coded badges
- Smart filtering to focus on what matters most

### 📊 **Real-Time Dashboard**
- Live statistics showing pending, in-progress, and completed transfers
- Quick overview of next priority transfer
- Status tracking with visual indicators

### 🚀 **Quick Actions**
- One-tap status updates (Start → Complete)
- Swipe actions for quick management
- Instant search across flight numbers and routes

### 📱 **Modern iOS Design**
- Built with iOS 26 design principles
- Ultra-thin material backgrounds for elegant appearance
- Intuitive navigation and gestures

## Setup

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ target
- macOS 14.0+ for development

### Installation
1. Open `Transfers.xcodeproj` in Xcode
2. Select your development team in project settings
3. Build and run on your device or simulator

### First Launch
The app includes sample data to demonstrate functionality:
- BA1234: London Heathrow → Terminal 1 (VIP passengers)
- LH789: Frankfurt → Terminal 2
- EK456: Dubai → Terminal 3
- QR789: Doha → Terminal 1
- TK234: Istanbul → Terminal 2

## Usage

### Adding Transfers
1. Tap the "+" button in the top right
2. Fill in flight details (auto-complete for common routes)
3. Set priority level and passenger count
4. Add any special notes or requirements

### Managing Transfers
- **View Details**: Tap the info icon on any transfer
- **Update Status**: Use quick action buttons or edit mode
- **Search**: Use the search bar to find specific flights
- **Filter**: Tap status chips to filter by transfer status

### Priority System
- **Urgent**: Immediate attention required (red)
- **High**: Important transfers (orange)
- **Medium**: Standard priority (blue)
- **Low**: Non-critical transfers (gray)

## Data Sources

In the absence of direct API access, the app is designed to work with:
- Manual entry of transfer information
- Integration with Manchester Airport's information systems
- Real-time updates from transfer team members

## Architecture

- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Persistent data storage
- **iOS 26**: Latest design patterns and materials
- **MVVM**: Clean separation of concerns

## Support

For technical support or feature requests, contact the development team.

---

*Built for Manchester Airport Transfer Team* ✈️ 