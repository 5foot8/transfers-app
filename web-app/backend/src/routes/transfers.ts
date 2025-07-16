import express from 'express';

const router = express.Router();

// Mock data for testing
let transfers = [
  {
    id: '1',
    passengerName: 'John Doe',
    incomingFlightCode: 'AA123',
    outgoingFlightCode: 'UA456',
    transferDate: '2024-01-15',
    status: 'pending',
    notes: 'VIP passenger',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: '2',
    passengerName: 'Jane Smith',
    incomingFlightCode: 'DL789',
    outgoingFlightCode: 'AA123',
    transferDate: '2024-01-15',
    status: 'completed',
    notes: 'Standard transfer',
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  }
];

// Get all transfers
router.get('/', (req, res) => {
  res.json(transfers);
});

// Get transfer by ID
router.get('/:id', (req, res) => {
  const transfer = transfers.find(t => t.id === req.params.id);
  if (!transfer) {
    return res.status(404).json({ error: 'Transfer not found' });
  }
  res.json(transfer);
});

// Create transfer
router.post('/', (req, res) => {
  const newTransfer = {
    id: Date.now().toString(),
    ...req.body,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
  transfers.push(newTransfer);
  res.status(201).json(newTransfer);
});

// Update transfer
router.put('/:id', (req, res) => {
  const index = transfers.findIndex(t => t.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Transfer not found' });
  }
  transfers[index] = {
    ...transfers[index],
    ...req.body,
    updatedAt: new Date().toISOString()
  };
  res.json(transfers[index]);
});

// Delete transfer
router.delete('/:id', (req, res) => {
  const index = transfers.findIndex(t => t.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Transfer not found' });
  }
  transfers.splice(index, 1);
  res.status(204).send();
});

export { router as transfersRouter }; 