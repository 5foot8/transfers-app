import React, { useState, useEffect } from 'react';
import { incomingFlightsService, outgoingFlightsService } from '../services/firebase';
import { authService } from '../services/auth';

const FirebaseTest: React.FC = () => {
  const [incomingFlights, setIncomingFlights] = useState<any[]>([]);
  const [outgoingFlights, setOutgoingFlights] = useState<any[]>([]);
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isSigningIn, setIsSigningIn] = useState(false);

  useEffect(() => {
    // Listen to auth state changes
    const unsubscribe = authService.onAuthStateChanged((user) => {
      setUser(user);
      setLoading(false);
    });

    return () => unsubscribe();
  }, []);

  useEffect(() => {
    if (user) {
      // Load flights when user is authenticated
      loadFlights();
    }
  }, [user]);

  const loadFlights = async () => {
    try {
      const [incoming, outgoing] = await Promise.all([
        incomingFlightsService.getAll(),
        outgoingFlightsService.getAll()
      ]);
      setIncomingFlights(incoming);
      setOutgoingFlights(outgoing);
    } catch (err: any) {
      setError(err.message);
    }
  };

  const createTestFlight = async () => {
    try {
      const testFlight = {
        flightNumber: 'TEST123',
        terminal: '1',
        origin: 'London (LHR)',
        scheduledTime: new Date(),
        cancelled: false,
        notes: 'Test flight',
        outgoingLinks: []
      };

      await incomingFlightsService.create(testFlight);
      await loadFlights(); // Reload the list
    } catch (err: any) {
      setError(err.message);
    }
  };

  const signIn = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setError('Please enter both email and password');
      return;
    }

    try {
      setIsSigningIn(true);
      setError(null);
      await authService.login(email, password);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsSigningIn(false);
    }
  };

  const signOut = async () => {
    try {
      await authService.logout();
    } catch (err: any) {
      setError(err.message);
    }
  };

  if (loading) {
    return <div className="p-4">Loading...</div>;
  }

  return (
    <div className="p-4 max-w-4xl mx-auto">
      <h1 className="text-2xl font-bold mb-4">Firebase Connection Test</h1>
      
      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          Error: {error}
        </div>
      )}

      <div className="mb-6">
        <h2 className="text-xl font-semibold mb-2">Authentication</h2>
        {user ? (
          <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded">
            <p>✅ Connected as: {user.email}</p>
            <button
              onClick={signOut}
              className="mt-2 bg-red-500 text-white px-4 py-2 rounded hover:bg-red-600"
            >
              Sign Out
            </button>
          </div>
        ) : (
          <div className="bg-yellow-100 border border-yellow-400 text-yellow-700 px-4 py-3 rounded p-4">
            <p className="mb-3">⚠️ Not authenticated</p>
            
            <form onSubmit={signIn} className="space-y-3">
              <div>
                <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-1">
                  Email:
                </label>
                <input
                  type="email"
                  id="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Enter your email"
                  required
                />
              </div>
              
              <div>
                <label htmlFor="password" className="block text-sm font-medium text-gray-700 mb-1">
                  Password:
                </label>
                <input
                  type="password"
                  id="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  placeholder="Enter your password"
                  required
                />
              </div>
              
              <button
                type="submit"
                disabled={isSigningIn}
                className="w-full bg-blue-500 text-white px-4 py-2 rounded hover:bg-blue-600 disabled:bg-gray-400 disabled:cursor-not-allowed"
              >
                {isSigningIn ? 'Signing In...' : 'Sign In'}
              </button>
            </form>
            
            <div className="mt-3 p-3 bg-blue-50 rounded text-sm">
              <p className="font-semibold mb-1">To create a test user:</p>
              <ol className="list-decimal list-inside space-y-1">
                <li>Go to <a href="https://console.firebase.google.com" target="_blank" rel="noopener noreferrer" className="text-blue-600 underline">Firebase Console</a></li>
                <li>Select your project</li>
                <li>Go to Authentication → Users</li>
                <li>Click "Add User"</li>
                <li>Enter email and password</li>
                <li>Use those credentials to sign in above</li>
              </ol>
            </div>
          </div>
        )}
      </div>

      {user && (
        <>
          <div className="mb-6">
            <h2 className="text-xl font-semibold mb-2">Database Test</h2>
            <button
              onClick={createTestFlight}
              className="bg-green-500 text-white px-4 py-2 rounded hover:bg-green-600"
            >
              Create Test Flight
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <h3 className="text-lg font-semibold mb-2">Incoming Flights ({incomingFlights.length})</h3>
              <div className="bg-gray-100 p-4 rounded max-h-64 overflow-y-auto">
                {incomingFlights.length === 0 ? (
                  <p className="text-gray-500">No incoming flights</p>
                ) : (
                  incomingFlights.map((flight) => (
                    <div key={flight.id} className="mb-2 p-2 bg-white rounded">
                      <p className="font-semibold">{flight.flightNumber}</p>
                      <p className="text-sm text-gray-600">
                        {flight.origin} - Terminal {flight.terminal}
                      </p>
                    </div>
                  ))
                )}
              </div>
            </div>

            <div>
              <h3 className="text-lg font-semibold mb-2">Outgoing Flights ({outgoingFlights.length})</h3>
              <div className="bg-gray-100 p-4 rounded max-h-64 overflow-y-auto">
                {outgoingFlights.length === 0 ? (
                  <p className="text-gray-500">No outgoing flights</p>
                ) : (
                  outgoingFlights.map((flight) => (
                    <div key={flight.id} className="mb-2 p-2 bg-white rounded">
                      <p className="font-semibold">{flight.flightNumber}</p>
                      <p className="text-sm text-gray-600">
                        {flight.destination} - Terminal {flight.terminal}
                      </p>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        </>
      )}

      <div className="mt-8 p-4 bg-blue-50 rounded">
        <h3 className="font-semibold mb-2">Next Steps:</h3>
        <ol className="list-decimal list-inside space-y-1 text-sm">
          <li>Create a user in Firebase Console (Authentication → Users → Add User)</li>
          <li>Try signing in with those credentials</li>
          <li>Test creating flights</li>
          <li>Check Firebase Console to see the data</li>
          <li>Once working, integrate with your main app</li>
        </ol>
      </div>
    </div>
  );
};

export default FirebaseTest; 