import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { 
  PaperAirplaneIcon, 
  ArrowPathIcon, 
  ClockIcon, 
  CheckCircleIcon,
  ExclamationTriangleIcon,
  ArchiveBoxIcon
} from '@heroicons/react/24/outline';
import { getIncomingFlights, getOutgoingFlights, getBaggageTransfers, getWorkflowStats } from '../services/api';

const Dashboard: React.FC = () => {
  const { data: incomingFlights, isLoading: incomingLoading } = useQuery({
    queryKey: ['incomingFlights'],
    queryFn: getIncomingFlights,
  });

  console.log('Total incoming flights loaded:', incomingFlights?.length || 0);
  console.log('Incoming flights:', incomingFlights);

  const { data: outgoingFlights, isLoading: outgoingLoading } = useQuery({
    queryKey: ['outgoingFlights'],
    queryFn: getOutgoingFlights,
  });

  const { data: baggageTransfers, isLoading: transfersLoading } = useQuery({
    queryKey: ['baggageTransfers'],
    queryFn: getBaggageTransfers,
  });

  const { data: workflowStats, isLoading: statsLoading } = useQuery({
    queryKey: ['workflow-stats'],
    queryFn: getWorkflowStats,
  });

  const isLoading = incomingLoading || outgoingLoading || transfersLoading || statsLoading;

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);

  const todayIncomingFlights = incomingFlights?.filter(flight => {
    const flightDate = new Date(flight.date);
    const flightDateOnly = new Date(flightDate.getFullYear(), flightDate.getMonth(), flightDate.getDate());
    const isToday = flightDateOnly.getTime() === today.getTime();
    console.log(`Flight ${flight.flightNumber}: date=${flight.date}, flightDateOnly=${flightDateOnly}, today=${today}, isToday=${isToday}`);
    return isToday;
  }).sort((a, b) => new Date(a.scheduledTime).getTime() - new Date(b.scheduledTime).getTime()) || [];

  const todayOutgoingFlights = outgoingFlights?.filter(flight => 
    flight.scheduledTime.getTime() >= today.getTime() && 
    flight.scheduledTime.getTime() < tomorrow.getTime()
  ).sort((a, b) => new Date(a.scheduledTime).getTime() - new Date(b.scheduledTime).getTime()) || [];

  const pendingCollections = todayIncomingFlights.filter(flight => 
    !flight.collectedTime && flight.bagAvailableTime && flight.bagAvailableTime <= new Date()
  );

  const pendingDeliveries = todayIncomingFlights.filter(flight => 
    flight.collectedTime && !flight.deliveredTime
  );

  const totalBagsToday = todayIncomingFlights.reduce((total, flight) => {
    return total + flight.outgoingLinks.reduce((sum, link) => sum + link.bagCount, 0);
  }, 0);

  const stats = [
    {
      name: 'Incoming Flights',
      value: todayIncomingFlights.length,
      icon: PaperAirplaneIcon,
      color: 'bg-blue-500',
      description: 'Flights with baggage today'
    },
    {
      name: 'Outgoing Flights',
      value: todayOutgoingFlights.length,
      icon: PaperAirplaneIcon,
      color: 'bg-green-500',
      description: 'Flights receiving baggage'
    },
    {
      name: 'Total Bags',
      value: totalBagsToday,
      icon: ArchiveBoxIcon,
      color: 'bg-purple-500',
      description: 'Bags being transferred'
    },
    {
      name: 'Pending Collections',
      value: pendingCollections.length,
      icon: ClockIcon,
      color: 'bg-yellow-500',
      description: 'Bags ready for collection'
    },
    {
      name: 'Pending Deliveries',
      value: pendingDeliveries.length,
      icon: ArrowPathIcon,
      color: 'bg-orange-500',
      description: 'Bags to be delivered'
    },
    {
      name: 'Active Workflows',
      value: workflowStats?.activeWorkflows || 0,
      icon: CheckCircleIcon,
      color: 'bg-indigo-500',
      description: 'Ongoing operations'
    },
  ];

  const recentIncomingFlights = todayIncomingFlights.slice(0, 5);
  const recentOutgoingFlights = todayOutgoingFlights.slice(0, 5);

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
        <h1 className="text-2xl font-semibold text-gray-900">Baggage Transfer Dashboard</h1>
        <p className="mt-1 text-sm text-gray-500">
          Overview of baggage transfer operations and workflow status
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {stats.map((stat) => (
          <div
            key={stat.name}
            className="bg-white overflow-hidden shadow rounded-lg"
          >
            <div className="p-5">
              <div className="flex items-center">
                <div className="flex-shrink-0">
                  <stat.icon className="h-6 w-6 text-gray-400" />
                </div>
                <div className="ml-5 w-0 flex-1">
                  <dl>
                    <dt className="text-sm font-medium text-gray-500 truncate">
                      {stat.name}
                    </dt>
                    <dd className="text-lg font-medium text-gray-900">
                      {stat.value}
                    </dd>
                    <dd className="text-xs text-gray-400">
                      {stat.description}
                    </dd>
                  </dl>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Recent Incoming Flights */}
        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg leading-6 font-medium text-gray-900">
              Recent Incoming Flights
            </h3>
            <div className="mt-4 flow-root">
              <ul className="-my-5 divide-y divide-gray-200">
                {recentIncomingFlights.length > 0 ? (
                  recentIncomingFlights.map((flight) => (
                    <li key={flight.id} className="py-4">
                      <div className="flex items-center space-x-4">
                        <div className="flex-shrink-0">
                          <PaperAirplaneIcon className="h-6 w-6 text-gray-400" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-gray-900 truncate">
                            {flight.flightNumber}
                          </p>
                          <p className="text-sm text-gray-500">
                            {flight.origin} → Terminal {flight.terminal}
                          </p>
                          <p className="text-xs text-gray-400">
                            {flight.carousel && `Carousel ${flight.carousel}`}
                            {flight.bagAvailableTime && ` • Available ${flight.bagAvailableTime.toLocaleTimeString()}`}
                          </p>
                        </div>
                        <div className="flex-shrink-0">
                          <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                            flight.collectedTime 
                              ? 'bg-green-100 text-green-800'
                              : flight.bagAvailableTime && flight.bagAvailableTime <= new Date()
                              ? 'bg-yellow-100 text-yellow-800'
                              : 'bg-gray-100 text-gray-800'
                          }`}>
                            {flight.collectedTime ? 'Collected' : flight.bagAvailableTime && flight.bagAvailableTime <= new Date() ? 'Ready' : 'Pending'}
                          </span>
                        </div>
                      </div>
                    </li>
                  ))
                ) : (
                  <li className="py-4 text-center text-gray-500">
                    No incoming flights today
                  </li>
                )}
              </ul>
            </div>
          </div>
        </div>

        {/* Recent Outgoing Flights */}
        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg leading-6 font-medium text-gray-900">
              Recent Outgoing Flights
            </h3>
            <div className="mt-4 flow-root">
              <ul className="-my-5 divide-y divide-gray-200">
                {recentOutgoingFlights.length > 0 ? (
                  recentOutgoingFlights.map((flight) => (
                    <li key={flight.id} className="py-4">
                      <div className="flex items-center space-x-4">
                        <div className="flex-shrink-0">
                          <PaperAirplaneIcon className="h-6 w-6 text-gray-400" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-gray-900 truncate">
                            {flight.flightNumber}
                          </p>
                          <p className="text-sm text-gray-500">
                            Terminal {flight.terminal} → {flight.destination}
                          </p>
                          <p className="text-xs text-gray-400">
                            {flight.scheduledTime.toLocaleTimeString()} • {Object.values(flight.bagsFromIncoming).reduce((a, b) => a + b, 0)} bags
                          </p>
                        </div>
                        <div className="flex-shrink-0">
                          <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                            flight.cancelled 
                              ? 'bg-red-100 text-red-800'
                              : flight.actualTime
                              ? 'bg-green-100 text-green-800'
                              : 'bg-blue-100 text-blue-800'
                          }`}>
                            {flight.cancelled ? 'Cancelled' : flight.actualTime ? 'Departed' : 'Scheduled'}
                          </span>
                        </div>
                      </div>
                    </li>
                  ))
                ) : (
                  <li className="py-4 text-center text-gray-500">
                    No outgoing flights today
                  </li>
                )}
              </ul>
            </div>
          </div>
        </div>
      </div>

      {/* Workflow Status */}
      <div className="bg-white shadow rounded-lg">
        <div className="px-4 py-5 sm:p-6">
          <h3 className="text-lg leading-6 font-medium text-gray-900">
            Workflow Status
          </h3>
          <div className="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
              <div className="flex items-center">
                <ClockIcon className="h-5 w-5 text-yellow-400" />
                <div className="ml-3">
                  <h4 className="text-sm font-medium text-yellow-800">
                    Bags Ready for Collection
                  </h4>
                  <p className="text-sm text-yellow-700">
                    {pendingCollections.length} flights have bags available
                  </p>
                </div>
              </div>
            </div>
            <div className="bg-orange-50 border border-orange-200 rounded-lg p-4">
              <div className="flex items-center">
                <ArrowPathIcon className="h-5 w-5 text-orange-400" />
                <div className="ml-3">
                  <h4 className="text-sm font-medium text-orange-800">
                    Bags Pending Delivery
                  </h4>
                  <p className="text-sm text-orange-700">
                    {pendingDeliveries.length} flights need bag delivery
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Dashboard; 