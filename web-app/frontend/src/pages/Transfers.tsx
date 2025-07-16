import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  PlusIcon, 
  PencilIcon, 
  TrashIcon,
  ArrowPathIcon,
  ArchiveBoxIcon,
  PaperAirplaneIcon
} from '@heroicons/react/24/outline';
import { 
  getIncomingFlights, 
  getOutgoingFlights, 
  getBaggageTransfers,
  createBaggageTransfer,
  updateBaggageTransfer,
  deleteBaggageTransfer,
  IncomingFlight,
  OutgoingFlight
} from '../services/api';

const Transfers: React.FC = () => {
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState(false);
  const [editingTransfer, setEditingTransfer] = useState<any>(null);
  
  const queryClient = useQueryClient();

  const { data: incomingFlights, isLoading: incomingLoading } = useQuery({
    queryKey: ['incomingFlights'],
    queryFn: getIncomingFlights,
  });

  const { data: outgoingFlights, isLoading: outgoingLoading } = useQuery({
    queryKey: ['outgoingFlights'],
    queryFn: getOutgoingFlights,
  });

  const { data: baggageTransfers, isLoading: transfersLoading } = useQuery({
    queryKey: ['baggageTransfers'],
    queryFn: getBaggageTransfers,
  });

  // Sort flights by scheduled time
  const sortedIncomingFlights = incomingFlights?.sort((a, b) => 
    new Date(a.scheduledTime).getTime() - new Date(b.scheduledTime).getTime()
  ) || [];

  const sortedOutgoingFlights = outgoingFlights?.sort((a, b) => 
    new Date(a.scheduledTime).getTime() - new Date(b.scheduledTime).getTime()
  ) || [];

  const createTransferMutation = useMutation({
    mutationFn: createBaggageTransfer,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['baggageTransfers'] });
      setShowCreateModal(false);
    },
    onError: (error) => {
      console.error('Error creating transfer:', error);
      alert('Failed to create transfer. Please check the console for details.');
    },
  });

  const updateTransferMutation = useMutation({
    mutationFn: ({ id, updates }: { id: string; updates: any }) => updateBaggageTransfer(id, updates),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['baggageTransfers'] });
      setShowEditModal(false);
      setEditingTransfer(null);
    },
    onError: (error) => {
      console.error('Error updating transfer:', error);
      alert('Failed to update transfer. Please check the console for details.');
    },
  });

  const deleteTransferMutation = useMutation({
    mutationFn: deleteBaggageTransfer,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['baggageTransfers'] });
    },
    onError: (error) => {
      console.error('Error deleting transfer:', error);
      alert('Failed to delete transfer. Please check the console for details.');
    },
  });

  const handleCreateSubmit = (formData: any) => {
    console.log('Submitting transfer form data:', formData);
    
    if (!formData.incomingFlightId || !formData.outgoingFlightId || !formData.bagCount) {
      alert('Please fill in all required fields');
      return;
    }
    
    createTransferMutation.mutate({
      incomingFlightId: formData.incomingFlightId,
      outgoingFlightId: formData.outgoingFlightId,
      bagCount: parseInt(formData.bagCount),
      isMAGTransfer: formData.isMAGTransfer,
    });
  };

  const handleEditSubmit = (formData: any) => {
    if (!editingTransfer) return;
    
    updateTransferMutation.mutate({
      id: editingTransfer.id,
      updates: {
        bagCount: parseInt(formData.bagCount),
        isMAGTransfer: formData.isMAGTransfer,
      }
    });
  };

  const handleDelete = (transfer: any) => {
    if (window.confirm(`Are you sure you want to delete this transfer? This will remove ${transfer.bagCount} bags from ${transfer.incomingFlight?.flightNumber} to ${transfer.outgoingFlight?.flightNumber}.`)) {
      deleteTransferMutation.mutate(transfer.id);
    }
  };

  const handleEdit = (transfer: any) => {
    setEditingTransfer(transfer);
    setShowEditModal(true);
  };

  const getIncomingFlight = (id: string) => {
    return sortedIncomingFlights.find(flight => flight.id === id);
  };

  const getOutgoingFlight = (id: string) => {
    return sortedOutgoingFlights.find(flight => flight.id === id);
  };

  // Group transfers by incoming flight
  const groupedTransfers = baggageTransfers?.reduce((groups: any, transfer) => {
    const incomingFlight = getIncomingFlight(transfer.incomingFlightId);
    const outgoingFlight = getOutgoingFlight(transfer.outgoingFlightId);
    
    if (!incomingFlight) return groups;
    
    const key = transfer.incomingFlightId;
    if (!groups[key]) {
      groups[key] = {
        incomingFlight,
        transfers: [],
        totalBags: 0
      };
    }
    
    groups[key].transfers.push({
      ...transfer,
      outgoingFlight
    });
    groups[key].totalBags += transfer.bagCount || 0;
    
    return groups;
  }, {}) || {};

  if (incomingLoading || outgoingLoading || transfersLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-2xl font-semibold text-gray-900">Baggage Transfers</h1>
          <p className="mt-1 text-sm text-gray-500">
            Manage baggage transfers between incoming and outgoing flights
          </p>
        </div>
        <button
          onClick={() => {
            setEditingTransfer(null);
            setShowCreateModal(true);
          }}
          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
        >
          <PlusIcon className="h-4 w-4 mr-2" />
          Create Transfer
        </button>
      </div>

      {/* Transfer Statistics */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-4">
        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <ArchiveBoxIcon className="h-6 w-6 text-gray-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Incoming Flights
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {Object.keys(groupedTransfers).length}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <ArchiveBoxIcon className="h-6 w-6 text-gray-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Total Transfers
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {baggageTransfers?.length || 0}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <ArchiveBoxIcon className="h-6 w-6 text-gray-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Total Bags
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {baggageTransfers?.reduce((total, transfer) => total + (transfer.bagCount || 0), 0) || 0}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-white overflow-hidden shadow rounded-lg">
          <div className="p-5">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <ArrowPathIcon className="h-6 w-6 text-gray-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    MAG Transfers
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {baggageTransfers?.filter(transfer => transfer.isMAGTransfer).length || 0}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Transfers List - Grouped by Incoming Flight */}
      <div className="space-y-4">
        {Object.keys(groupedTransfers).length > 0 ? (
          Object.values(groupedTransfers).map((group: any) => (
            <div key={group.incomingFlight.id} className="bg-white shadow rounded-lg">
              <div className="px-4 py-4 sm:px-6 border-b border-gray-200">
                <div className="flex items-center justify-between">
                  <div className="flex items-center">
                    <PaperAirplaneIcon className="h-5 w-5 text-blue-500 mr-3" />
                    <div>
                      <h3 className="text-lg font-medium text-gray-900">
                        {group.incomingFlight.flightNumber}
                      </h3>
                      <p className="text-sm text-gray-500">
                        {group.incomingFlight.origin} → Terminal {group.incomingFlight.terminal}
                      </p>
                      <p className="text-xs text-gray-400">
                        {group.incomingFlight.carousel && `Carousel ${group.incomingFlight.carousel}`}
                        {group.incomingFlight.bagAvailableTime && ` • Available ${group.incomingFlight.bagAvailableTime.toLocaleTimeString()}`}
                      </p>
                    </div>
                  </div>
                  <div className="text-right">
                    <p className="text-sm font-medium text-gray-900">
                      {group.totalBags} total bags
                    </p>
                    <p className="text-sm text-gray-500">
                      {group.transfers.length} destinations
                    </p>
                  </div>
                </div>
              </div>
              
              <div className="divide-y divide-gray-200">
                {group.transfers.map((transfer: any) => (
                  <div key={transfer.id} className="px-4 py-3 sm:px-6">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <ArrowPathIcon className="h-4 w-4 text-gray-400 mr-3" />
                        <div>
                          <div className="flex items-center space-x-2">
                            <span className="text-sm font-medium text-gray-900">→</span>
                            <span className="text-sm font-medium text-gray-900">
                              {transfer.outgoingFlight?.flightNumber}
                            </span>
                          </div>
                          <p className="text-sm text-gray-500">
                            Terminal {transfer.outgoingFlight?.terminal} → {transfer.outgoingFlight?.destination}
                          </p>
                          <p className="text-xs text-gray-400">
                            {transfer.bagCount} bags
                            {transfer.isMAGTransfer && ' • MAG Transfer'}
                            {transfer.createdAt && ` • Created ${new Date(transfer.createdAt.toDate()).toLocaleString()}`}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center space-x-2">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                          transfer.isMAGTransfer 
                            ? 'bg-green-100 text-green-800'
                            : 'bg-blue-100 text-blue-800'
                        }`}>
                          {transfer.isMAGTransfer ? 'MAG' : 'Standard'}
                        </span>
                        <button
                          onClick={() => handleEdit(transfer)}
                          className="text-gray-400 hover:text-gray-600"
                          title="Edit transfer"
                        >
                          <PencilIcon className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => handleDelete(transfer)}
                          className="text-gray-400 hover:text-red-600"
                          title="Delete transfer"
                        >
                          <TrashIcon className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          ))
        ) : (
          <div className="bg-white shadow rounded-lg">
            <div className="px-4 py-8 text-center text-gray-500">
              No baggage transfers found
            </div>
          </div>
        )}
      </div>

      {/* Create Transfer Modal */}
      {showCreateModal && (
        <TransferModal
          title="Create Baggage Transfer"
          onSubmit={handleCreateSubmit}
          onClose={() => {
            setShowCreateModal(false);
            setEditingTransfer(null);
          }}
          incomingFlights={sortedIncomingFlights}
          outgoingFlights={sortedOutgoingFlights}
          initialData={null}
          baggageTransfers={baggageTransfers || []}
        />
      )}

      {/* Edit Transfer Modal */}
      {showEditModal && editingTransfer && (
        <EditTransferModal
          title="Edit Baggage Transfer"
          onSubmit={handleEditSubmit}
          onClose={() => {
            setShowEditModal(false);
            setEditingTransfer(null);
          }}
          transfer={editingTransfer}
        />
      )}
    </div>
  );
};

// Transfer Modal Component
interface TransferModalProps {
  title: string;
  onSubmit: (data: any) => void;
  onClose: () => void;
  incomingFlights: IncomingFlight[];
  outgoingFlights: OutgoingFlight[];
  initialData?: any;
  baggageTransfers: any[];
}

const TransferModal: React.FC<TransferModalProps> = ({ 
  title, 
  onSubmit, 
  onClose, 
  incomingFlights, 
  outgoingFlights, 
  initialData,
  baggageTransfers
}) => {
  const [formData, setFormData] = useState({
    incomingFlightId: initialData?.incomingFlightId || '',
    outgoingFlightId: initialData?.outgoingFlightId || '',
    bagCount: initialData?.bagCount || '',
    isMAGTransfer: initialData?.isMAGTransfer || false,
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(formData);
  };

  const selectedIncomingFlight = incomingFlights.find(f => f.id === formData.incomingFlightId);
  const selectedOutgoingFlight = outgoingFlights.find(f => f.id === formData.outgoingFlightId);

  // Check if this transfer already exists
  const existingTransfer = selectedIncomingFlight && selectedOutgoingFlight ? 
    baggageTransfers.find(transfer => 
      transfer.incomingFlightId === formData.incomingFlightId && 
      transfer.outgoingFlightId === formData.outgoingFlightId
    ) : null;

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div className="mt-3">
          <h3 className="text-lg font-medium text-gray-900 mb-4">{title}</h3>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">Incoming Flight</label>
              <select
                required
                value={formData.incomingFlightId}
                onChange={(e) => setFormData({ ...formData, incomingFlightId: e.target.value })}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="">Select incoming flight</option>
                {incomingFlights.map((flight) => (
                  <option key={flight.id} value={flight.id}>
                    {flight.flightNumber} - {flight.origin} → Terminal {flight.terminal}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">Outgoing Flight</label>
              <select
                required
                value={formData.outgoingFlightId}
                onChange={(e) => setFormData({ ...formData, outgoingFlightId: e.target.value })}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
              >
                <option value="">Select outgoing flight</option>
                {outgoingFlights.map((flight) => (
                  <option key={flight.id} value={flight.id}>
                    {flight.flightNumber} - Terminal {flight.terminal} → {flight.destination}
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700">Number of Bags</label>
              <input
                type="number"
                required
                min="1"
                value={formData.bagCount}
                onChange={(e) => setFormData({ ...formData, bagCount: e.target.value })}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
              />
            </div>

            <div className="flex items-center">
              <input
                type="checkbox"
                checked={formData.isMAGTransfer}
                onChange={(e) => setFormData({ ...formData, isMAGTransfer: e.target.checked })}
                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label className="ml-2 block text-sm text-gray-900">MAG Transfer (Same Terminal)</label>
            </div>

            {/* Transfer Preview */}
            {selectedIncomingFlight && selectedOutgoingFlight && (
              <div className="bg-gray-50 p-3 rounded-md">
                <h4 className="text-sm font-medium text-gray-900 mb-2">Transfer Preview</h4>
                <div className="text-sm text-gray-600 space-y-1">
                  <p><strong>From:</strong> {selectedIncomingFlight.flightNumber} ({selectedIncomingFlight.origin})</p>
                  <p><strong>To:</strong> {selectedOutgoingFlight.flightNumber} ({selectedOutgoingFlight.destination})</p>
                  <p><strong>Bags:</strong> {formData.bagCount}</p>
                  <p><strong>Type:</strong> {formData.isMAGTransfer ? 'MAG Transfer' : 'Standard Transfer'}</p>
                  {existingTransfer && (
                    <p className="text-orange-600 text-xs">
                      ⚠️ Transfer already exists with {existingTransfer.bagCount} bags
                    </p>
                  )}
                </div>
              </div>
            )}

            <div className="flex justify-end space-x-3">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={!!existingTransfer}
                className={`px-4 py-2 text-sm font-medium text-white border border-transparent rounded-md ${
                  existingTransfer 
                    ? 'bg-gray-400 cursor-not-allowed'
                    : 'bg-blue-600 hover:bg-blue-700'
                }`}
              >
                {existingTransfer ? 'Transfer Exists' : 'Create Transfer'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

// Edit Transfer Modal Component
interface EditTransferModalProps {
  title: string;
  onSubmit: (data: any) => void;
  onClose: () => void;
  transfer: any;
}

const EditTransferModal: React.FC<EditTransferModalProps> = ({ 
  title, 
  onSubmit, 
  onClose, 
  transfer 
}) => {
  const [formData, setFormData] = useState({
    bagCount: transfer.bagCount || '',
    isMAGTransfer: transfer.isMAGTransfer || false,
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(formData);
  };

  return (
    <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
      <div className="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
        <div className="mt-3">
          <h3 className="text-lg font-medium text-gray-900 mb-4">{title}</h3>
          
          {/* Transfer Info */}
          <div className="bg-gray-50 p-3 rounded-md mb-4">
            <h4 className="text-sm font-medium text-gray-900 mb-2">Transfer Information</h4>
            <div className="text-sm text-gray-600 space-y-1">
              <p><strong>From:</strong> {transfer.incomingFlight?.flightNumber} ({transfer.incomingFlight?.origin})</p>
              <p><strong>To:</strong> {transfer.outgoingFlight?.flightNumber} ({transfer.outgoingFlight?.destination})</p>
              <p><strong>Current Bags:</strong> {transfer.bagCount}</p>
              <p><strong>Type:</strong> {transfer.isMAGTransfer ? 'MAG Transfer' : 'Standard Transfer'}</p>
            </div>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">Number of Bags</label>
              <input
                type="number"
                required
                min="1"
                value={formData.bagCount}
                onChange={(e) => setFormData({ ...formData, bagCount: e.target.value })}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
              />
            </div>

            <div className="flex items-center">
              <input
                type="checkbox"
                checked={formData.isMAGTransfer}
                onChange={(e) => setFormData({ ...formData, isMAGTransfer: e.target.checked })}
                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label className="ml-2 block text-sm text-gray-900">MAG Transfer (Same Terminal)</label>
            </div>

            <div className="flex justify-end space-x-3">
              <button
                type="button"
                onClick={onClose}
                className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
              >
                Cancel
              </button>
              <button
                type="submit"
                className="px-4 py-2 text-sm font-medium text-white bg-blue-600 border border-transparent rounded-md hover:bg-blue-700"
              >
                Update Transfer
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Transfers; 