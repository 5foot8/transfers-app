import express from 'express';

const router = express.Router();

// Mock data for testing
let workflows = [
  {
    id: '1',
    name: 'Standard Transfer Process',
    description: 'Standard workflow for passenger transfers',
    status: 'active',
    priority: 'medium',
    steps: [
      { name: 'Flight Arrival', description: 'Monitor incoming flight', order: 1 },
      { name: 'Passenger Check-in', description: 'Verify passenger details', order: 2 },
      { name: 'Baggage Transfer', description: 'Transfer baggage to outgoing flight', order: 3 }
    ],
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    lastRun: new Date().toISOString()
  },
  {
    id: '2',
    name: 'VIP Transfer Process',
    description: 'Enhanced workflow for VIP passengers',
    status: 'active',
    priority: 'high',
    steps: [
      { name: 'VIP Arrival', description: 'Special handling for VIP arrival', order: 1 },
      { name: 'Concierge Service', description: 'Provide concierge assistance', order: 2 },
      { name: 'Priority Transfer', description: 'Priority baggage and passenger transfer', order: 3 }
    ],
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    lastRun: new Date().toISOString()
  }
];

// Get all workflows
router.get('/', (req, res) => {
  res.json(workflows);
});

// Get workflow by ID
router.get('/:id', (req, res) => {
  const workflow = workflows.find(w => w.id === req.params.id);
  if (!workflow) {
    return res.status(404).json({ error: 'Workflow not found' });
  }
  res.json(workflow);
});

// Create workflow
router.post('/', (req, res) => {
  const newWorkflow = {
    id: Date.now().toString(),
    ...req.body,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    lastRun: null
  };
  workflows.push(newWorkflow);
  res.status(201).json(newWorkflow);
});

// Update workflow
router.put('/:id', (req, res) => {
  const index = workflows.findIndex(w => w.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Workflow not found' });
  }
  workflows[index] = {
    ...workflows[index],
    ...req.body,
    updatedAt: new Date().toISOString()
  };
  res.json(workflows[index]);
});

// Delete workflow
router.delete('/:id', (req, res) => {
  const index = workflows.findIndex(w => w.id === req.params.id);
  if (index === -1) {
    return res.status(404).json({ error: 'Workflow not found' });
  }
  workflows.splice(index, 1);
  res.status(204).send();
});

// Get workflow stats
router.get('/stats', (req, res) => {
  const activeWorkflows = workflows.filter(w => w.status === 'active').length;
  const completedWorkflows = workflows.filter(w => w.status === 'completed').length;
  const pausedWorkflows = workflows.filter(w => w.status === 'paused').length;
  
  res.json({
    activeWorkflows,
    completedWorkflows,
    pausedWorkflows,
    totalWorkflows: workflows.length
  });
});

export { router as workflowRouter }; 