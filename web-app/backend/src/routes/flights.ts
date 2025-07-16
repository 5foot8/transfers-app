import express from 'express';

const router = express.Router();

// Mock data for testing
let flights = [
  {
    id: '1',
    flightCode: 'AA123',
    origin: 'JFK',
    destination: 'LAX',
    date: '2024-01-15',
    scheduledTime: '10:00',
    status: 'scheduled',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: '2',
    flightCode: 'UA456',
    origin: 'LAX',
    destination: 'ORD',
    date: '2024-01-15',
    scheduledTime: '14:30',
    status: 'departed',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  }
];

// Get all flights
router.get('/', (req, res) => {
  res.json(flights);
});

// Get flight by ID
router.get('/:id', (req, res) => {
  const flight = flights.find(f => f.id === req.params.id);
  if (!flight) {
    return res.status(404).json({ error: 'Flight not found' });
  }
  res.json(flight);
});

// Create flight
router.post('/', (req, res) => {
  const newFlight = {
    id: Date.now().toString(),
    ...req.body,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
  flights.push(newFlight);
  res.status(201).json(newFlight);
});

// Update flight
router.put('/:id', (req, res) => {
  const index = flights.findIndex(f => f.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Flight not found' });
  }
  flights[index] = {
    ...flights[index],
    ...req.body,
    updatedAt: new Date().toISOString()
  };
  res.json(flights[index]);
});

// Delete flight
router.delete('/:id', (req, res) => {
  const index = flights.findIndex(f => f.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Flight not found' });
  }
  flights.splice(index, 1);
  res.status(204).send();
});

export { router as flightsRouter }; 