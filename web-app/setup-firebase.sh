#!/bin/bash

echo "🚀 Setting up Firebase for Flight Transfers App"
echo "================================================"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    echo "   Download from: https://nodejs.org/"
    exit 1
fi

echo "✅ Node.js version: $(node --version)"

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm first."
    exit 1
fi

echo "✅ npm version: $(npm --version)"

# Install dependencies
echo ""
echo "📦 Installing dependencies..."
cd frontend
npm install

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo ""
echo "🎯 Next Steps:"
echo "=============="
echo "1. Go to https://console.firebase.google.com/"
echo "2. Create a new project called 'flight-transfers-app'"
echo "3. Enable Authentication (Email/Password)"
echo "4. Create Firestore Database (test mode)"
echo "5. Add a web app to your project"
echo "6. Copy the Firebase config to firebase-config.js"
echo "7. Create a test user in Firebase Console"
echo "8. Run: npm run dev"
echo "9. Visit: http://localhost:3000/firebase-test"
echo ""
echo "📖 See FIREBASE_SETUP.md for detailed instructions"
echo ""
echo "🔧 To start the development server:"
echo "   cd frontend && npm run dev" 