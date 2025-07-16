import { 
  createUserWithEmailAndPassword,
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  User as FirebaseUser
} from 'firebase/auth';
import { auth } from '../firebase-config';

export interface User {
  uid: string;
  email: string | null;
  displayName?: string;
  role: 'ADMIN' | 'MANAGER' | 'OPERATOR' | 'VIEWER';
}

export const authService = {
  // Register new user
  async register(email: string, password: string, name: string, role: User['role'] = 'VIEWER'): Promise<User> {
    try {
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;
      
      // Update display name
      await user.updateProfile({
        displayName: name
      });

      // Store additional user data in Firestore (you'll need to implement this)
      // For now, we'll return the basic user info
      return {
        uid: user.uid,
        email: user.email,
        displayName: name,
        role
      };
    } catch (error: any) {
      throw new Error(error.message);
    }
  },

  // Login user
  async login(email: string, password: string): Promise<User> {
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;
      
      // Get user role from Firestore (you'll need to implement this)
      // For now, we'll return basic user info
      return {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName || undefined,
        role: 'VIEWER' // Default role, should be fetched from Firestore
      };
    } catch (error: any) {
      throw new Error(error.message);
    }
  },

  // Logout user
  async logout(): Promise<void> {
    try {
      await signOut(auth);
    } catch (error: any) {
      throw new Error(error.message);
    }
  },

  // Get current user
  getCurrentUser(): FirebaseUser | null {
    return auth.currentUser;
  },

  // Listen to auth state changes
  onAuthStateChanged(callback: (user: FirebaseUser | null) => void) {
    return onAuthStateChanged(auth, callback);
  }
}; 