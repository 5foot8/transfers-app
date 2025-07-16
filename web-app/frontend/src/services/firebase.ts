import { 
  collection, 
  doc, 
  getDocs, 
  getDoc, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  onSnapshot,
  Timestamp,
  writeBatch
} from 'firebase/firestore';
import { db } from '../firebase-config';

// Types
export interface IncomingFlight {
  id?: string;
  flightNumber: string;
  terminal: string;
  origin: string;
  scheduledTime: Date;
  actualArrivalTime?: Date;
  expectedArrivalTime?: Date;
  cancelled: boolean;
  collectedTime?: Date;
  screeningStartTime?: Date;
  screeningEndTime?: Date;
  screeningBags?: number;
  deliveredTime?: Date;
  bagAvailableTime?: Date;
  carousel?: string;
  notes: string;
  outgoingLinks: OutgoingLink[];
  createdAt: Date;
  updatedAt: Date;
}

export interface OutgoingFlight {
  id?: string;
  flightNumber: string;
  terminal: string;
  destination: string;
  scheduledTime: Date;
  actualTime?: Date;
  expectedTime?: Date;
  cancelled: boolean;
  bagsFromIncoming: Record<string, number>;
  createdAt: Date;
  updatedAt: Date;
}

export interface OutgoingLink {
  id?: string;
  outgoingFlightID: string;
  bagCount: number;
  isMAGTransfer: boolean;
}

// Helper functions
const timestampToDate = (timestamp: any): Date => {
  if (timestamp instanceof Timestamp) {
    return timestamp.toDate();
  }
  return timestamp;
};

const dateToTimestamp = (date: Date): Timestamp => {
  return Timestamp.fromDate(date);
};

// Incoming Flights Service
export const incomingFlightsService = {
  async getAll(): Promise<IncomingFlight[]> {
    const querySnapshot = await getDocs(collection(db, 'incomingFlights'));
    return querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      scheduledTime: timestampToDate(doc.data().scheduledTime),
      actualArrivalTime: doc.data().actualArrivalTime ? timestampToDate(doc.data().actualArrivalTime) : undefined,
      expectedArrivalTime: doc.data().expectedArrivalTime ? timestampToDate(doc.data().expectedArrivalTime) : undefined,
      collectedTime: doc.data().collectedTime ? timestampToDate(doc.data().collectedTime) : undefined,
      screeningStartTime: doc.data().screeningStartTime ? timestampToDate(doc.data().screeningStartTime) : undefined,
      screeningEndTime: doc.data().screeningEndTime ? timestampToDate(doc.data().screeningEndTime) : undefined,
      deliveredTime: doc.data().deliveredTime ? timestampToDate(doc.data().deliveredTime) : undefined,
      bagAvailableTime: doc.data().bagAvailableTime ? timestampToDate(doc.data().bagAvailableTime) : undefined,
      createdAt: timestampToDate(doc.data().createdAt),
      updatedAt: timestampToDate(doc.data().updatedAt)
    })) as IncomingFlight[];
  },

  async create(flight: Omit<IncomingFlight, 'id' | 'createdAt' | 'updatedAt'>): Promise<IncomingFlight> {
    const now = new Date();
    const flightData = {
      ...flight,
      scheduledTime: dateToTimestamp(flight.scheduledTime),
      actualArrivalTime: flight.actualArrivalTime ? dateToTimestamp(flight.actualArrivalTime) : null,
      expectedArrivalTime: flight.expectedArrivalTime ? dateToTimestamp(flight.expectedArrivalTime) : null,
      collectedTime: flight.collectedTime ? dateToTimestamp(flight.collectedTime) : null,
      screeningStartTime: flight.screeningStartTime ? dateToTimestamp(flight.screeningStartTime) : null,
      screeningEndTime: flight.screeningEndTime ? dateToTimestamp(flight.screeningEndTime) : null,
      deliveredTime: flight.deliveredTime ? dateToTimestamp(flight.deliveredTime) : null,
      bagAvailableTime: flight.bagAvailableTime ? dateToTimestamp(flight.bagAvailableTime) : null,
      createdAt: dateToTimestamp(now),
      updatedAt: dateToTimestamp(now)
    };

    const docRef = await addDoc(collection(db, 'incomingFlights'), flightData);
    return this.getById(docRef.id) as Promise<IncomingFlight>;
  },

  async getById(id: string): Promise<IncomingFlight | null> {
    const docRef = doc(db, 'incomingFlights', id);
    const docSnap = await getDoc(docRef);
    
    if (docSnap.exists()) {
      const data = docSnap.data();
      return {
        id: docSnap.id,
        ...data,
        scheduledTime: timestampToDate(data.scheduledTime),
        actualArrivalTime: data.actualArrivalTime ? timestampToDate(data.actualArrivalTime) : undefined,
        expectedArrivalTime: data.expectedArrivalTime ? timestampToDate(data.expectedArrivalTime) : undefined,
        collectedTime: data.collectedTime ? timestampToDate(data.collectedTime) : undefined,
        screeningStartTime: data.screeningStartTime ? timestampToDate(data.screeningStartTime) : undefined,
        screeningEndTime: data.screeningEndTime ? timestampToDate(data.screeningEndTime) : undefined,
        deliveredTime: data.deliveredTime ? timestampToDate(data.deliveredTime) : undefined,
        bagAvailableTime: data.bagAvailableTime ? timestampToDate(data.bagAvailableTime) : undefined,
        createdAt: timestampToDate(data.createdAt),
        updatedAt: timestampToDate(data.updatedAt)
      } as IncomingFlight;
    }
    return null;
  },

  async update(id: string, updates: Partial<IncomingFlight>): Promise<void> {
    const docRef = doc(db, 'incomingFlights', id);
    const updateData: any = {
      ...updates,
      updatedAt: dateToTimestamp(new Date())
    };

    if (updates.scheduledTime) updateData.scheduledTime = dateToTimestamp(updates.scheduledTime);
    if (updates.actualArrivalTime) updateData.actualArrivalTime = dateToTimestamp(updates.actualArrivalTime);
    if (updates.expectedArrivalTime) updateData.expectedArrivalTime = dateToTimestamp(updates.expectedArrivalTime);
    if (updates.collectedTime) updateData.collectedTime = dateToTimestamp(updates.collectedTime);
    if (updates.screeningStartTime) updateData.screeningStartTime = dateToTimestamp(updates.screeningStartTime);
    if (updates.screeningEndTime) updateData.screeningEndTime = dateToTimestamp(updates.screeningEndTime);
    if (updates.deliveredTime) updateData.deliveredTime = dateToTimestamp(updates.deliveredTime);
    if (updates.bagAvailableTime) updateData.bagAvailableTime = dateToTimestamp(updates.bagAvailableTime);

    await updateDoc(docRef, updateData);
  },

  async delete(id: string): Promise<void> {
    const docRef = doc(db, 'incomingFlights', id);
    await deleteDoc(docRef);
  },

  onSnapshot(callback: (flights: IncomingFlight[]) => void) {
    return onSnapshot(collection(db, 'incomingFlights'), (querySnapshot) => {
      const flights = querySnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        scheduledTime: timestampToDate(doc.data().scheduledTime),
        actualArrivalTime: doc.data().actualArrivalTime ? timestampToDate(doc.data().actualArrivalTime) : undefined,
        expectedArrivalTime: doc.data().expectedArrivalTime ? timestampToDate(doc.data().expectedArrivalTime) : undefined,
        collectedTime: doc.data().collectedTime ? timestampToDate(doc.data().collectedTime) : undefined,
        screeningStartTime: doc.data().screeningStartTime ? timestampToDate(doc.data().screeningStartTime) : undefined,
        screeningEndTime: doc.data().screeningEndTime ? timestampToDate(doc.data().screeningEndTime) : undefined,
        deliveredTime: doc.data().deliveredTime ? timestampToDate(doc.data().deliveredTime) : undefined,
        bagAvailableTime: doc.data().bagAvailableTime ? timestampToDate(doc.data().bagAvailableTime) : undefined,
        createdAt: timestampToDate(doc.data().createdAt),
        updatedAt: timestampToDate(doc.data().updatedAt)
      })) as IncomingFlight[];
      callback(flights);
    });
  }
};

// Outgoing Flights Service
export const outgoingFlightsService = {
  async getAll(): Promise<OutgoingFlight[]> {
    const querySnapshot = await getDocs(collection(db, 'outgoingFlights'));
    return querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      scheduledTime: timestampToDate(doc.data().scheduledTime),
      actualTime: doc.data().actualTime ? timestampToDate(doc.data().actualTime) : undefined,
      expectedTime: doc.data().expectedTime ? timestampToDate(doc.data().expectedTime) : undefined,
      createdAt: timestampToDate(doc.data().createdAt),
      updatedAt: timestampToDate(doc.data().updatedAt)
    })) as OutgoingFlight[];
  },

  async create(flight: Omit<OutgoingFlight, 'id' | 'createdAt' | 'updatedAt'>): Promise<OutgoingFlight> {
    const now = new Date();
    const flightData = {
      ...flight,
      scheduledTime: dateToTimestamp(flight.scheduledTime),
      actualTime: flight.actualTime ? dateToTimestamp(flight.actualTime) : null,
      expectedTime: flight.expectedTime ? dateToTimestamp(flight.expectedTime) : null,
      createdAt: dateToTimestamp(now),
      updatedAt: dateToTimestamp(now)
    };

    const docRef = await addDoc(collection(db, 'outgoingFlights'), flightData);
    return this.getById(docRef.id) as Promise<OutgoingFlight>;
  },

  async getById(id: string): Promise<OutgoingFlight | null> {
    const docRef = doc(db, 'outgoingFlights', id);
    const docSnap = await getDoc(docRef);
    
    if (docSnap.exists()) {
      const data = docSnap.data();
      return {
        id: docSnap.id,
        ...data,
        scheduledTime: timestampToDate(data.scheduledTime),
        actualTime: data.actualTime ? timestampToDate(data.actualTime) : undefined,
        expectedTime: data.expectedTime ? timestampToDate(data.expectedTime) : undefined,
        createdAt: timestampToDate(data.createdAt),
        updatedAt: timestampToDate(data.updatedAt)
      } as OutgoingFlight;
    }
    return null;
  },

  async update(id: string, updates: Partial<OutgoingFlight>): Promise<void> {
    const docRef = doc(db, 'outgoingFlights', id);
    const updateData: any = {
      ...updates,
      updatedAt: dateToTimestamp(new Date())
    };

    if (updates.scheduledTime) updateData.scheduledTime = dateToTimestamp(updates.scheduledTime);
    if (updates.actualTime) updateData.actualTime = dateToTimestamp(updates.actualTime);
    if (updates.expectedTime) updateData.expectedTime = dateToTimestamp(updates.expectedTime);

    await updateDoc(docRef, updateData);
  },

  async delete(id: string): Promise<void> {
    const docRef = doc(db, 'outgoingFlights', id);
    await deleteDoc(docRef);
  },

  onSnapshot(callback: (flights: OutgoingFlight[]) => void) {
    return onSnapshot(collection(db, 'outgoingFlights'), (querySnapshot) => {
      const flights = querySnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        scheduledTime: timestampToDate(doc.data().scheduledTime),
        actualTime: doc.data().actualTime ? timestampToDate(doc.data().actualTime) : undefined,
        expectedTime: doc.data().expectedTime ? timestampToDate(doc.data().expectedTime) : undefined,
        createdAt: timestampToDate(doc.data().createdAt),
        updatedAt: timestampToDate(doc.data().updatedAt)
      })) as OutgoingFlight[];
      callback(flights);
    });
  }
};

// Transfer Links
export const transferLinksService = {
  // Link flights with bag count
  async linkFlights(incomingFlightId: string, outgoingFlightId: string, bagCount: number, isMAGTransfer: boolean = false): Promise<void> {
    const batch = writeBatch(db);
    
    // Add link to incoming flight
    const incomingRef = doc(db, 'incomingFlights', incomingFlightId);
    const incomingDoc = await getDoc(incomingRef);
    if (incomingDoc.exists()) {
      const incomingData = incomingDoc.data();
      const outgoingLinks = incomingData.outgoingLinks || [];
      outgoingLinks.push({
        outgoingFlightID: outgoingFlightId,
        bagCount,
        isMAGTransfer
      });
      
      batch.update(incomingRef, { 
        outgoingLinks,
        updatedAt: dateToTimestamp(new Date())
      });
    }

    // Update outgoing flight with bag count
    const outgoingRef = doc(db, 'outgoingFlights', outgoingFlightId);
    const outgoingDoc = await getDoc(outgoingRef);
    if (outgoingDoc.exists()) {
      const outgoingData = outgoingDoc.data();
      const bagsFromIncoming = outgoingData.bagsFromIncoming || {};
      const incomingFlight = await this.getIncomingFlightNumber(incomingFlightId);
      if (incomingFlight) {
        bagsFromIncoming[incomingFlight] = bagCount;
      }
      
      batch.update(outgoingRef, { 
        bagsFromIncoming,
        updatedAt: dateToTimestamp(new Date())
      });
    }

    await batch.commit();
  },

  // Unlink flights
  async unlinkFlights(incomingFlightId: string, outgoingFlightId: string): Promise<void> {
    const batch = writeBatch(db);
    
    // Remove link from incoming flight
    const incomingRef = doc(db, 'incomingFlights', incomingFlightId);
    const incomingDoc = await getDoc(incomingRef);
    if (incomingDoc.exists()) {
      const incomingData = incomingDoc.data();
      const outgoingLinks = incomingData.outgoingLinks || [];
      const updatedLinks = outgoingLinks.filter((link: any) => link.outgoingFlightID !== outgoingFlightId);
      
      batch.update(incomingRef, { 
        outgoingLinks: updatedLinks,
        updatedAt: dateToTimestamp(new Date())
      });
    }

    // Remove bag count from outgoing flight
    const outgoingRef = doc(db, 'outgoingFlights', outgoingFlightId);
    const outgoingDoc = await getDoc(outgoingRef);
    if (outgoingDoc.exists()) {
      const outgoingData = outgoingDoc.data();
      const bagsFromIncoming = outgoingData.bagsFromIncoming || {};
      const incomingFlight = await this.getIncomingFlightNumber(incomingFlightId);
      if (incomingFlight) {
        delete bagsFromIncoming[incomingFlight];
      }
      
      batch.update(outgoingRef, { 
        bagsFromIncoming,
        updatedAt: dateToTimestamp(new Date())
      });
    }

    await batch.commit();
  },

  // Helper function to get incoming flight number
  async getIncomingFlightNumber(incomingFlightId: string): Promise<string | null> {
    const docRef = doc(db, 'incomingFlights', incomingFlightId);
    const docSnap = await getDoc(docRef);
    if (docSnap.exists()) {
      return docSnap.data().flightNumber;
    }
    return null;
  }
}; 