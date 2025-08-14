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
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  ImageList,
  ImageListItem
} from '@mui/material';
import {
  DirectionsCar as DriverIcon,
  CheckCircle as ApproveIcon,
  Cancel as RejectIcon,
  Info as InfoIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  LocationOn as LocationIcon,
  Description as DescriptionIcon,
  AttachFile as AttachmentIcon,
  Visibility as ViewIcon,
  Person as PersonIcon,
  DriveEta as VehicleIcon,
  Assignment as LicenseIcon,
  Image as ImageIcon
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

const DriverVerification = () => {
  const { adminData, isCountryAdmin, isSuperAdmin } = useAuth();
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedDriver, setSelectedDriver] = useState(null);
  const [detailsOpen, setDetailsOpen] = useState(false);
  const [actionDialog, setActionDialog] = useState({ open: false, action: null, driver: null });
  const [actionLoading, setActionLoading] = useState(false);
  const [rejectionReason, setRejectionReason] = useState('');
  const [approvalNotes, setApprovalNotes] = useState('');
  const [filterStatus, setFilterStatus] = useState('all');
  const [imageDialog, setImageDialog] = useState({ open: false, imageUrl: '', title: '' });

  useEffect(() => {
    loadDrivers();
  }, [filterStatus]);

  const loadDrivers = async () => {
    try {
      setLoading(true);
      let driverQuery = collection(db, 'driver_verification');
      
      // Country-based filtering for country admins
      const conditions = [];
      if (isCountryAdmin && adminData?.country) {
        conditions.push(where('country', '==', adminData.country));
      }
      
      // Status filtering
      if (filterStatus !== 'all') {
        conditions.push(where('verificationStatus', '==', filterStatus));
      }
      
      if (conditions.length > 0) {
        driverQuery = query(driverQuery, ...conditions, orderBy('createdAt', 'desc'));
      } else {
        driverQuery = query(driverQuery, orderBy('createdAt', 'desc'));
      }
      
      const snapshot = await getDocs(driverQuery);
      const driverList = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      
      setDrivers(driverList);
      console.log(`Loaded ${driverList.length} drivers for verification`);
    } catch (error) {
      console.error('Error loading drivers:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleAction = async (driver, action) => {
    setActionDialog({ open: true, action, driver });
    setRejectionReason('');
    setApprovalNotes('');
  };

  const executeAction = async () => {
    if (!actionDialog.driver || !actionDialog.action) return;
    
    setActionLoading(true);
    try {
      const driver = actionDialog.driver;
      const action = actionDialog.action;
      
      const updateData = {
        verificationStatus: action,
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
      
      await updateDoc(doc(db, 'driver_verification', driver.id), updateData);
      
      // Refresh the list
      await loadDrivers();
      
      setActionDialog({ open: false, action: null, driver: null });
      console.log(`Driver ${driver.fullName} ${action} successfully`);
    } catch (error) {
      console.error(`Error ${actionDialog.action} driver:`, error);
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

  const openDriverDetails = (driver) => {
    setSelectedDriver(driver);
    setDetailsOpen(true);
  };

  const openImageDialog = (imageUrl, title) => {
    setImageDialog({ open: true, imageUrl, title });
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
          Driver Verification
        </Typography>
        <Typography variant="body1" color="text.secondary">
          {isSuperAdmin 
            ? 'Manage driver verifications from all countries'
            : `Manage driver verifications for ${adminData?.country}`
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
              onClick={loadDrivers}
              disabled={loading}
            >
              Refresh
            </Button>
          </Grid>
        </Grid>
      </Paper>

      {/* Drivers List */}
      {drivers.length === 0 ? (
        <Alert severity="info">
          No drivers found for verification.
        </Alert>
      ) : (
        <List>
          {drivers.map((driver) => (
            <Card key={driver.id} sx={{ mb: 2 }}>
              <ListItem alignItems="flex-start">
                <ListItemAvatar>
                  <Avatar sx={{ bgcolor: 'primary.main' }}>
                    <DriverIcon />
                  </Avatar>
                </ListItemAvatar>
                <ListItemText
                  primary={
                    <Box display="flex" alignItems="center" gap={1}>
                      <Typography variant="h6" component="span">
                        {driver.fullName || 'Unnamed Driver'}
                      </Typography>
                      <Chip 
                        label={driver.verificationStatus || 'pending'}
                        color={getStatusColor(driver.verificationStatus)}
                        size="small"
                        icon={getStatusIcon(driver.verificationStatus)}
                      />
                    </Box>
                  }
                  secondary={
                    <Box mt={1}>
                      <Typography variant="body2" color="text.secondary">
                        <LocationIcon sx={{ fontSize: 16, mr: 0.5, verticalAlign: 'middle' }} />
                        {driver.country || 'Unknown'} • {driver.city || 'Unknown City'}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        <EmailIcon sx={{ fontSize: 16, mr: 0.5, verticalAlign: 'middle' }} />
                        {driver.email || 'No email'}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        <PhoneIcon sx={{ fontSize: 16, mr: 0.5, verticalAlign: 'middle' }} />
                        {driver.phoneNumber || 'No phone'}
                      </Typography>
                      <Typography variant="body2" color="text.secondary">
                        <LicenseIcon sx={{ fontSize: 16, mr: 0.5, verticalAlign: 'middle' }} />
                        License: {driver.licenseNumber || 'Not provided'}
                      </Typography>
                      <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                        Applied: {driver.createdAt?.toDate?.()?.toLocaleDateString() || 'Unknown'}
                      </Typography>
                    </Box>
                  }
                />
                <ListItemSecondaryAction>
                  <Box display="flex" gap={1}>
                    <IconButton
                      color="info"
                      onClick={() => openDriverDetails(driver)}
                      title="View Details"
                    >
                      <ViewIcon />
                    </IconButton>
                    {driver.verificationStatus === 'pending' && (
                      <>
                        <IconButton
                          color="success"
                          onClick={() => handleAction(driver, 'approved')}
                          title="Approve"
                        >
                          <ApproveIcon />
                        </IconButton>
                        <IconButton
                          color="error"
                          onClick={() => handleAction(driver, 'rejected')}
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

      {/* Driver Details Dialog */}
      <Dialog
        open={detailsOpen}
        onClose={() => setDetailsOpen(false)}
        maxWidth="lg"
        fullWidth
      >
        <DialogTitle>Driver Details</DialogTitle>
        <DialogContent>
          {selectedDriver && (
            <Grid container spacing={3}>
              <Grid item xs={12}>
                <Typography variant="h6" gutterBottom>
                  {selectedDriver.fullName || 'Unnamed Driver'}
                </Typography>
              </Grid>
              
              {/* Personal Information */}
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  <PersonIcon sx={{ fontSize: 16, mr: 0.5, verticalAlign: 'middle' }} />
                  Personal Information
                </Typography>
                <Box mt={1}>
                  <Typography variant="body2">Email: {selectedDriver.email || 'Not provided'}</Typography>
                  <Typography variant="body2">Phone: {selectedDriver.phoneNumber || 'Not provided'}</Typography>
                  <Typography variant="body2">Country: {selectedDriver.country || 'Not provided'}</Typography>
                  <Typography variant="body2">City: {selectedDriver.city || 'Not provided'}</Typography>
                  <Typography variant="body2">Age: {selectedDriver.age || 'Not provided'}</Typography>
                  <Typography variant="body2">Experience: {selectedDriver.drivingExperience || 'Not provided'} years</Typography>
                </Box>
              </Grid>
              
              {/* License Information */}
              <Grid item xs={12} md={6}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  <LicenseIcon sx={{ fontSize: 16, mr: 0.5, verticalAlign: 'middle' }} />
                  License Information
                </Typography>
                <Box mt={1}>
                  <Typography variant="body2">License Number: {selectedDriver.licenseNumber || 'Not provided'}</Typography>
                  <Typography variant="body2">License Type: {selectedDriver.licenseType || 'Not specified'}</Typography>
                  <Typography variant="body2">Issue Date: {selectedDriver.licenseIssueDate || 'Not provided'}</Typography>
                  <Typography variant="body2">Expiry Date: {selectedDriver.licenseExpiryDate || 'Not provided'}</Typography>
                </Box>
              </Grid>
              
              {/* Vehicle Information */}
              {(selectedDriver.vehicleMake || selectedDriver.vehicleModel) && (
                <Grid item xs={12}>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                    <VehicleIcon sx={{ fontSize: 16, mr: 0.5, verticalAlign: 'middle' }} />
                    Vehicle Information
                  </Typography>
                  <TableContainer component={Paper} variant="outlined">
                    <Table size="small">
                      <TableBody>
                        {selectedDriver.vehicleMake && (
                          <TableRow>
                            <TableCell><strong>Make</strong></TableCell>
                            <TableCell>{selectedDriver.vehicleMake}</TableCell>
                          </TableRow>
                        )}
                        {selectedDriver.vehicleModel && (
                          <TableRow>
                            <TableCell><strong>Model</strong></TableCell>
                            <TableCell>{selectedDriver.vehicleModel}</TableCell>
                          </TableRow>
                        )}
                        {selectedDriver.vehicleYear && (
                          <TableRow>
                            <TableCell><strong>Year</strong></TableCell>
                            <TableCell>{selectedDriver.vehicleYear}</TableCell>
                          </TableRow>
                        )}
                        {selectedDriver.vehicleColor && (
                          <TableRow>
                            <TableCell><strong>Color</strong></TableCell>
                            <TableCell>{selectedDriver.vehicleColor}</TableCell>
                          </TableRow>
                        )}
                        {selectedDriver.vehiclePlateNumber && (
                          <TableRow>
                            <TableCell><strong>Plate Number</strong></TableCell>
                            <TableCell>{selectedDriver.vehiclePlateNumber}</TableCell>
                          </TableRow>
                        )}
                      </TableBody>
                    </Table>
                  </TableContainer>
                </Grid>
              )}
              
              {/* Document Images */}
              {(selectedDriver.licenseImageUrl || selectedDriver.profileImageUrl || selectedDriver.vehicleImageUrl) && (
                <Grid item xs={12}>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                    <ImageIcon sx={{ fontSize: 16, mr: 0.5, verticalAlign: 'middle' }} />
                    Documents & Images
                  </Typography>
                  <Box mt={1}>
                    <Grid container spacing={2}>
                      {selectedDriver.profileImageUrl && (
                        <Grid item xs={6} sm={4} md={3}>
                          <Paper
                            sx={{ 
                              p: 2, 
                              textAlign: 'center', 
                              cursor: 'pointer',
                              '&:hover': { bgcolor: 'action.hover' }
                            }}
                            onClick={() => openImageDialog(selectedDriver.profileImageUrl, 'Profile Photo')}
                          >
                            <PersonIcon sx={{ fontSize: 40, color: 'primary.main' }} />
                            <Typography variant="caption" display="block">Profile Photo</Typography>
                          </Paper>
                        </Grid>
                      )}
                      {selectedDriver.licenseImageUrl && (
                        <Grid item xs={6} sm={4} md={3}>
                          <Paper
                            sx={{ 
                              p: 2, 
                              textAlign: 'center', 
                              cursor: 'pointer',
                              '&:hover': { bgcolor: 'action.hover' }
                            }}
                            onClick={() => openImageDialog(selectedDriver.licenseImageUrl, 'Driver License')}
                          >
                            <LicenseIcon sx={{ fontSize: 40, color: 'primary.main' }} />
                            <Typography variant="caption" display="block">Driver License</Typography>
                          </Paper>
                        </Grid>
                      )}
                      {selectedDriver.vehicleImageUrl && (
                        <Grid item xs={6} sm={4} md={3}>
                          <Paper
                            sx={{ 
                              p: 2, 
                              textAlign: 'center', 
                              cursor: 'pointer',
                              '&:hover': { bgcolor: 'action.hover' }
                            }}
                            onClick={() => openImageDialog(selectedDriver.vehicleImageUrl, 'Vehicle Photo')}
                          >
                            <VehicleIcon sx={{ fontSize: 40, color: 'primary.main' }} />
                            <Typography variant="caption" display="block">Vehicle Photo</Typography>
                          </Paper>
                        </Grid>
                      )}
                    </Grid>
                  </Box>
                </Grid>
              )}
              
              {/* Verification Status */}
              <Grid item xs={12}>
                <Typography variant="subtitle2" color="text.secondary">Verification Status</Typography>
                <Box mt={1} display="flex" alignItems="center" gap={1}>
                  <Chip 
                    label={selectedDriver.verificationStatus || 'pending'}
                    color={getStatusColor(selectedDriver.verificationStatus)}
                    icon={getStatusIcon(selectedDriver.verificationStatus)}
                  />
                  {selectedDriver.verifiedAt && (
                    <Typography variant="body2" color="text.secondary">
                      Verified on {selectedDriver.verifiedAt.toDate().toLocaleDateString()}
                    </Typography>
                  )}
                </Box>
              </Grid>
              
              {selectedDriver.rejectionReason && (
                <Grid item xs={12}>
                  <Alert severity="error">
                    <strong>Rejection Reason:</strong> {selectedDriver.rejectionReason}
                  </Alert>
                </Grid>
              )}
              
              {selectedDriver.approvalNotes && (
                <Grid item xs={12}>
                  <Alert severity="success">
                    <strong>Approval Notes:</strong> {selectedDriver.approvalNotes}
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

      {/* Image Viewer Dialog */}
      <Dialog
        open={imageDialog.open}
        onClose={() => setImageDialog({ open: false, imageUrl: '', title: '' })}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>{imageDialog.title}</DialogTitle>
        <DialogContent>
          <Box display="flex" justifyContent="center" alignItems="center" minHeight="400px">
            <img
              src={imageDialog.imageUrl}
              alt={imageDialog.title}
              style={{
                maxWidth: '100%',
                maxHeight: '80vh',
                objectFit: 'contain'
              }}
              onError={(e) => {
                e.target.style.display = 'none';
                e.target.nextSibling.style.display = 'block';
              }}
            />
            <Box style={{ display: 'none' }} textAlign="center">
              <ImageIcon sx={{ fontSize: 60, color: 'text.secondary' }} />
              <Typography variant="body2" color="text.secondary">
                Image could not be loaded
              </Typography>
            </Box>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setImageDialog({ open: false, imageUrl: '', title: '' })}>Close</Button>
        </DialogActions>
      </Dialog>

      {/* Action Confirmation Dialog */}
      <Dialog open={actionDialog.open} onClose={() => setActionDialog({ open: false, action: null, driver: null })}>
        <DialogTitle>
          {actionDialog.action === 'approved' ? 'Approve Driver' : 'Reject Driver'}
        </DialogTitle>
        <DialogContent>
          <Typography variant="body1" gutterBottom>
            Are you sure you want to {actionDialog.action === 'approved' ? 'approve' : 'reject'}{' '}
            <strong>{actionDialog.driver?.fullName}</strong>?
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
            onClick={() => setActionDialog({ open: false, action: null, driver: null })}
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

export default DriverVerification;
