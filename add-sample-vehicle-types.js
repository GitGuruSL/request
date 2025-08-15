// Quick script to add sample vehicle types data via Firebase Web SDK
import { collection, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from './admin-react/src/firebase/config.js';

const vehicleTypes = [
  {
    name: 'Car',
    description: 'Standard passenger car',
    icon: 'DirectionsCar',
    passengerCapacity: 4,
    fuelTypes: ['Petrol', 'Diesel', 'Electric', 'Hybrid'],
    country: 'LK',
    isActive: true,
    createdAt: serverTimestamp(),
    createdBy: 'system'
  },
  {
    name: 'Motorcycle',
    description: 'Two-wheeler motorcycle',
    icon: 'TwoWheeler', 
    passengerCapacity: 2,
    fuelTypes: ['Petrol', 'Electric'],
    country: 'LK',
    isActive: true,
    createdAt: serverTimestamp(),
    createdBy: 'system'
  },
  {
    name: 'Taxi',
    description: 'Commercial taxi service',
    icon: 'LocalTaxi',
    passengerCapacity: 4,
    fuelTypes: ['Petrol', 'Diesel', 'Electric', 'Hybrid'],
    country: 'LK',
    isActive: true,
    createdAt: serverTimestamp(),
    createdBy: 'system'
  },
  {
    name: 'Van',
    description: 'Large passenger van',
    icon: 'AirportShuttle',
    passengerCapacity: 8,
    fuelTypes: ['Petrol', 'Diesel'],
    country: 'LK',
    isActive: true,
    createdAt: serverTimestamp(),
    createdBy: 'system'
  },
  {
    name: 'Three Wheeler',
    description: 'Auto rickshaw/tuk-tuk',
    icon: 'DirectionsCar',
    passengerCapacity: 3,
    fuelTypes: ['Petrol', 'Electric'],
    country: 'LK',
    isActive: true,
    createdAt: serverTimestamp(),
    createdBy: 'system'
  }
];

// Function to add vehicle types
export async function addSampleVehicleTypes() {
  try {
    const promises = vehicleTypes.map(vehicleType => 
      addDoc(collection(db, 'vehicle_types'), vehicleType)
    );
    
    await Promise.all(promises);
    console.log('Sample vehicle types added successfully!');
    return { success: true, message: 'Vehicle types added successfully' };
  } catch (error) {
    console.error('Error adding vehicle types:', error);
    return { success: false, error: error.message };
  }
}

// Run if this file is executed directly
if (typeof window !== 'undefined') {
  // Browser environment - you can call addSampleVehicleTypes() from browser console
  window.addSampleVehicleTypes = addSampleVehicleTypes;
  console.log('Vehicle types data ready. Call addSampleVehicleTypes() to add sample data.');
}
