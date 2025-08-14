const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./admin-react/src/config/request-marketplace-firebase-adminsdk-sv7l4-e7e3ff7473.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'request-marketplace'
});

const db = admin.firestore();

const defaultCities = [
  {
    name: 'Colombo',
    countryCode: 'LK',
    isActive: true,
    population: 752993,
    coordinates: {
      lat: 6.9271,
      lng: 79.8612
    },
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now()
  },
  {
    name: 'Kandy',
    countryCode: 'LK',
    isActive: true,
    population: 125400,
    coordinates: {
      lat: 7.2906,
      lng: 80.6337
    },
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now()
  },
  {
    name: 'Galle',
    countryCode: 'LK',
    isActive: true,
    population: 99478,
    coordinates: {
      lat: 6.0535,
      lng: 80.2210
    },
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now()
  },
  {
    name: 'Jaffna',
    countryCode: 'LK',
    isActive: true,
    population: 88138,
    coordinates: {
      lat: 9.6615,
      lng: 80.0255
    },
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now()
  },
  {
    name: 'Negombo',
    countryCode: 'LK',
    isActive: true,
    population: 142136,
    coordinates: {
      lat: 7.2083,
      lng: 79.8358
    },
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now()
  }
];

async function addCities() {
  console.log('Adding default cities...');
  
  const batch = db.batch();
  
  for (const city of defaultCities) {
    const cityRef = db.collection('cities').doc();
    batch.set(cityRef, city);
    console.log(`Adding ${city.name}...`);
  }
  
  await batch.commit();
  console.log('Cities added successfully!');
  process.exit(0);
}

addCities().catch(console.error);
