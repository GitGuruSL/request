import { useAuth } from '../contexts/AuthContext';
import { db } from '../firebase/config';
import { doc, updateDoc } from 'firebase/firestore';
import { Button, Card, CardContent, Typography, Box, Alert } from '@mui/material';
import { useState } from 'react';

const DebugAuth = () => {
  const { user, adminData, userRole, userCountry } = useAuth();
  const [fixing, setFixing] = useState(false);
  const [message, setMessage] = useState('');

  const fixSuperAdminUID = async () => {
    setFixing(true);
    try {
      if (user && user.email === 'superadmin@request.lk') {
        // Update the document ID 6ZlVBdijVfXpOgEp83E5AnHOUaH2 with the correct UID
        const adminDocRef = doc(db, 'admin_users', '6ZlVBdijVfXpOgEp83E5AnHOUaH2');
        
        await updateDoc(adminDocRef, {
          uid: user.uid
        });
        
        setMessage('✅ Super Admin UID fixed! Please refresh the page.');
      }
    } catch (error) {
      setMessage('❌ Error: ' + error.message);
    }
    setFixing(false);
  };

  return (
    <Box sx={{ p: 3 }}>
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            🔍 Authentication Debug Info
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>Firebase User UID:</strong> {user?.uid || 'Not logged in'}
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>Firebase User Email:</strong> {user?.email || 'Not logged in'}
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>Admin Data Found:</strong> {adminData ? 'Yes' : 'No'}
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>Detected Role:</strong> {userRole || 'Not detected'}
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>Admin Country:</strong> {userCountry || 'Not detected'}
          </Typography>
          
          <Typography variant="body2" paragraph>
            <strong>Admin Data:</strong> {JSON.stringify(adminData, null, 2)}
          </Typography>
          
          {user?.email === 'superadmin@request.lk' && userRole !== 'super_admin' && (
            <Box sx={{ mt: 2 }}>
              <Alert severity="warning" sx={{ mb: 2 }}>
                Issue detected: You're logged in as superadmin@request.lk but the system shows role as "{userRole}". 
                This means the UID mapping is broken.
              </Alert>
              
              <Button 
                variant="contained" 
                color="primary"
                onClick={fixSuperAdminUID}
                disabled={fixing}
              >
                {fixing ? 'Fixing...' : '🔧 Fix Super Admin UID'}
              </Button>
            </Box>
          )}
          
          {message && (
            <Alert severity={message.includes('✅') ? 'success' : 'error'} sx={{ mt: 2 }}>
              {message}
            </Alert>
          )}
        </CardContent>
      </Card>
    </Box>
  );
};

export default DebugAuth;
