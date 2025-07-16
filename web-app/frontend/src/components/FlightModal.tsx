import React, { useState, useEffect } from 'react';
import { XMarkIcon } from '@heroicons/react/24/outline';

interface FlightModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (flightData: any) => void;
  flight?: any;
  isLoading?: boolean;
}

const FlightModal: React.FC<FlightModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
  flight,
  isLoading = false,
}) => {
  const [formData, setFormData] = useState({
    flightCode: '',
    origin: '',
    destination: '',
    date: '',
    scheduledTime: '',
    status: 'scheduled',
  });

  useEffect(() => {
    if (flight) {
      setFormData({
        flightCode: flight.flightCode || '',
        origin: flight.origin || '',
        destination: flight.destination || '',
        date: flight.date || '',
        scheduledTime: flight.scheduledTime || '',
        status: flight.status || 'scheduled',
      });
    } else {
      setFormData({
        flightCode: '',
        origin: '',
        destination: '',
        date: '',
        scheduledTime: '',
        status: 'scheduled',
      });
    }
  }, [flight]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(formData);
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value,
    }));
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      <div className="flex items-end justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:block sm:p-0">
        <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={onClose} />

        <span className="hidden sm:inline-block sm:align-middle sm:h-screen" aria-hidden="true">
          &#8203;
        </span>

        <div className="inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6">
          <div className="absolute top-0 right-0 pt-4 pr-4">
            <button
              type="button"
              className="bg-white rounded-md text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
              onClick={onClose}
            >
              <span className="sr-only">Close</span>
              <XMarkIcon className="h-6 w-6" />
            </button>
          </div>

          <div className="sm:flex sm:items-start">
            <div className="mt-3 text-center sm:mt-0 sm:text-left w-full">
              <h3 className="text-lg leading-6 font-medium text-gray-900">
                {flight ? 'Edit Flight' : 'Add New Flight'}
              </h3>
              <div className="mt-2">
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div>
                    <label htmlFor="flightCode" className="block text-sm font-medium text-gray-700">
                      Flight Code
                    </label>
                    <input
                      type="text"
                      name="flightCode"
                      id="flightCode"
                      required
                      value={formData.flightCode}
                      onChange={handleChange}
                      className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                      placeholder="e.g., AA123"
                    />
                  </div>

                  <div>
                    <label htmlFor="origin" className="block text-sm font-medium text-gray-700">
                      Origin
                    </label>
                    <input
                      type="text"
                      name="origin"
                      id="origin"
                      required
                      value={formData.origin}
                      onChange={handleChange}
                      className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                      placeholder="e.g., JFK"
                    />
                  </div>

                  <div>
                    <label htmlFor="destination" className="block text-sm font-medium text-gray-700">
                      Destination
                    </label>
                    <input
                      type="text"
                      name="destination"
                      id="destination"
                      required
                      value={formData.destination}
                      onChange={handleChange}
                      className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                      placeholder="e.g., LAX"
                    />
                  </div>

                  <div>
                    <label htmlFor="date" className="block text-sm font-medium text-gray-700">
                      Date
                    </label>
                    <input
                      type="date"
                      name="date"
                      id="date"
                      required
                      value={formData.date}
                      onChange={handleChange}
                      className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    />
                  </div>

                  <div>
                    <label htmlFor="scheduledTime" className="block text-sm font-medium text-gray-700">
                      Scheduled Time
                    </label>
                    <input
                      type="time"
                      name="scheduledTime"
                      id="scheduledTime"
                      required
                      value={formData.scheduledTime}
                      onChange={handleChange}
                      className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    />
                  </div>

                  <div>
                    <label htmlFor="status" className="block text-sm font-medium text-gray-700">
                      Status
                    </label>
                    <select
                      name="status"
                      id="status"
                      value={formData.status}
                      onChange={handleChange}
                      className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                    >
                      <option value="scheduled">Scheduled</option>
                      <option value="departed">Departed</option>
                      <option value="delayed">Delayed</option>
                      <option value="cancelled">Cancelled</option>
                    </select>
                  </div>

                  <div className="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
                    <button
                      type="submit"
                      disabled={isLoading}
                      className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {isLoading ? 'Saving...' : (flight ? 'Update' : 'Create')}
                    </button>
                    <button
                      type="button"
                      onClick={onClose}
                      className="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:mt-0 sm:w-auto sm:text-sm"
                    >
                      Cancel
                    </button>
                  </div>
                </form>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default FlightModal; 