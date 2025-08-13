import React, { useState, useEffect } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Switch,
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  Chip,
  Alert,
  Snackbar,
  Paper,
} from '@mui/material';
import { Add as AddIcon, Edit as EditIcon } from '@mui/icons-material';
import { collection, getDocs, addDoc, updateDoc, doc } from 'firebase/firestore';
import { db } from '../firebase/config';

// Predefined list of countries with codes and flags
const AVAILABLE_COUNTRIES = [
  { code: 'LK', name: 'Sri Lanka', flag: '🇱🇰', phoneCode: '+94' },
  { code: 'IN', name: 'India', flag: '🇮🇳', phoneCode: '+91' },
  { code: 'US', name: 'United States', flag: '🇺🇸', phoneCode: '+1' },
  { code: 'GB', name: 'United Kingdom', flag: '🇬🇧', phoneCode: '+44' },
  { code: 'AU', name: 'Australia', flag: '🇦🇺', phoneCode: '+61' },
  { code: 'CA', name: 'Canada', flag: '🇨🇦', phoneCode: '+1' },
  { code: 'DE', name: 'Germany', flag: '🇩🇪', phoneCode: '+49' },
  { code: 'FR', name: 'France', flag: '🇫🇷', phoneCode: '+33' },
  { code: 'AE', name: 'UAE', flag: '🇦🇪', phoneCode: '+971' },
  { code: 'MY', name: 'Malaysia', flag: '🇲🇾', phoneCode: '+60' },
  { code: 'SG', name: 'Singapore', flag: '🇸🇬', phoneCode: '+65' },
  { code: 'TH', name: 'Thailand', flag: '🇹🇭', phoneCode: '+66' },
];

const Countries = () => {
  const [countries, setCountries] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingCountry, setEditingCountry] = useState(null);
  const [selectedCountry, setSelectedCountry] = useState(null);
  const [comingSoonMessage, setComingSoonMessage] = useState('');
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });

  useEffect(() => {
    fetchCountries();
  }, []);

  const fetchCountries = async () => {
    try {
      const snapshot = await getDocs(collection(db, 'app_countries'));
      const countriesData = [];
      
      snapshot.forEach(doc => {
        countriesData.push({
          id: doc.id,
          ...doc.data()
        });
      });
      
      setCountries(countriesData);
    } catch (error) {
      console.error('Error fetching countries:', error);
      showSnackbar('Error fetching countries', 'error');
    } finally {
      setLoading(false);
    }
  };

  const showSnackbar = (message, severity = 'success') => {
    setSnackbar({ open: true, message, severity });
  };

  const handleToggleStatus = async (countryId, currentStatus) => {
    try {
      await updateDoc(doc(db, 'app_countries', countryId), {
        isEnabled: !currentStatus,
        updatedAt: new Date()
      });
      
      fetchCountries();
      showSnackbar(`Country ${!currentStatus ? 'enabled' : 'disabled'} successfully`);
    } catch (error) {
      console.error('Error updating country status:', error);
      showSnackbar('Error updating country status', 'error');
    }
  };

  const handleOpenDialog = (country = null) => {
    if (country) {
      setEditingCountry(country);
      const predefinedCountry = AVAILABLE_COUNTRIES.find(c => c.code === country.code);
      setSelectedCountry(predefinedCountry);
      setComingSoonMessage(country.comingSoonMessage || '');
    } else {
      setEditingCountry(null);
      setSelectedCountry(null);
      setComingSoonMessage('Coming soon to your country! Stay tuned for updates.');
    }
    setDialogOpen(true);
  };

  const handleSave = async () => {
    if (!selectedCountry) {
      showSnackbar('Please select a country', 'error');
      return;
    }

    try {
      const countryData = {
        code: selectedCountry.code,
        name: selectedCountry.name,
        flag: selectedCountry.flag,
        phoneCode: selectedCountry.phoneCode,
        isEnabled: true,
        comingSoonMessage,
        updatedAt: new Date()
      };

      if (editingCountry) {
        await updateDoc(doc(db, 'app_countries', editingCountry.id), countryData);
        showSnackbar('Country updated successfully');
      } else {
        // Check if country already exists
        const existingCountry = countries.find(c => c.code === selectedCountry.code);
        if (existingCountry) {
          showSnackbar('Country already exists', 'error');
          return;
        }
        
        await addDoc(collection(db, 'app_countries'), {
          ...countryData,
          createdAt: new Date()
        });
        showSnackbar('Country added successfully');
      }

      fetchCountries();
      setDialogOpen(false);
    } catch (error) {
      console.error('Error saving country:', error);
      showSnackbar('Error saving country', 'error');
    }
  };

  if (loading) {
    return (
      <Box sx={{ p: 3 }}>
        <Typography>Loading countries...</Typography>
      </Box>
    );
  }

  return (
    <Box sx={{ p: 3 }}>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
        <Typography variant="h4" component="h1">
          Country Management
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => handleOpenDialog()}
        >
          Add Country
        </Button>
      </Box>

      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            Supported Countries
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Manage which countries your app supports. Disabled countries will show "coming soon" message.
          </Typography>

          <TableContainer component={Paper}>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>Country</TableCell>
                  <TableCell>Code</TableCell>
                  <TableCell>Phone Code</TableCell>
                  <TableCell>Status</TableCell>
                  <TableCell>Coming Soon Message</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {countries.map((country) => (
                  <TableRow key={country.id}>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Typography variant="h6">{country.flag}</Typography>
                        <Typography>{country.name}</Typography>
                      </Box>
                    </TableCell>
                    <TableCell>{country.code}</TableCell>
                    <TableCell>{country.phoneCode}</TableCell>
                    <TableCell>
                      <Chip 
                        label={country.isEnabled ? 'Enabled' : 'Disabled'} 
                        color={country.isEnabled ? 'success' : 'default'}
                        size="small"
                      />
                    </TableCell>
                    <TableCell>
                      <Typography variant="body2" sx={{ maxWidth: 200, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                        {country.comingSoonMessage}
                      </Typography>
                    </TableCell>
                    <TableCell>
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Switch
                          checked={country.isEnabled}
                          onChange={() => handleToggleStatus(country.id, country.isEnabled)}
                          size="small"
                        />
                        <Button
                          size="small"
                          startIcon={<EditIcon />}
                          onClick={() => handleOpenDialog(country)}
                        >
                          Edit
                        </Button>
                      </Box>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>

          {countries.length === 0 && (
            <Alert severity="info" sx={{ mt: 2 }}>
              No countries configured yet. Add your first supported country to get started.
            </Alert>
          )}
        </CardContent>
      </Card>

      {/* Add/Edit Country Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          {editingCountry ? 'Edit Country' : 'Add Country'}
        </DialogTitle>
        <DialogContent>
          <Box sx={{ mt: 2 }}>
            <Typography variant="subtitle1" gutterBottom>
              Select Country
            </Typography>
            <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1, mb: 3 }}>
              {AVAILABLE_COUNTRIES
                .filter(country => !countries.find(c => c.code === country.code) || editingCountry?.code === country.code)
                .map((country) => (
                <Chip
                  key={country.code}
                  label={`${country.flag} ${country.name}`}
                  onClick={() => setSelectedCountry(country)}
                  color={selectedCountry?.code === country.code ? 'primary' : 'default'}
                  variant={selectedCountry?.code === country.code ? 'filled' : 'outlined'}
                />
              ))}
            </Box>

            {selectedCountry && (
              <Box sx={{ mb: 3, p: 2, bgcolor: 'grey.50', borderRadius: 1 }}>
                <Typography variant="subtitle2">Selected Country:</Typography>
                <Typography>{selectedCountry.flag} {selectedCountry.name} ({selectedCountry.code}) - {selectedCountry.phoneCode}</Typography>
              </Box>
            )}

            <TextField
              fullWidth
              label="Coming Soon Message"
              multiline
              rows={3}
              value={comingSoonMessage}
              onChange={(e) => setComingSoonMessage(e.target.value)}
              helperText="Message to show when country is disabled (coming soon)"
              sx={{ mb: 2 }}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancel</Button>
          <Button onClick={handleSave} variant="contained">
            {editingCountry ? 'Update' : 'Add'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar for notifications */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={6000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
      >
        <Alert 
          onClose={() => setSnackbar({ ...snackbar, open: false })} 
          severity={snackbar.severity}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default Countries;
