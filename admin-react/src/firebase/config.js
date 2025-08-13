import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: "AIzaSyCtuD42SzwxKmSY5p-x5olFex2U_S9YrMk",
  authDomain: "request-marketplace.firebaseapp.com",
  projectId: "request-marketplace",
  storageBucket: "request-marketplace.firebasestorage.app",
  messagingSenderId: "355474518888",
  appId: "1:355474518888:web:7b3a7f6f7d7a8b0d8e8f9f"
};

const app = initializeApp(firebaseConfig);

export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);

// Log config to verify
console.log('Firebase initialized with project:', firebaseConfig.projectId);
console.log('Storage bucket:', firebaseConfig.storageBucket);

export default app;
