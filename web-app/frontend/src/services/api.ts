import { db } from '../firebase-config';
import { 
  collection, 
  addDoc, 
  getDocs, 
  doc, 
  updateDoc, 
  deleteDoc, 
  query, 
  where, 
  orderBy,
  Timestamp 
} from 'firebase/firestore';

// Types matching the iOS app
export interface IncomingFlight {
  id: string;
  flightNumber: string;
  terminal: string;
  origin: string;
  scheduledTime: Date;
  actualArrivalTime?: Date;
  expectedArrivalTime?: Date;
  bagAvailableTime?: Date;
  carousel?: string;
  notes: string;
  cancelled: boolean;
  outgoingLinks: OutgoingLink[];
  date: Date;
  collectedTime?: Date;
  deliveredTime?: Date;
  screeningBags?: number;
  screeningStartTime?: Date;
  screeningEndTime?: Date;
  deliveredNonScreeningTime?: Date;
  deliveredScreeningTime?: Date;
}

export interface OutgoingFlight {
  id: string;
  flightNumber: string;
  terminal: string;
  destination: string;
  scheduledTime: Date;
  actualTime?: Date;
  expectedTime?: Date;
  cancelled: boolean;
  bagsFromIncoming: { [key: string]: number };
}

export interface OutgoingLink {
  id: string;
  outgoingFlightID: string;
  bagCount: number;
  isMAGTransfer: boolean;
}

// Helper function to convert Firestore timestamp to Date
const timestampToDate = (timestamp: any): Date => {
  if (timestamp?.toDate) {
    return timestamp.toDate();
  }
  return new Date(timestamp);
};

// Helper function to convert Date to Firestore timestamp
const dateToTimestamp = (date: Date): Timestamp => {
  return Timestamp.fromDate(date);
};

// Incoming Flights API
export const getIncomingFlights = async (): Promise<IncomingFlight[]> => {
  try {
    const querySnapshot = await getDocs(collection(db, 'incomingFlights'));
    return querySnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        flightNumber: data.flightNumber,
        terminal: data.terminal,
        origin: data.origin,
        scheduledTime: timestampToDate(data.scheduledTime),
        actualArrivalTime: data.actualArrivalTime ? timestampToDate(data.actualArrivalTime) : undefined,
        expectedArrivalTime: data.expectedArrivalTime ? timestampToDate(data.expectedArrivalTime) : undefined,
        bagAvailableTime: data.bagAvailableTime ? timestampToDate(data.bagAvailableTime) : undefined,
        carousel: data.carousel,
        notes: data.notes || '',
        cancelled: data.cancelled || false,
        outgoingLinks: data.outgoingLinks || [],
        date: timestampToDate(data.date),
        collectedTime: data.collectedTime ? timestampToDate(data.collectedTime) : undefined,
        deliveredTime: data.deliveredTime ? timestampToDate(data.deliveredTime) : undefined,
        screeningBags: data.screeningBags,
        screeningStartTime: data.screeningStartTime ? timestampToDate(data.screeningStartTime) : undefined,
        screeningEndTime: data.screeningEndTime ? timestampToDate(data.screeningEndTime) : undefined,
        deliveredNonScreeningTime: data.deliveredNonScreeningTime ? timestampToDate(data.deliveredNonScreeningTime) : undefined,
        deliveredScreeningTime: data.deliveredScreeningTime ? timestampToDate(data.deliveredScreeningTime) : undefined,
      };
    });
  } catch (error) {
    console.error('Error fetching incoming flights:', error);
    throw error;
  }
};

export const createIncomingFlight = async (flight: Omit<IncomingFlight, 'id'>): Promise<string> => {
  try {
    const docRef = await addDoc(collection(db, 'incomingFlights'), {
      ...flight,
      scheduledTime: dateToTimestamp(flight.scheduledTime),
      actualArrivalTime: flight.actualArrivalTime ? dateToTimestamp(flight.actualArrivalTime) : null,
      expectedArrivalTime: flight.expectedArrivalTime ? dateToTimestamp(flight.expectedArrivalTime) : null,
      bagAvailableTime: flight.bagAvailableTime ? dateToTimestamp(flight.bagAvailableTime) : null,
      date: dateToTimestamp(flight.date),
      collectedTime: flight.collectedTime ? dateToTimestamp(flight.collectedTime) : null,
      deliveredTime: flight.deliveredTime ? dateToTimestamp(flight.deliveredTime) : null,
      screeningStartTime: flight.screeningStartTime ? dateToTimestamp(flight.screeningStartTime) : null,
      screeningEndTime: flight.screeningEndTime ? dateToTimestamp(flight.screeningEndTime) : null,
      deliveredNonScreeningTime: flight.deliveredNonScreeningTime ? dateToTimestamp(flight.deliveredNonScreeningTime) : null,
      deliveredScreeningTime: flight.deliveredScreeningTime ? dateToTimestamp(flight.deliveredScreeningTime) : null,
    });
    return docRef.id;
  } catch (error) {
    console.error('Error creating incoming flight:', error);
    throw error;
  }
};

export const updateIncomingFlight = async (id: string, updates: Partial<IncomingFlight>): Promise<void> => {
  try {
    const docRef = doc(db, 'incomingFlights', id);
    const updateData: any = { ...updates };
    
    // Convert dates to timestamps
    if (updates.scheduledTime) updateData.scheduledTime = dateToTimestamp(updates.scheduledTime);
    if (updates.actualArrivalTime) updateData.actualArrivalTime = dateToTimestamp(updates.actualArrivalTime);
    if (updates.expectedArrivalTime) updateData.expectedArrivalTime = dateToTimestamp(updates.expectedArrivalTime);
    if (updates.bagAvailableTime) updateData.bagAvailableTime = dateToTimestamp(updates.bagAvailableTime);
    if (updates.date) updateData.date = dateToTimestamp(updates.date);
    if (updates.collectedTime) updateData.collectedTime = dateToTimestamp(updates.collectedTime);
    if (updates.deliveredTime) updateData.deliveredTime = dateToTimestamp(updates.deliveredTime);
    if (updates.screeningStartTime) updateData.screeningStartTime = dateToTimestamp(updates.screeningStartTime);
    if (updates.screeningEndTime) updateData.screeningEndTime = dateToTimestamp(updates.screeningEndTime);
    if (updates.deliveredNonScreeningTime) updateData.deliveredNonScreeningTime = dateToTimestamp(updates.deliveredNonScreeningTime);
    if (updates.deliveredScreeningTime) updateData.deliveredScreeningTime = dateToTimestamp(updates.deliveredScreeningTime);
    
    await updateDoc(docRef, updateData);
  } catch (error) {
    console.error('Error updating incoming flight:', error);
    throw error;
  }
};

export const deleteIncomingFlight = async (id: string): Promise<void> => {
  try {
    await deleteDoc(doc(db, 'incomingFlights', id));
  } catch (error) {
    console.error('Error deleting incoming flight:', error);
    throw error;
  }
};

// Outgoing Flights API
export const getOutgoingFlights = async (): Promise<OutgoingFlight[]> => {
  try {
    const querySnapshot = await getDocs(collection(db, 'outgoingFlights'));
    return querySnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        flightNumber: data.flightNumber,
        terminal: data.terminal,
        destination: data.destination,
        scheduledTime: timestampToDate(data.scheduledTime),
        actualTime: data.actualTime ? timestampToDate(data.actualTime) : undefined,
        expectedTime: data.expectedTime ? timestampToDate(data.expectedTime) : undefined,
        cancelled: data.cancelled || false,
        bagsFromIncoming: data.bagsFromIncoming || {},
      };
    });
  } catch (error) {
    console.error('Error fetching outgoing flights:', error);
    throw error;
  }
};

export const createOutgoingFlight = async (flight: Omit<OutgoingFlight, 'id'>): Promise<string> => {
  try {
    const docRef = await addDoc(collection(db, 'outgoingFlights'), {
      ...flight,
      scheduledTime: dateToTimestamp(flight.scheduledTime),
      actualTime: flight.actualTime ? dateToTimestamp(flight.actualTime) : null,
      expectedTime: flight.expectedTime ? dateToTimestamp(flight.expectedTime) : null,
    });
    return docRef.id;
  } catch (error) {
    console.error('Error creating outgoing flight:', error);
    throw error;
  }
};

export const updateOutgoingFlight = async (id: string, updates: Partial<OutgoingFlight>): Promise<void> => {
  try {
    const docRef = doc(db, 'outgoingFlights', id);
    const updateData: any = { ...updates };
    
    // Convert dates to timestamps
    if (updates.scheduledTime) updateData.scheduledTime = dateToTimestamp(updates.scheduledTime);
    if (updates.actualTime) updateData.actualTime = dateToTimestamp(updates.actualTime);
    if (updates.expectedTime) updateData.expectedTime = dateToTimestamp(updates.expectedTime);
    
    await updateDoc(docRef, updateData);
  } catch (error) {
    console.error('Error updating outgoing flight:', error);
    throw error;
  }
};

export const deleteOutgoingFlight = async (id: string): Promise<void> => {
  try {
    await deleteDoc(doc(db, 'outgoingFlights', id));
  } catch (error) {
    console.error('Error deleting outgoing flight:', error);
    throw error;
  }
};

// Baggage Transfer API
export const createBaggageTransfer = async (transferData: {
  incomingFlightId: string;
  outgoingFlightId: string;
  bagCount: number;
  isMAGTransfer: boolean;
}): Promise<string> => {
  try {
    const transfer = {
      ...transferData,
      createdAt: Timestamp.now(),
    };
    const docRef = await addDoc(collection(db, 'baggageTransfers'), transfer);
    return docRef.id;
  } catch (error) {
    console.error('Error creating baggage transfer:', error);
    throw error;
  }
};

export const updateBaggageTransfer = async (id: string, updates: {
  bagCount?: number;
  isMAGTransfer?: boolean;
}): Promise<void> => {
  try {
    const docRef = doc(db, 'baggageTransfers', id);
    await updateDoc(docRef, {
      ...updates,
      updatedAt: Timestamp.now(),
    });
  } catch (error) {
    console.error('Error updating baggage transfer:', error);
    throw error;
  }
};

export const deleteBaggageTransfer = async (id: string): Promise<void> => {
  try {
    await deleteDoc(doc(db, 'baggageTransfers', id));
  } catch (error) {
    console.error('Error deleting baggage transfer:', error);
    throw error;
  }
};

export const getBaggageTransfers = async (): Promise<any[]> => {
  try {
    const querySnapshot = await getDocs(collection(db, 'baggageTransfers'));
    return querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error('Error fetching baggage transfers:', error);
    throw error;
  }
};

// Workflow Stats API
export const getWorkflowStats = async (): Promise<any> => {
  try {
    const incomingFlights = await getIncomingFlights();
    const outgoingFlights = await getOutgoingFlights();
    
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const todayIncoming = incomingFlights.filter(flight => 
      flight.date.getTime() === today.getTime()
    );
    
    const pendingCollections = todayIncoming.filter(flight => 
      !flight.collectedTime && flight.bagAvailableTime && flight.bagAvailableTime <= new Date()
    );
    
    const pendingDeliveries = todayIncoming.filter(flight => 
      flight.collectedTime && !flight.deliveredTime
    );
    
    return {
      totalIncomingFlights: todayIncoming.length,
      pendingCollections: pendingCollections.length,
      pendingDeliveries: pendingDeliveries.length,
      activeWorkflows: pendingCollections.length + pendingDeliveries.length,
    };
  } catch (error) {
    console.error('Error fetching workflow stats:', error);
    throw error;
  }
}; 