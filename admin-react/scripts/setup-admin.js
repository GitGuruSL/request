import { createUserWithEmailAndPassword } from 'firebase/auth';
import { doc, setDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '../src/firebase/config.js';
import { signOut } from 'firebase/auth';

async function createSuperAdmin() {
  try {
    console.log('🚀 Setting up Super Admin for Request Marketplace...');
    
    const email = 'superadmin@requestmarketplace.com';
    const password = 'SuperAdmin123!'; // Change this in production!
    const name = 'Super Administrator';

    console.log('📧 Creating Firebase Auth user...');
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;

    console.log('📝 Creating admin document in Firestore...');
    await setDoc(doc(db, 'admin_users', user.uid), {
      name: name,
      email: email,
      role: 'super_admin',
      country: null, // Super admin has global access
      isActive: true,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });

    // Sign out the created user
    await signOut(auth);

    console.log('✅ Super Admin created successfully!');
    console.log('');
    console.log('📋 Login Credentials:');
    console.log('   Email:', email);
    console.log('   Password:', password);
    console.log('');
    console.log('🔐 IMPORTANT: Change the password after first login!');
    console.log('');
    console.log('🌐 Access the admin panel at: http://localhost:5173');
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating super admin:', error);
    
    if (error.code === 'auth/email-already-in-use') {
      console.log('');
      console.log('🔍 The super admin user already exists.');
      console.log('📧 Email: superadmin@requestmarketplace.com');
      console.log('🔑 Try logging in with the existing credentials.');
    }
    
    process.exit(1);
  }
}

// Create example country admin
async function createCountryAdmin() {
  try {
    const email = 'admin.usa@requestmarketplace.com';
    const password = 'CountryAdmin123!'; // Change this in production!
    const name = 'USA Administrator';
    const country = 'United States';

    console.log('🇺🇸 Creating Country Admin for', country);
    const userCredential = await createUserWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;

    await setDoc(doc(db, 'admin_users', user.uid), {
      name: name,
      email: email,
      role: 'country_admin',
      country: country,
      isActive: true,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp()
    });

    await signOut(auth);

    console.log('✅ Country Admin created successfully!');
    console.log('📧 Email:', email);
    console.log('🔑 Password:', password);
    console.log('🌍 Country:', country);

  } catch (error) {
    if (error.code !== 'auth/email-already-in-use') {
      console.error('❌ Error creating country admin:', error);
    }
  }
}

async function setupAdmins() {
  await createSuperAdmin();
  await createCountryAdmin();
}

setupAdmins();
