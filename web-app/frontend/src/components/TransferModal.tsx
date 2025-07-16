import React, { useState, useEffect } from 'react';
import { XMarkIcon } from '@heroicons/react/24/outline';

interface TransferModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (transferData: any) => void;
  transfer?: any;
  isLoading?: boolean;
}

const TransferModal: React.FC<TransferModalProps> = ({
  isOpen,
  onClose,
  onSubmit,
  transfer,
  isLoading = false,
}) => {
  const [formData, setFormData] = useState({
    passengerName: '',
    incomingFlightCode: '',
    outgoingFlightCode: '',
    transferDate: '',
    status: 'pending',
    notes: '',
  });

  useEffect(() => {
    if (transfer) {
      setFormData({
        passengerName: transfer.passengerName || '',
        incomingFlightCode: transfer.incomingFlightCode || '',
        outgoingFlightCode: transfer.outgoingFlightCode || '',
        transferDate: transfer.transferDate || '',
        status: transfer.status || 'pending',
        notes: transfer.notes || '',
      });
    } else {
      setFormData({
        passengerName: '',
        incomingFlightCode: '',
        outgoingFlightCode: '',
        transferDate: '',
        status: 'pending',
        notes: '',
      });
    }
  }, [transfer]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit(formData);
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
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
                {transfer ? 'Edit Transfer' : 'Add New Transfer'}
              </h3>
              <div className="mt-2">
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div>
                    <label htmlFor="passengerName" className="block text-sm font-medium text-gray-700">
                      Passenger Name
                    </label>
                    <input
                      type="text"
                      name="passengerName"
                      id="passengerName"
                      required
                      value={formData.passengerName}
                      onChange={handleChange}
                      className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                      placeholder="Enter passenger name"
                    />
                  </div>

                  <div>
                    <label htmlFor="incomingFlightCode" className="block text-sm font-medium text-gray-700">
                      Incoming Flight Code
                    </label>
                    <input
                      type="text"
                      name="incomingFlightCode"
                      id="incomingFlightCode"
                      required
                      value={formData.incomingFlightCode}
                      onChange={handleChange}
                      className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                      placeholder="e.g., AA123"
                    />
                  </div>

                  <div>
                    <label htmlFor="outgoingFlightCode" className="block text-sm font-medium text-gray-700">
                      Outgoing Flight Code
                    </label>
                    <input
                      type="text"
                      name="outgoingFlightCode"
                      id="outgoingFlightCode"
                      required
                      value={formData.outgoingFlightCode}
                      onChange={handleChange}
                      className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                      placeholder="e.g., UA456"
                    />
                  </div>

                  <div>
                    <label htmlFor="transferDate" className="block text-sm font-medium text-gray-700">
                      Transfer Date
                    </label>
                    <input
                      type="date"
                      name="transferDate"
                      id="transferDate"
                      required
                      value={formData.transferDate}
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
                      <option value="pending">Pending</option>
                      <option value="in_progress">In Progress</option>
                      <option value="completed">Completed</option>
                      <option value="cancelled">Cancelled</option>
                    </select>
                  </div>

                  <div>
                    <label htmlFor="notes" className="block text-sm font-medium text-gray-700">
                      Notes
                    </label>
                    <textarea
                      name="notes"
                      id="notes"
                      rows={3}
                      value={formData.notes}
                      onChange={handleChange}
                      className="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
                      placeholder="Additional notes about the transfer..."
                    />
                  </div>

                  <div className="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
                    <button
                      type="submit"
                      disabled={isLoading}
                      className="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-blue-600 text-base font-medium text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 sm:ml-3 sm:w-auto sm:text-sm disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {isLoading ? 'Saving...' : (transfer ? 'Update' : 'Create')}
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

export default TransferModal; 