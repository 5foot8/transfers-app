# Flight Transfers Web App

A modern web application for managing airport flight transfers, built with React, Node.js, and PostgreSQL. This web app provides the same functionality as the iOS app but accessible from any browser.

## Features

- **Flight Management**: Add, edit, and delete incoming and outgoing flights
- **Transfer Linking**: Connect incoming flights to outgoing flights with bag counts
- **Workflow Tracking**: Track collection, screening, and delivery status
- **Real-time Updates**: Live updates via WebSocket connections
- **User Authentication**: Role-based access control (Admin, Manager, Operator, Viewer)
- **Terminal Filtering**: Filter flights by terminal
- **Reports**: Generate PDF reports for daily operations
- **Priority Management**: View urgent flights and transfer chains

## Tech Stack

### Backend
- **Node.js** with Express
- **TypeScript** for type safety
- **PostgreSQL** with Prisma ORM
- **WebSocket** for real-time updates
- **JWT** for authentication
- **Zod** for validation

### Frontend
- **React 18** with TypeScript
- **Vite** for fast development
- **Tailwind CSS** for styling
- **React Query** for data fetching
- **React Router** for navigation
- **React Hook Form** for forms

## Quick Start

### Prerequisites
- Node.js 18+ 
- PostgreSQL 12+
- npm or yarn

### 1. Clone and Install

```bash
# Clone the repository
git clone <your-repo-url>
cd web-app

# Install all dependencies
npm run install:all
```

### 2. Database Setup

```bash
# Copy environment file
cd backend
cp env.example .env

# Edit .env with your database credentials
# DATABASE_URL="postgresql://username:password@localhost:5432/flight_transfers"

# Generate Prisma client
npm run db:generate

# Run database migrations
npm run db:migrate
```

### 3. Start Development Servers

```bash
# From the root directory
npm run dev
```

This will start:
- Backend API on http://localhost:3001
- Frontend on http://localhost:3000
- WebSocket server on ws://localhost:3001

### 4. Create Admin User

```bash
# Access the database directly or use Prisma Studio
npm run db:studio
```

Or create a user via the API:

```bash
curl -X POST http://localhost:3001/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@airport.com",
    "password": "admin123",
    "name": "Admin User",
    "role": "ADMIN"
  }'
```

## API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `GET /api/auth/me` - Get current user

### Flights
- `GET /api/flights/incoming` - Get incoming flights
- `POST /api/flights/incoming` - Create incoming flight
- `PUT /api/flights/incoming/:id` - Update incoming flight
- `DELETE /api/flights/incoming/:id` - Delete incoming flight
- `GET /api/flights/outgoing` - Get outgoing flights
- `POST /api/flights/outgoing` - Create outgoing flight
- `PUT /api/flights/outgoing/:id` - Update outgoing flight
- `DELETE /api/flights/outgoing/:id` - Delete outgoing flight

### Transfers
- `POST /api/transfers/link` - Link flights
- `DELETE /api/transfers/link/:id` - Unlink flights
- `PUT /api/transfers/bags/:id` - Update bag count
- `GET /api/transfers/summary` - Get transfer summary

### Workflow
- `PUT /api/workflow/collect/:flightId` - Mark bags collected
- `PUT /api/workflow/screen/:flightId` - Start screening
- `PUT /api/workflow/deliver/:flightId` - Mark bags delivered
- `GET /api/workflow/inbound` - Get inbound workflow status

## iOS App Integration

The web app is designed to work alongside the iOS app. To integrate:

1. **Update iOS App**: Modify the iOS app to use the web API instead of local storage
2. **Add API Client**: Create an API client in the iOS app
3. **Add Toggle**: Add a switch to toggle between local and web modes
4. **Sync Data**: Implement data synchronization between local and web storage

### iOS API Integration Example

```swift
// API Client
class FlightTransfersAPI {
    private let baseURL = "http://localhost:3001/api"
    private let token: String
    
    func fetchIncomingFlights() async throws -> [IncomingFlight] {
        let url = URL(string: "\(baseURL)/flights/incoming")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([IncomingFlight].self, from: data)
    }
    
    func createIncomingFlight(_ flight: IncomingFlight) async throws -> IncomingFlight {
        let url = URL(string: "\(baseURL)/flights/incoming")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(flight)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(IncomingFlight.self, from: data)
    }
}
```

## Deployment

### Backend Deployment (Railway/Render)

1. **Set up database**: Create PostgreSQL database
2. **Deploy backend**: Connect your GitHub repo to Railway/Render
3. **Set environment variables**:
   - `DATABASE_URL`
   - `JWT_SECRET`
   - `FRONTEND_URL`

### Frontend Deployment (Vercel)

1. **Deploy frontend**: Connect your GitHub repo to Vercel
2. **Set environment variables**:
   - `VITE_API_URL` (your backend URL)

### Production Checklist

- [ ] Set up SSL certificates
- [ ] Configure CORS properly
- [ ] Set strong JWT secret
- [ ] Enable rate limiting
- [ ] Set up monitoring/logging
- [ ] Configure backups
- [ ] Test WebSocket connections

## Development

### Project Structure

```
web-app/
├── backend/                 # Node.js API server
│   ├── src/
│   │   ├── routes/         # API routes
│   │   ├── websocket.ts    # WebSocket handler
│   │   └── index.ts        # Server entry point
│   ├── prisma/             # Database schema
│   └── package.json
├── frontend/               # React frontend
│   ├── src/
│   │   ├── components/     # React components
│   │   ├── pages/          # Page components
│   │   ├── contexts/       # React contexts
│   │   ├── hooks/          # Custom hooks
│   │   └── utils/          # Utility functions
│   └── package.json
└── package.json            # Root package.json
```

### Available Scripts

```bash
# Development
npm run dev                 # Start both frontend and backend
npm run dev:backend         # Start backend only
npm run dev:frontend        # Start frontend only

# Build
npm run build              # Build both frontend and backend
npm run build:backend      # Build backend only
npm run build:frontend     # Build frontend only

# Database
npm run db:migrate         # Run database migrations
npm run db:generate        # Generate Prisma client
npm run db:studio          # Open Prisma Studio
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details 