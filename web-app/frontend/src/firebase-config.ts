import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

// Firebase configuration
// Replace these values with your actual Firebase project configuration
const firebaseConfig = {
  apiKey: "AIzaSyC3kz_ZPj1Bb1pW0AN8Vhhu0IU3ApNdLUM",
  authDomain: "flight-transfers-app.firebaseapp.com",
  projectId: "flight-transfers-app",
  storageBucket: "flight-transfers-app.firebasestorage.app",
  messagingSenderId: "180323492479",
  appId: "1:180323492479:web:b34861a5ffb561baf5d54a",
  measurementId: "G-43G8F2RVR9"
};

const app = initializeApp(firebaseConfig);

// Initialize Firebase services
export const auth = getAuth(app);
export const db = getFirestore(app);

export default app; 