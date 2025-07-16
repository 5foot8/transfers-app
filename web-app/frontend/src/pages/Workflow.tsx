import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { 
  ClockIcon, 
  CheckCircleIcon,
  ExclamationTriangleIcon,
  ArchiveBoxIcon,
  ArrowPathIcon,
  PaperAirplaneIcon
} from '@heroicons/react/24/outline';
import { 
  getIncomingFlights, 
  updateIncomingFlight,
  IncomingFlight
} from '../services/api';

const Workflow: React.FC = () => {
  const [selectedFlight, setSelectedFlight] = useState<IncomingFlight | null>(null);
  const [showCollectionModal, setShowCollectionModal] = useState(false);
  const [showDeliveryModal, setShowDeliveryModal] = useState(false);
  const [showScreeningModal, setShowScreeningModal] = useState(false);
  
  const queryClient = useQueryClient();

  const { data: incomingFlights, isLoading } = useQuery({
    queryKey: ['incomingFlights'],
    queryFn: getIncomingFlights,
  });

  console.log('Workflow - Total incoming flights loaded:', incomingFlights?.length || 0);
  console.log('Workflow - Incoming flights:', incomingFlights);

  const updateFlightMutation = useMutation({
    mutationFn: ({ id, updates }: { id: string; updates: Partial<IncomingFlight> }) => 
      updateIncomingFlight(id, updates),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['incomingFlights'] });
      setShowCollectionModal(false);
      setShowDeliveryModal(false);
      setShowScreeningModal(false);
      setSelectedFlight(null);
    },
    onError: (error) => {
      console.error('Error updating flight:', error);
      alert('Failed to update flight status. Please check the console for details.');
    },
  });

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const todayFlights = incomingFlights?.filter(flight => {
    const flightDate = new Date(flight.date);
    const flightDateOnly = new Date(flightDate.getFullYear(), flightDate.getMonth(), flightDate.getDate());
    const isToday = flightDateOnly.getTime() === today.getTime();
    console.log(`Workflow - Flight ${flight.flightNumber}: date=${flight.date}, flightDateOnly=${flightDateOnly}, today=${today}, isToday=${isToday}`);
    return isToday;
  }).sort((a, b) => new Date(a.scheduledTime).getTime() - new Date(b.scheduledTime).getTime()) || [];

  const pendingCollections = todayFlights.filter(flight => {
    const isReady = !flight.collectedTime && flight.bagAvailableTime && flight.bagAvailableTime <= new Date();
    console.log(`Workflow - Flight ${flight.flightNumber}: collectedTime=${flight.collectedTime}, bagAvailableTime=${flight.bagAvailableTime}, isReady=${isReady}`);
    return isReady;
  });

  const pendingDeliveries = todayFlights.filter(flight => 
    flight.collectedTime && !flight.deliveredTime
  );

  const completedFlights = todayFlights.filter(flight => 
    flight.deliveredTime
  );

  console.log('Workflow - Today flights:', todayFlights);
  console.log('Workflow - Pending collections:', pendingCollections);
  console.log('Workflow - Pending deliveries:', pendingDeliveries);
  console.log('Workflow - Completed flights:', completedFlights);

  const handleCollection = (flight: IncomingFlight) => {
    setSelectedFlight(flight);
    setShowCollectionModal(true);
  };

  const handleDelivery = (flight: IncomingFlight) => {
    setSelectedFlight(flight);
    setShowDeliveryModal(true);
  };

  const handleScreening = (flight: IncomingFlight) => {
    setSelectedFlight(flight);
    setShowScreeningModal(true);
  };

  const handleCollectionSubmit = (formData: any) => {
    if (!selectedFlight) return;
    
    console.log('Collecting bags for flight:', selectedFlight.flightNumber, formData);
    
    updateFlightMutation.mutate({
      id: selectedFlight.id,
      updates: {
        collectedTime: new Date(),
        notes: formData.notes || selectedFlight.notes,
      }
    });
  };

  const handleDeliverySubmit = (formData: any) => {
    if (!selectedFlight) return;
    
    console.log('Delivering bags for flight:', selectedFlight.flightNumber, formData);
    
    const updates: Partial<IncomingFlight> = {
      deliveredTime: new Date(),
      notes: formData.notes || selectedFlight.notes,
    };

    // If there are screening bags, mark as delivered to screening
    if (selectedFlight.screeningBags && selectedFlight.screeningBags > 0) {
      updates.deliveredScreeningTime = new Date();
    } else {
      updates.deliveredNonScreeningTime = new Date();
    }
    
    updateFlightMutation.mutate({
      id: selectedFlight.id,
      updates
    });
  };

  const handleScreeningSubmit = (formData: any) => {
    if (!selectedFlight) return;
    
    console.log('Starting screening for flight:', selectedFlight.flightNumber, formData);
    
    updateFlightMutation.mutate({
      id: selectedFlight.id,
      updates: {
        screeningBags: parseInt(formData.screeningBags) || 0,
        screeningStartTime: new Date(),
        screeningEndTime: formData.screeningEndTime ? new Date(formData.screeningEndTime) : undefined,
        notes: formData.notes || selectedFlight.notes,
      }
    });
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">Baggage Workflow</h1>
        <p className="mt-1 text-sm text-gray-500">
          Manage baggage collection, screening, and delivery operations
        </p>
      </div>

      {/* Workflow Statistics */}
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
                    Today's Flights
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {todayFlights.length}
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
                <ClockIcon className="h-6 w-6 text-yellow-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Ready for Collection
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {pendingCollections.length}
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
                <ArrowPathIcon className="h-6 w-6 text-orange-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Pending Delivery
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {pendingDeliveries.length}
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
                <CheckCircleIcon className="h-6 w-6 text-green-400" />
              </div>
              <div className="ml-5 w-0 flex-1">
                <dl>
                  <dt className="text-sm font-medium text-gray-500 truncate">
                    Completed
                  </dt>
                  <dd className="text-lg font-medium text-gray-900">
                    {completedFlights.length}
                  </dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Ready for Collection */}
      <div className="bg-white shadow rounded-lg">
        <div className="px-4 py-5 sm:p-6">
          <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">
            Bags Ready for Collection
          </h3>
          <div className="flow-root">
            <ul className="-my-5 divide-y divide-gray-200">
              {pendingCollections.length > 0 ? (
                pendingCollections.map((flight) => (
                  <li key={flight.id} className="py-4">
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
                            {flight.bagAvailableTime && ` • Available since ${flight.bagAvailableTime.toLocaleTimeString()}`}
                            {flight.outgoingLinks.length > 0 && ` • ${flight.outgoingLinks.reduce((sum, link) => sum + link.bagCount, 0)} bags`}
                          </p>
                        </div>
                      </div>
                      <div className="flex space-x-2">
                        <button
                          onClick={() => handleCollection(flight)}
                          className="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700"
                        >
                          Collect
                        </button>
                        <button
                          onClick={() => handleScreening(flight)}
                          className="inline-flex items-center px-3 py-1 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                        >
                          Screening
                        </button>
                      </div>
                    </div>
                  </li>
                ))
              ) : (
                <li className="py-4 text-center text-gray-500">
                  No bags ready for collection
                </li>
              )}
            </ul>
          </div>
        </div>
      </div>

      {/* Pending Delivery */}
      <div className="bg-white shadow rounded-lg">
        <div className="px-4 py-5 sm:p-6">
          <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">
            Bags Pending Delivery
          </h3>
          <div className="flow-root">
            <ul className="-my-5 divide-y divide-gray-200">
              {pendingDeliveries.length > 0 ? (
                pendingDeliveries.map((flight) => (
                  <li key={flight.id} className="py-4">
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
                            Collected at {flight.collectedTime?.toLocaleTimeString()}
                            {flight.screeningBags && flight.screeningBags > 0 && ` • ${flight.screeningBags} bags in screening`}
                            {flight.outgoingLinks.length > 0 && ` • ${flight.outgoingLinks.reduce((sum, link) => sum + link.bagCount, 0)} total bags`}
                          </p>
                        </div>
                      </div>
                      <button
                        onClick={() => handleDelivery(flight)}
                        className="inline-flex items-center px-3 py-1 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700"
                      >
                        Deliver
                      </button>
                    </div>
                  </li>
                ))
              ) : (
                <li className="py-4 text-center text-gray-500">
                  No bags pending delivery
                </li>
              )}
            </ul>
          </div>
        </div>
      </div>

      {/* Collection Modal */}
      {showCollectionModal && selectedFlight && (
        <WorkflowModal
          title="Collect Bags"
          onSubmit={handleCollectionSubmit}
          onClose={() => {
            setShowCollectionModal(false);
            setSelectedFlight(null);
          }}
          flight={selectedFlight}
          type="collection"
        />
      )}

      {/* Delivery Modal */}
      {showDeliveryModal && selectedFlight && (
        <WorkflowModal
          title="Deliver Bags"
          onSubmit={handleDeliverySubmit}
          onClose={() => {
            setShowDeliveryModal(false);
            setSelectedFlight(null);
          }}
          flight={selectedFlight}
          type="delivery"
        />
      )}

      {/* Screening Modal */}
      {showScreeningModal && selectedFlight && (
        <WorkflowModal
          title="Baggage Screening"
          onSubmit={handleScreeningSubmit}
          onClose={() => {
            setShowScreeningModal(false);
            setSelectedFlight(null);
          }}
          flight={selectedFlight}
          type="screening"
        />
      )}
    </div>
  );
};

// Workflow Modal Component
interface WorkflowModalProps {
  title: string;
  onSubmit: (data: any) => void;
  onClose: () => void;
  flight: IncomingFlight;
  type: 'collection' | 'delivery' | 'screening';
}

const WorkflowModal: React.FC<WorkflowModalProps> = ({ title, onSubmit, onClose, flight, type }) => {
  const [formData, setFormData] = useState({
    notes: '',
    screeningBags: flight.screeningBags || 0,
    screeningEndTime: '',
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
          
          {/* Flight Info */}
          <div className="bg-gray-50 p-3 rounded-md mb-4">
            <h4 className="text-sm font-medium text-gray-900 mb-2">Flight Information</h4>
            <div className="text-sm text-gray-600 space-y-1">
              <p><strong>Flight:</strong> {flight.flightNumber}</p>
              <p><strong>Origin:</strong> {flight.origin}</p>
              <p><strong>Terminal:</strong> {flight.terminal}</p>
              {flight.carousel && <p><strong>Carousel:</strong> {flight.carousel}</p>}
              {flight.outgoingLinks.length > 0 && (
                <p><strong>Total Bags:</strong> {flight.outgoingLinks.reduce((sum, link) => sum + link.bagCount, 0)}</p>
              )}
              {flight.collectedTime && (
                <p><strong>Collected:</strong> {flight.collectedTime.toLocaleTimeString()}</p>
              )}
              {flight.screeningBags && flight.screeningBags > 0 && (
                <p><strong>Screening Bags:</strong> {flight.screeningBags}</p>
              )}
            </div>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            {type === 'screening' && (
              <>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Bags for Screening</label>
                  <input
                    type="number"
                    min="0"
                    value={formData.screeningBags}
                    onChange={(e) => setFormData({ ...formData, screeningBags: parseInt(e.target.value) || 0 })}
                    className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700">Screening End Time (Optional)</label>
                  <input
                    type="datetime-local"
                    value={formData.screeningEndTime}
                    onChange={(e) => setFormData({ ...formData, screeningEndTime: e.target.value })}
                    className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                  />
                </div>
              </>
            )}

            <div>
              <label className="block text-sm font-medium text-gray-700">Notes</label>
              <textarea
                value={formData.notes}
                onChange={(e) => setFormData({ ...formData, notes: e.target.value })}
                rows={3}
                className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500"
                placeholder={`Add notes for ${type}...`}
              />
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
                className={`px-4 py-2 text-sm font-medium text-white border border-transparent rounded-md ${
                  type === 'collection' ? 'bg-blue-600 hover:bg-blue-700' :
                  type === 'delivery' ? 'bg-green-600 hover:bg-green-700' :
                  'bg-orange-600 hover:bg-orange-700'
                }`}
              >
                {type === 'collection' ? 'Collect' : type === 'delivery' ? 'Deliver' : 'Start Screening'}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default Workflow; 