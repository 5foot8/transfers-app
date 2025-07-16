# Flight Transfers Frontend

A modern React web application for managing flight transfers and operations.

## Features

- **Dashboard**: Overview of flights, transfers, and workflow statistics
- **Flight Management**: CRUD operations for flight information
- **Transfer Management**: Manage passenger transfers between flights
- **Workflow Management**: Create and manage automated workflow processes
- **Authentication**: Firebase-based authentication system
- **Real-time Updates**: WebSocket integration for live updates
- **Responsive Design**: Mobile-friendly interface

## Tech Stack

- **React 18** with TypeScript
- **React Router** for navigation
- **React Query** for data fetching and caching
- **Tailwind CSS** for styling
- **Heroicons** for icons
- **Firebase** for authentication
- **Vite** for build tooling

## Getting Started

### Prerequisites

- Node.js 18+ 
- npm or yarn
- Backend API running (see backend README)

### Installation

1. Install dependencies:
```bash
npm install
```

2. Create environment file:
```bash
cp .env.example .env
```

3. Configure environment variables:
```env
# API Configuration
VITE_API_URL=http://localhost:3001/api

# Firebase Configuration (if using Firebase)
VITE_FIREBASE_API_KEY=your_firebase_api_key
VITE_FIREBASE_AUTH_DOMAIN=your_firebase_auth_domain
VITE_FIREBASE_PROJECT_ID=your_firebase_project_id
VITE_FIREBASE_STORAGE_BUCKET=your_firebase_storage_bucket
VITE_FIREBASE_MESSAGING_SENDER_ID=your_firebase_messaging_sender_id
VITE_FIREBASE_APP_ID=your_firebase_app_id
```

4. Start development server:
```bash
npm run dev
```

The application will be available at `http://localhost:5173`

## Project Structure

```
src/
├── components/          # Reusable UI components
│   ├── Layout.tsx      # Main layout with navigation
│   ├── FlightModal.tsx # Flight creation/editing modal
│   ├── TransferModal.tsx # Transfer creation/editing modal
│   └── WorkflowModal.tsx # Workflow creation/editing modal
├── contexts/           # React contexts
│   └── AuthContext.tsx # Authentication context
├── pages/              # Page components
│   ├── Dashboard.tsx   # Dashboard overview
│   ├── Flights.tsx     # Flight management
│   ├── Transfers.tsx   # Transfer management
│   ├── Workflow.tsx    # Workflow management
│   └── Login.tsx       # Authentication page
├── services/           # API and external services
│   ├── api.ts          # Backend API calls
│   ├── auth.ts         # Authentication service
│   └── firebase.ts     # Firebase configuration
├── App.tsx             # Main app component
├── main.tsx           # App entry point
└── index.css          # Global styles
```

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint

## Authentication

The app uses Firebase Authentication. Users need to be created in the Firebase Console or through the backend API.

## API Integration

The frontend communicates with the backend API for all data operations. Make sure the backend is running and accessible at the configured `VITE_API_URL`.

## Deployment

1. Build the application:
```bash
npm run build
```

2. Deploy the `dist` folder to your hosting provider (Vercel, Netlify, etc.)

## Contributing

1. Follow the existing code style
2. Add TypeScript types for new features
3. Test your changes thoroughly
4. Update documentation as needed 