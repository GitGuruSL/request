import React, { useState, useEffect } from 'react';
import {
  Container,
  Typography,
  Card,
  CardContent,
  Button,
  Box,
  Chip,
  Grid,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Alert,
  Avatar,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  Divider,
  CircularProgress,
  Paper
} from '@mui/material';
import {
  Business as BusinessIcon,
  CheckCircle as ApproveIcon,
  Cancel as RejectIcon,
  Info as InfoIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  LocationOn as LocationIcon,
  Description as DescriptionIcon,
  AttachFile as AttachmentIcon,
  Visibility as ViewIcon
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import { db } from '../firebase/config';
import { 
  collection, 
  getDocs, 
  doc, 
  updateDoc,
  query,
  where,
  orderBy,
  Timestamp
} from 'firebase/firestore';

const BusinessVerification = () => {
  const { adminData, isCountryAdmin, isSuperAdmin } = useAuth();
  const [businesses, setBusinesses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedBusiness, setSelectedBusiness] = useState(null);
  const [detailsOpen, setDetailsOpen] = useState(false);
  const [actionDialog, setActionDialog] = useState({ open: false, action: null, business: null });
  const [actionLoading, setActionLoading] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');
  const [approvalNotes, setApprovalNotes] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');

  useEffect(() => {
    loadBusinesses();
  }, [filterStatus]);

  const loadBusinesses = async () => {
    try {
      setLoading(true);
      console.log('🔄 Loading businesses...');
      console.log('Admin data:', { isCountryAdmin, isSuperAdmin, country: adminData?.country });
      console.log('Filter status:', filterStatus);
      
      let businessQuery = collection(db, 'new_business_verifications');
      
      // Build query conditions
      const conditions = [];
      
      // Country-based filtering for country admins
      if (isCountryAdmin && adminData?.country) {
        conditions.push(where('country', '==', adminData.country));
        console.log('👤 Filtering by country:', adminData.country);
      }
      
      // Status filtering
      if (filterStatus !== 'all') {
        conditions.push(where('status', '==', filterStatus));
        console.log('🎯 Filtering by status:', filterStatus);
      }
      
      console.log('🔧 Query conditions:', conditions.length);
      
      // Apply conditions with ordering - only use orderBy if no complex conditions
      if (conditions.length === 0) {
        businessQuery = query(businessQuery, orderBy('createdAt', 'desc'));
      } else if (conditions.length === 1 && filterStatus !== 'all') {
        // Single status filter - can use orderBy
        businessQuery = query(businessQuery, ...conditions, orderBy('createdAt', 'desc'));
      } else {
        // Multiple conditions or country filter - skip orderBy for now to avoid index issues
        businessQuery = query(businessQuery, ...conditions);
      }

      const snapshot = await getDocs(businessQuery);
      console.log('📊 Found documents:', snapshot.docs.length);
      
      // Check for businesses missing country field and try to fix them
      const businessList = [];
      const missingCountryBusinesses = [];
      
      for (const docSnapshot of snapshot.docs) {
        const data = docSnapshot.data();
        const businessData = { id: docSnapshot.id, ...data };
        
        // Check if country field is missing
        if (!data.country && data.userId) {
          console.log(`⚠️ Business ${data.businessName} is missing country field`);
          missingCountryBusinesses.push({ docRef: docSnapshot.ref, data: businessData });
        }
        
        businessList.push(businessData);
      }
      
      // Auto-migrate businesses missing country field
      if (missingCountryBusinesses.length > 0 && isSuperAdmin) {
        console.log(`🔧 Found ${missingCountryBusinesses.length} businesses missing country field. Attempting to fix...`);
        
        for (const { docRef, data } of missingCountryBusinesses) {
          try {
            // Try to get user's country info
            const userDoc = await getDocs(query(collection(db, 'users'), where('__name__', '==', data.userId)));
            let countryToSet = 'LK'; // Default to Sri Lanka
            let countryNameToSet = 'Sri Lanka';
            
            if (!userDoc.empty) {
              const userData = userDoc.docs[0].data();
              if (userData.countryCode) {
                countryToSet = userData.countryCode;
                countryNameToSet = userData.countryName || 'Unknown';
              }
            }
            
            // Update the document
            await updateDoc(docRef, {
              country: countryToSet,
              countryName: countryNameToSet,
              updatedAt: Timestamp.now()
            });
            
            console.log(`✅ Updated ${data.businessName} with country: ${countryNameToSet} (${countryToSet})`);
            
            // Update the local data
            const businessIndex = businessList.findIndex(b => b.id === data.id);
            if (businessIndex !== -1) {
              businessList[businessIndex].country = countryToSet;
              businessList[businessIndex].countryName = countryNameToSet;
            }
          } catch (error) {
            console.error(`❌ Failed to update country for business ${data.businessName}:`, error);
          }
        }
        
        // Show success message
        if (missingCountryBusinesses.length > 0) {
          console.log(`✅ Successfully migrated ${missingCountryBusinesses.length} business(es) with missing country data`);
        }
      }
      
      // Sort client-side if we couldn't use orderBy in query
      businessList.sort((a, b) => {
        const aTime = a.createdAt?.toDate?.() || a.createdAt || new Date(0);
        const bTime = b.createdAt?.toDate?.() || b.createdAt || new Date(0);
        return bTime - aTime; // Descending order (newest first)
      });
      
      // Filter by country again after migration (in case some were just migrated)
      const filteredBusinesses = businessList.filter(business => {
        if (isCountryAdmin && adminData?.country) {
          return business.country === adminData.country;
        }
        return true;
      });
      
      setBusinesses(filteredBusinesses);
      console.log(`Loaded ${filteredBusinesses.length} businesses for verification`);
      console.log('Business list:', filteredBusinesses);
    } catch (error) {
      console.error('Error loading businesses:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAction = async (business, action) => {
    setActionDialog({ open: true, action, business });
    setRejectionReason('');
    setApprovalNotes('');
  };

  const executeAction = async () => {
    if (!actionDialog.business || !actionDialog.action) return;
    
    setActionLoading(true);
    try {
      const business = actionDialog.business;
      const action = actionDialog.action;
      
      const updateData = {
        status: action,
        verifiedAt: Timestamp.now(),
        verifiedBy: adminData?.email || 'Admin',
        verifierCountry: adminData?.country || 'Global'
      };
      
      if (action === 'approved') {
        updateData.approvalNotes = approvalNotes;
        updateData.isVerified = true;
      } else if (action === 'rejected') {
        updateData.rejectionReason = rejectionReason;
        updateData.isVerified = false;
      }
      
      await updateDoc(doc(db, 'new_business_verifications', business.id), updateData);
      
      // Refresh the list
      await loadBusinesses();
      
      setActionDialog({ open: false, action: null, business: null });
      console.log(`Business ${business.businessName} ${action} successfully`);
    } catch (error) {
      console.error(`Error ${actionDialog.action} business:`, error);
    } finally {
      setActionLoading(false);
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'approved': return 'success';
      case 'rejected': return 'error';
      case 'pending': return 'warning';
      default: return 'default';
    }
  };

  const getStatusIcon = (status) => {
    switch (status) {
      case 'approved': return <ApproveIcon />;
      case 'rejected': return <RejectIcon />;
      default: return <InfoIcon />;
    }
  };

  const openBusinessDetails = (business) => {
    setSelectedBusiness(business);
    setDetailsOpen(true);
  };

  if (loading) {
    return (
      <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
        <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
          <CircularProgress />
        </Box>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Box mb={4}>
        <Typography variant="h4" component="h1" gutterBottom>
          Business Verification
        </Typography>
        <Typography variant="body1" color="text.secondary">
          {isSuperAdmin 
            ? 'Manage business verifications from all countries'
            : `Manage business verifications for ${adminData?.country}`
          }
        </Typography>
      </Box>

      {/* Filter Controls */}
      <Paper sx={{ p: 2, mb: 3 }}>
        <Grid container spacing={2} alignItems="center">
          <Grid item xs={12} sm={6} md={3}>
            <FormControl fullWidth>
              <InputLabel>Status Filter</InputLabel>
              <Select
                value={filterStatus}
                label="Status Filter"
                onChange={(e) => setFilterStatus(e.target.value)}
              >
                <MenuItem value="all">All Status</MenuItem>
                <MenuItem value="pending">Pending</MenuItem>
                <MenuItem value="approved">Approved</MenuItem>
                <MenuItem value="rejected">Rejected</MenuItem>
              </Select>
            </FormControl>
          </Grid>
          <Grid item>
            <Button
              variant="outlined"
              onClick={loadBusinesses}
              disabled={loading}
            >
              Refresh
            </Button>
          </Grid>
        </Grid>
      </Paper>

      {/* Businesses List */}
      {businesses.length === 0 ? (
        <Alert severity="info">
          No businesses found for verification.
        </Alert>
      ) : (
        <List>
          {businesses.map((business) => (
            <Card key={business.id} sx={{ mb: 2 }}>
              <ListItem alignItems="flex-start">
                <ListItemAvatar>
                  <Avatar sx={{ bgcolor: 'primary.main' }}>
                    <BusinessIcon />
                  </Avatar>
                </ListItemAvatar>
                <ListItemText
                  primary={
                    <Box display="flex" alignItems="center" gap={1}>
                      <Typography variant="h6" component="span">
                        {business.businessName || 'Unnamed Business'}
                      </Typography>
                      <Chip 
                        label={business.status || 'pending'}
                        color={getStatusColor(business.status)}
                        size="small"
                        icon={getStatusIcon(business.status)}
                      />
                    </Box>
                  }
                  secondary={
                    <Box mt={1}>
                      <Typography variant="body2" color="text.secondary">
                        <LocationIcon sx={{ fontSize: 16, mr: 0.5, verticalAlign: 'middle' }} />
                        {business.country || 'Unknown'} • {business.city || 'Unknown City'}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        <EmailIcon sx={{ fontSize: 16, mr: 0.5, verticalAlign: 'middle' }} />
                        {business.email || 'No email'}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        <PhoneIcon sx={{ fontSize: 16, mr: 0.5, verticalAlign: 'middle' }} />
                        {business.phoneNumber || 'No phone'}
                      </Typography>
                      <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                        Applied: {business.createdAt?.toDate?.()?.toLocaleDateString() || 'Unknown'}
                      </Typography>
                    </Box>
                  }
                />
                <ListItemSecondaryAction>
                  <Box display="flex" gap={1}>
                    <IconButton
                      color="info"
                      onClick={() => openBusinessDetails(business)}
                      title="View Details"
                    >
                      <ViewIcon />
                    </IconButton>
                    {business.status === 'pending' && (
                      <>
                        <IconButton
                          color="success"
                          onClick={() => handleAction(business, 'approved')}
                          title="Approve"
                        >
                          <ApproveIcon />
                        </IconButton>
                        <IconButton
                          color="error"
                          onClick={() => handleAction(business, 'rejected')}
                          title="Reject"
                        >
                          <RejectIcon />
                        </IconButton>
                      </>
                    )}
                  </Box>
                </ListItemSecondaryAction>
              </ListItem>
            </Card>
          ))}
        </List>
      )}

      {/* Business Details Dialog */}
      <Dialog
        open={detailsOpen}
        onClose={() => setDetailsOpen(false)}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>Business Details</DialogTitle>
        <DialogContent>
          {selectedBusiness && (
            <Grid container spacing={3}>
              <Grid item xs={12}>
                <Typography variant="h6" gutterBottom>
                  {selectedBusiness.businessName || 'Unnamed Business'}
                </Typography>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" color="text.secondary">Contact Information</Typography>
                <Box mt={1}>
                  <Typography variant="body2">Email: {selectedBusiness.email || 'Not provided'}</Typography>
                  <Typography variant="body2">Phone: {selectedBusiness.phoneNumber || 'Not provided'}</Typography>
                  <Typography variant="body2">Country: {selectedBusiness.country || 'Not provided'}</Typography>
                  <Typography variant="body2">City: {selectedBusiness.city || 'Not provided'}</Typography>
                </Box>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" color="text.secondary">Business Information</Typography>
                <Box mt={1}>
                  <Typography variant="body2">Type: {selectedBusiness.businessType || 'Not specified'}</Typography>
                  <Typography variant="body2">Registration: {selectedBusiness.registrationNumber || 'Not provided'}</Typography>
                  <Typography variant="body2">Tax ID: {selectedBusiness.taxId || 'Not provided'}</Typography>
                </Box>
              </Grid>
              
              {selectedBusiness.description && (
                <Grid item xs={12}>
                  <Typography variant="subtitle2" color="text.secondary">Description</Typography>
                  <Typography variant="body2" sx={{ mt: 1 }}>
                    {selectedBusiness.description}
                  </Typography>
                </Grid>
              )}
              
              <Grid item xs={12}>
                <Typography variant="subtitle2" color="text.secondary">Verification Status</Typography>
                <Box mt={1} display="flex" alignItems="center" gap={1}>
                  <Chip 
                    label={selectedBusiness.status || 'pending'}
                    color={getStatusColor(selectedBusiness.status)}
                    icon={getStatusIcon(selectedBusiness.status)}
                  />
                  {selectedBusiness.verifiedAt && (
                    <Typography variant="body2" color="text.secondary">
                      Verified on {selectedBusiness.verifiedAt.toDate().toLocaleDateString()}
                    </Typography>
                  )}
                </Box>
              </Grid>
              
              {selectedBusiness.rejectionReason && (
                <Grid item xs={12}>
                  <Alert severity="error">
                    <strong>Rejection Reason:</strong> {selectedBusiness.rejectionReason}
                  </Alert>
                </Grid>
              )}
              
              {selectedBusiness.approvalNotes && (
                <Grid item xs={12}>
                  <Alert severity="success">
                    <strong>Approval Notes:</strong> {selectedBusiness.approvalNotes}
                  </Alert>
                </Grid>
              )}
            </Grid>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDetailsOpen(false)}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Action Confirmation Dialog */}
      <Dialog open={actionDialog.open} onClose={() => setActionDialog({ open: false, action: null, business: null })}>
        <DialogTitle>
          {actionDialog.action === 'approved' ? 'Approve Business' : 'Reject Business'}
        </DialogTitle>
        <DialogContent>
          <Typography variant="body1" gutterBottom>
            Are you sure you want to {actionDialog.action === 'approved' ? 'approve' : 'reject'}{' '}
            <strong>{actionDialog.business?.businessName}</strong>?
          </Typography>
          
          {actionDialog.action === 'approved' && (
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Approval Notes (Optional)"
              value={approvalNotes}
              onChange={(e) => setApprovalNotes(e.target.value)}
              sx={{ mt: 2 }}
            />
          )}
          
          {actionDialog.action === 'rejected' && (
            <TextField
              fullWidth
              multiline
              rows={3}
              label="Rejection Reason"
              value={rejectionReason}
              onChange={(e) => setRejectionReason(e.target.value)}
              required
              sx={{ mt: 2 }}
            />
          )}
        </DialogContent>
        <DialogActions>
          <Button 
            onClick={() => setActionDialog({ open: false, action: null, business: null })}
            disabled={actionLoading}
          >
            Cancel
          </Button>
          <Button
            onClick={executeAction}
            color={actionDialog.action === 'approved' ? 'success' : 'error'}
            variant="contained"
            disabled={actionLoading || (actionDialog.action === 'rejected' && !rejectionReason.trim())}
          >
            {actionLoading ? <CircularProgress size={20} /> : `${actionDialog.action === 'approved' ? 'Approve' : 'Reject'}`}
          </Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
};

export default BusinessVerification;
