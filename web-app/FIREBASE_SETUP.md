# Firebase Setup Guide for Flight Transfers App

This guide will walk you through setting up Firebase for your Flight Transfers web app. Firebase provides real-time database, authentication, and hosting all in one platform.

## Step 1: Create Firebase Project

### 1.1 Go to Firebase Console
- Open your web browser and go to [https://console.firebase.google.com/](https://console.firebase.google.com/)
- Sign in with your Google account (or create one if you don't have one)

### 1.2 Create New Project
- Click "Create a project" or "Add project"
- Enter a project name: `flight-transfers-app` (or whatever you prefer)
- You can disable Google Analytics for now (we can add it later)
- Click "Create project"

## Step 2: Set Up Authentication

### 2.1 Enable Authentication
- In your Firebase project dashboard, click "Authentication" in the left sidebar
- Click "Get started"
- Go to the "Sign-in method" tab
- Enable "Email/Password" authentication
- Click "Save"

### 2.2 Create Admin User (Optional)
- Go to the "Users" tab
- Click "Add user"
- Enter an email and password for your admin account
- This will be your first user

## Step 3: Set Up Firestore Database

### 3.1 Create Database
- In the left sidebar, click "Firestore Database"
- Click "Create database"
- Choose "Start in test mode" for now (we'll add security rules later)
- Select a location close to your users (e.g., "europe-west1" for UK)
- Click "Done"

### 3.2 Set Up Security Rules (Later)
For now, we're using test mode. Later, you'll want to set up proper security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Step 4: Get Your Firebase Configuration

### 4.1 Get Project Settings
- In the Firebase console, click the gear icon next to "Project Overview"
- Select "Project settings"
- Scroll down to "Your apps" section
- Click the web icon (</>) to add a web app
- Give it a nickname like "Flight Transfers Web"
- Click "Register app"
- Copy the configuration object

### 4.2 Update Configuration File
Replace the placeholder values in `firebase-config.js` with your actual Firebase configuration:

```javascript
export const firebaseConfig = {
  apiKey: "your-actual-api-key",
  authDomain: "your-project-id.firebaseapp.com",
  projectId: "your-actual-project-id",
  storageBucket: "your-project-id.appspot.com",
  messagingSenderId: "your-actual-messaging-sender-id",
  appId: "your-actual-app-id"
};
```

## Step 5: Install Dependencies

### 5.1 Install Firebase SDK
Run this command in your project directory:

```bash
cd web-app/frontend
npm install firebase
```

### 5.2 Verify Installation
Check that Firebase is listed in your `package.json` dependencies.

## Step 6: Test Your Setup

### 6.1 Start the Development Server
```bash
cd web-app/frontend
npm run dev
```

### 6.2 Test Authentication
- Open your app in the browser
- Try to register a new user
- Check the Firebase console to see if the user appears in Authentication

### 6.3 Test Database
- Try to create a flight
- Check the Firebase console to see if the data appears in Firestore

## Step 7: Set Up Hosting (Optional)

### 7.1 Install Firebase CLI
```bash
npm install -g firebase-tools
```

### 7.2 Login to Firebase
```bash
firebase login
```

### 7.3 Initialize Hosting
```bash
firebase init hosting
```

Follow the prompts:
- Select your project
- Use `web-app/frontend/dist` as your public directory
- Configure as a single-page app: Yes
- Don't overwrite index.html: No

### 7.4 Deploy
```bash
npm run build
firebase deploy
```

## Step 8: Security Rules (Important!)

### 8.1 Basic Security Rules
Once your app is working, update your Firestore security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Flight data - authenticated users can read/write
    match /incomingFlights/{flightId} {
      allow read, write: if request.auth != null;
    }
    
    match /outgoingFlights/{flightId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### 8.2 Apply Rules
- Go to Firestore Database in Firebase console
- Click "Rules" tab
- Replace the rules with the ones above
- Click "Publish"

## Troubleshooting

### Common Issues

1. **"Firebase not initialized" error**
   - Make sure you've updated `firebase-config.js` with your actual configuration
   - Check that the config object is being imported correctly

2. **"Permission denied" error**
   - Check your Firestore security rules
   - Make sure you're authenticated

3. **"Module not found" error**
   - Run `npm install` to install dependencies
   - Check that Firebase is in your package.json

4. **Authentication not working**
   - Check that Email/Password authentication is enabled in Firebase console
   - Verify your Firebase config is correct

### Getting Help

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firebase Console](https://console.firebase.google.com/)
- [Firebase Support](https://firebase.google.com/support)

## Next Steps

Once Firebase is set up:

1. **Test the app** - Make sure you can create and view flights
2. **Set up security rules** - Protect your data
3. **Add more features** - Implement user roles, reports, etc.
4. **Deploy to production** - Use Firebase Hosting
5. **Set up monitoring** - Enable Firebase Analytics

## Cost Considerations

Firebase has a generous free tier:
- **Firestore**: 1GB storage, 50,000 reads/day, 20,000 writes/day
- **Authentication**: 10,000 users
- **Hosting**: 10GB storage, 360MB/day transfer

For most small to medium operations, the free tier should be sufficient. Monitor your usage in the Firebase console. 