import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  PlusIcon, 
  PencilIcon, 
  TrashIcon,
  PaperAirplaneIcon,
  ArchiveBoxIcon,
  ClockIcon,
  CheckCircleIcon
} from '@heroicons/react/24/outline';
import { 
  getIncomingFlights, 
  getOutgoingFlights, 
  createIncomingFlight, 
  createOutgoingFlight,
  updateIncomingFlight,
  updateOutgoingFlight,
  deleteIncomingFlight,
  deleteOutgoingFlight,
  IncomingFlight,
  OutgoingFlight
} from '../services/api';

const Flights: React.FC = () => {
  const [activeTab, setActiveTab] = useState<'incoming' | 'outgoing'>('incoming');
  const [showIncomingModal, setShowIncomingModal] = useState(false);
  const [showOutgoingModal, setShowOutgoingModal] = useState(false);
  const [editingFlight, setEditingFlight] = useState<IncomingFlight | OutgoingFlight | null>(null);
  
  const queryClient = useQueryClient();

  const { data: incomingFlights, isLoading: incomingLoading } = useQuery({
    queryKey: ['incomingFlights'],
    queryFn: getIncomingFlights,
  });

  const { data: outgoingFlights, isLoading: outgoingLoading } = useQuery({
    queryKey: ['outgoingFlights'],
    queryFn: getOutgoingFlights,
  });

  // Sort flights by scheduled time
  const sortedIncomingFlights = incomingFlights?.sort((a, b) => 
    new Date(a.scheduledTime).getTime() - new Date(b.scheduledTime).getTime()
  ) || [];

  const sortedOutgoingFlights = outgoingFlights?.sort((a, b) => 
    new Date(a.scheduledTime).getTime() - new Date(b.scheduledTime).getTime()
  ) || [];

  const createIncomingMutation = useMutation({
    mutationFn: createIncomingFlight,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['incomingFlights'] });
      setShowIncomingModal(false);
    },
  });

  const createOutgoingMutation = useMutation({
    mutationFn: createOutgoingFlight,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['outgoingFlights'] });
      setShowOutgoingModal(false);
    },
  });

  const updateIncomingMutation = useMutation({
    mutationFn: ({ id, updates }: { id: string; updates: Partial<IncomingFlight> }) => 
      updateIncomingFlight(id, updates),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['incomingFlights'] });
      setShowIncomingModal(false);
      setEditingFlight(null);
    },
  });

  const updateOutgoingMutation = useMutation({
    mutationFn: ({ id, updates }: { id: string; updates: Partial<OutgoingFlight> }) => 
      updateOutgoingFlight(id, updates),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['outgoingFlights'] });
      setShowOutgoingModal(false);
      setEditingFlight(null);
    },
  });

  const deleteIncomingMutation = useMutation({
    mutationFn: deleteIncomingFlight,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['incomingFlights'] });
    },
  });

  const deleteOutgoingMutation = useMutation({
    mutationFn: deleteOutgoingFlight,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['outgoingFlights'] });
    },
  });

  const handleIncomingSubmit = (formData: any) => {
    const flightData = {
      flightNumber: formData.flightNumber,
      terminal: formData.terminal,
      origin: formData.origin,
      scheduledTime: new Date(formData.scheduledTime),
      actualArrivalTime: formData.actualArrivalTime ? new Date(formData.actualArrivalTime) : undefined,
      expectedArrivalTime: formData.expectedArrivalTime ? new Date(formData.expectedArrivalTime) : undefined,
      bagAvailableTime: formData.bagAvailableTime ? new Date(formData.bagAvailableTime) : undefined,
      carousel: formData.carousel || undefined,
      notes: formData.notes || '',
      cancelled: formData.cancelled || false,
      outgoingLinks: [],
      date: new Date(formData.date),
    };

    if (editingFlight) {
      updateIncomingMutation.mutate({ id: editingFlight.id, updates: flightData });
    } else {
      createIncomingMutation.mutate(flightData);
    }
  };

  const handleOutgoingSubmit = (formData: any) => {
    const flightData = {
      flightNumber: formData.flightNumber,
      terminal: formData.terminal,
      destination: formData.destination,
      scheduledTime: new Date(formData.scheduledTime),
      actualTime: formData.actualTime ? new Date(formData.actualTime) : undefined,
      expectedTime: formData.expectedTime ? new Date(formData.expectedTime) : undefined,
      cancelled: formData.cancelled || false,
      bagsFromIncoming: {},
    };

    if (editingFlight) {
      updateOutgoingMutation.mutate({ id: editingFlight.id, updates: flightData });
    } else {
      createOutgoingMutation.mutate(flightData);
    }
  };

  const getStatusColor = (flight: IncomingFlight | OutgoingFlight) => {
    if ('cancelled' in flight && flight.cancelled) return 'bg-red-100 text-red-800';
    if ('collectedTime' in flight && flight.collectedTime) return 'bg-green-100 text-green-800';
    if ('bagAvailableTime' in flight && flight.bagAvailableTime && flight.bagAvailableTime <= new Date()) {
      return 'bg-yellow-100 text-yellow-800';
    }
    if ('actualTime' in flight && flight.actualTime) return 'bg-green-100 text-green-800';
    return 'bg-gray-100 text-gray-800';
  };

  const getStatusText = (flight: IncomingFlight | OutgoingFlight) => {
    if ('cancelled' in flight && flight.cancelled) return 'Cancelled';
    if ('collectedTime' in flight && flight.collectedTime) return 'Collected';
    if ('bagAvailableTime' in flight && flight.bagAvailableTime && flight.bagAvailableTime <= new Date()) {
      return 'Ready';
    }
    if ('actualTime' in flight && flight.actualTime) return 'Departed';
    return 'Scheduled';
  };

  if (incomingLoading || outgoingLoading) {
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
          <h1 className="text-2xl font-semibold text-gray-900">Baggage Transfer Flights</h1>
          <p className="mt-1 text-sm text-gray-500">
            Manage incoming and outgoing flights for baggage transfers
          </p>
        </div>
        <div className="flex space-x-3">
          <button
            onClick={() => {
              setEditingFlight(null);
              setShowIncomingModal(true);
            }}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700"
          >
            <PlusIcon className="h-4 w-4 mr-2" />
            Add Incoming Flight
          </button>
          <button
            onClick={() => {
              setEditingFlight(null);
              setShowOutgoingModal(true);
            }}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-green-600 hover:bg-green-700"
          >
            <PlusIcon className="h-4 w-4 mr-2" />
            Add Outgoing Flight
          </button>
        </div>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          <button
            onClick={() => setActiveTab('incoming')}
            className={`py-2 px-1 border-b-2 font-medium text-sm ${
              activeTab === 'incoming'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Incoming Flights ({sortedIncomingFlights.length || 0})
          </button>
          <button
            onClick={() => setActiveTab('outgoing')}
            className={`py-2 px-1 border-b-2 font-medium text-sm ${
              activeTab === 'outgoing'
                ? 'border-blue-500 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            }`}
          >
            Outgoing Flights ({sortedOutgoingFlights.length || 0})
          </button>
        </nav>
      </div>

      {/* Incoming Flights */}
      {activeTab === 'incoming' && (
        <div className="bg-white shadow overflow-hidden sm:rounded-md">
          <ul className="divide-y divide-gray-200">
            {sortedIncomingFlights.map((flight) => (
              <li key={flight.id}>
                <div className="px-4 py-4 sm:px-6">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <PaperAirplaneIcon className="h-5 w-5 text-gray-400 mr-3" />
                      <div>
                        <p className="text-sm font-medium text-gray-900">
                          {flight.flightNumber}
                        </p>
                        <p className="text-sm text-gray-500">
                          {flight.origin} → Terminal {flight.terminal}
                        </p>
                        <p className="text-xs text-gray-400">
                          {flight.carousel && `Carousel ${flight.carousel}`}
                          {flight.bagAvailableTime && ` • Available ${flight.bagAvailableTime.toLocaleTimeString()}`}
                          {flight.outgoingLinks.length > 0 && ` • ${flight.outgoingLinks.reduce((sum, link) => sum + link.bagCount, 0)} bags`}
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(flight)}`}>
                        {getStatusText(flight)}
                      </span>
                      <button
                        onClick={() => {
                          setEditingFlight(flight);
                          setShowIncomingModal(true);
                        }}
                        className="text-gray-400 hover:text-gray-600"
                      >
                        <PencilIcon className="h-4 w-4" />
                      </button>
                      <button
                        onClick={() => deleteIncomingMutation.mutate(flight.id)}
                        className="text-gray-400 hover:text-red-600"
                      >
                        <TrashIcon className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                </div>
              </li>
            ))}
            {sortedIncomingFlights.length === 0 && (
              <li className="px-4 py-8 text-center text-gray-500">
                No incoming flights found
              </li>
            )}
          </ul>
        </div>
      )}

      {/* Outgoing Flights */}
      {activeTab === 'outgoing' && (
        <div className="bg-white shadow overflow-hidden sm:rounded-md">
          <ul className="divide-y divide-gray-200">
            {sortedOutgoingFlights.map((flight) => (
              <li key={flight.id}>
                <div className="px-4 py-4 sm:px-6">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <PaperAirplaneIcon className="h-5 w-5 text-gray-400 mr-3" />
                      <div>
                        <p className="text-sm font-medium text-gray-900">
                          {flight.flightNumber}
                        </p>
                        <p className="text-sm text-gray-500">
                          Terminal {flight.terminal} → {flight.destination}
                        </p>
                        <p className="text-xs text-gray-400">
                          {flight.scheduledTime.toLocaleTimeString()} • {Object.values(flight.bagsFromIncoming).reduce((a, b) => a + b, 0)} bags
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getStatusColor(flight)}`}>
                        {getStatusText(flight)}
                      </span>
                      <button
                        onClick={() => {
                          setEditingFlight(flight);
                          setShowOutgoingModal(true);
                        }}
                        className="text-gray-400 hover:text-gray-600"
                      >
                        <PencilIcon className="h-4 w-4" />
                      </button>
                      <button
                        onClick={() => deleteOutgoingMutation.mutate(flight.id)}
                        className="text-gray-400 hover:text-red-600"
                      >
                        <TrashIcon className="h-4 w-4" />
                      </button>
                    </div>
                  </div>
                </div>
              </li>
            ))}
            {sortedOutgoingFlights.length === 0 && (
              <li className="px-4 py-8 text-center text-gray-500">
                No outgoing flights found
              </li>
            )}
          </ul>
        </div>
      )}

      {/* Incoming Flight Modal */}
      {showIncomingModal && (
        <FlightModal
          title={editingFlight ? 'Edit Incoming Flight' : 'Add Incoming Flight'}
          onSubmit={handleIncomingSubmit}
          onClose={() => {
            setShowIncomingModal(false);
            setEditingFlight(null);
          }}
          initialData={editingFlight as IncomingFlight}
          type="incoming"
        />
      )}

      {/* Outgoing Flight Modal */}
      {showOutgoingModal && (
        <FlightModal
          title={editingFlight ? 'Edit Outgoing Flight' : 'Add Outgoing Flight'}
          onSubmit={handleOutgoingSubmit}
          onClose={() => {
            setShowOutgoingModal(false);
            setEditingFlight(null);
          }}
          initialData={editingFlight as OutgoingFlight}
          type="outgoing"
        />
      )}
    </div>
  );
};

// Flight Modal Component
interface FlightModalProps {
  title: string;
  onSubmit: (data: any) => void;
  onClose: () => void;
  initialData?: IncomingFlight | OutgoingFlight;
  type: 'incoming' | 'outgoing';
}

const FlightModal: React.FC<FlightModalProps> = ({ title, onSubmit, onClose, initialData, type }) => {
  const [formData, setFormData] = useState({
    flightNumber: initialData?.flightNumber || '',
    terminal: initialData?.terminal || '',
    origin: type === 'incoming' ? (initialData as IncomingFlight)?.origin || '' : '',
    destination: type === 'outgoing' ? (initialData as OutgoingFlight)?.destination || '' : '',
    scheduledTime: initialData?.scheduledTime ? new Date(initialData.scheduledTime).toISOString().slice(0, 16) : '',
    actualArrivalTime: type === 'incoming' ? (initialData as IncomingFlight)?.actualArrivalTime ? new Date((initialData as IncomingFlight).actualArrivalTime!).toISOString().slice(0, 16) : '' : '',
    expectedArrivalTime: type === 'incoming' ? (initialData as IncomingFlight)?.expectedArrivalTime ? new Date((initialData as IncomingFlight).expectedArrivalTime!).toISOString().slice(0, 16) : '' : '',
    bagAvailableTime: type === 'incoming' ? (initialData as IncomingFlight)?.bagAvailableTime ? new Date((initialData as IncomingFlight).bagAvailableTime!).toISOString().slice(0, 16) : '' : '',
    carousel: type === 'incoming' ? (initialData as IncomingFlight)?.carousel || '' : '',
    actualTime: type === 'outgoing' ? (initialData as OutgoingFlight)?.actualTime ? new Date((initialData as OutgoingFlight).actualTime!).toISOString().slice(0, 16) : '' : '',
    expectedTime: type === 'outgoing' ? (initialData as OutgoingFlight)?.expectedTime ? new Date((initialData as OutgoingFlight).expectedTime!).toISOString().slice(0, 16) : '' : '',
    notes: type === 'incoming' ? (initialData as IncomingFlight)?.notes || '' : '',
    cancelled: initialData?.cancelled || false,
    date: type === 'incoming' ? (initialData as IncomingFlight)?.date ? new Date((initialData as IncomingFlight).date).toISOString().slice(0, 10) : new Date().toISOString().slice(0, 10) : '',
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
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700">Flight Number</label>
              <input
                type="text"
                required
                value={formData.flightNumber}
                onChange={(e) => setFormData({ ...formData, flightNumber: e.target.value })}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700">Terminal</label>
              <input
                type="text"
                required
                value={formData.terminal}
                onChange={(e) => setFormData({ ...formData, terminal: e.target.value })}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
              />
            </div>

            {type === 'incoming' && (
              <>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Origin</label>
                  <input
                    type="text"
                    required
                    value={formData.origin}
                    onChange={(e) => setFormData({ ...formData, origin: e.target.value })}
                    className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Date</label>
                  <input
                    type="date"
                    required
                    value={formData.date}
                    onChange={(e) => setFormData({ ...formData, date: e.target.value })}
                    className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Bag Available Time</label>
                  <input
                    type="datetime-local"
                    value={formData.bagAvailableTime}
                    onChange={(e) => setFormData({ ...formData, bagAvailableTime: e.target.value })}
                    className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Carousel</label>
                  <input
                    type="text"
                    value={formData.carousel}
                    onChange={(e) => setFormData({ ...formData, carousel: e.target.value })}
                    className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Notes</label>
                  <textarea
                    value={formData.notes}
                    onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                    rows={3}
                    className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
              </>
            )}

            {type === 'outgoing' && (
              <div>
                <label className="block text-sm font-medium text-gray-700">Destination</label>
                <input
                  type="text"
                  required
                  value={formData.destination}
                  onChange={(e) => setFormData({ ...formData, destination: e.target.value })}
                  className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                />
              </div>
            )}

            <div>
              <label className="block text-sm font-medium text-gray-700">Scheduled Time</label>
              <input
                type="datetime-local"
                required
                value={formData.scheduledTime}
                onChange={(e) => setFormData({ ...formData, scheduledTime: e.target.value })}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
              />
            </div>

            <div className="flex items-center">
              <input
                type="checkbox"
                checked={formData.cancelled}
                onChange={(e) => setFormData({ ...formData, cancelled: e.target.checked })}
                className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
              />
              <label className="ml-2 block text-sm text-gray-900">Cancelled</label>
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
                {initialData ? 'Update' : 'Create'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Flights; 