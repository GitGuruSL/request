#!/usr/bin/env node

// Simple script to add vehicle types to Firestore
// Run with: node add-vehicle-types.js

const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = {
  // Add your Firebase Admin SDK key here
  "type": "service_account",
  "project_id": "request-users-app"
};

// For now, let's use a simple approach without admin SDK
// You can run this in the browser console instead

console.log(`
==============================================
🚀 VEHICLE TYPES INITIALIZATION SCRIPT 
==============================================

Since Firebase Admin SDK requires service account key,
you can use one of these methods:

METHOD 1 - Browser Console (Easiest):
1. Open your admin panel in browser
2. Login as Super Admin  
3. Open browser developer tools (F12)
4. Go to Console tab
5. Paste this code:

// Copy and paste this in browser console:
const vehicleTypes = [
  { name: 'Bike', icon: 'TwoWheeler', isActive: true, displayOrder: 1 },
  { name: 'Three Wheeler', icon: 'LocalTaxi', isActive: true, displayOrder: 2 },
  { name: 'Car', icon: 'DirectionsCar', isActive: true, displayOrder: 3 },
  { name: 'Van', icon: 'AirportShuttle', isActive: true, displayOrder: 4 },
  { name: 'Shared Ride', icon: 'People', isActive: true, displayOrder: 5 }
];

// Run this in console:
(async () => {
  const db = window.firebase.firestore();
  for (const vehicle of vehicleTypes) {
    await db.collection('vehicle_types').add({
      ...vehicle,
      createdAt: window.firebase.firestore.FieldValue.serverTimestamp(),
      createdBy: 'console-init'
    });
    console.log('Added:', vehicle.name);
  }
  console.log('✅ All vehicle types added!');
})();

METHOD 2 - Admin Panel:
1. Go to admin panel → Vehicle Types
2. Click "Add Default Types" button
3. Done!

==============================================
`);
