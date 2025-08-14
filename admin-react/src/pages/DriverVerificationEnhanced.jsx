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
  IconButton,
  CircularProgress,
  Tabs,
  Tab,
  CardHeader,
  CardMedia,
  CardActions
} from '@mui/material';
import {
  Person as PersonIcon,
  CheckCircle as ApproveIcon,
  Cancel as RejectIcon,
  Visibility as ViewIcon,
  Phone as PhoneIcon,
  Email as EmailIcon,
  LocationOn as LocationIcon,
  DriveEta as CarIcon,
  Image as ImageIcon,
  CheckCircleOutline as CheckIcon,
  RadioButtonUnchecked as PendingIcon,
  Error as ErrorIcon,
  Assignment as AssignmentIcon,
  Description as DescriptionIcon,
  Security as SecurityIcon,
  TwoWheeler,
  DirectionsCar,
  LocalTaxi,
  AirportShuttle,
  People,
  LocalShipping,
  Download as DownloadIcon,
  Launch as LaunchIcon,
  Store as StoreIcon,
  ContactPhone as ContactIcon,
  CalendarToday as CalendarIcon,
  Category as CategoryIcon,
  Assessment as ReportsIcon,
  VerifiedUser as VerifiedIcon,
  AccessTime as TimeIcon,
  Language as WebsiteIcon,
  Map as MapIcon,
  PhotoLibrary as GalleryIcon,
  PictureAsPdf as PdfIcon,
  InsertDriveFile as FileIcon,
  CloudDownload as CloudIcon,
  Fullscreen as FullscreenIcon,
  Close as CloseIcon,
  Warning as WarningIcon,
  Info as InfoIcon
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
  Timestamp,
  getDoc
} from 'firebase/firestore';

const DriverVerificationEnhanced = () => {
  const { adminData, isCountryAdmin, isSuperAdmin } = useAuth();
  const [drivers, setDrivers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedDriver, setSelectedDriver] = useState(null);
  const [detailsOpen, setDetailsOpen] = useState(false);
  const [filterStatus, setFilterStatus] = useState('all');
  const [tabValue, setTabValue] = useState(0);
  
  // Document verification states
  const [rejectionDialog, setRejectionDialog] = useState({ open: false, target: null, type: '' });
  const [rejectionReason, setRejectionReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [fullscreenImage, setFullscreenImage] = useState({ open: false, url: '', title: '' });

  useEffect(() => {
    loadDrivers();
  }, [filterStatus]);

  const loadDrivers = async () => {
    try {
      setLoading(true);
      console.log('🔄 Loading drivers...');
      
      let driverQuery = collection(db, 'new_driver_verifications');
      const conditions = [];
      
      // Country-based filtering for country admins
      if (isCountryAdmin && adminData?.country) {
        conditions.push(where('country', '==', adminData.country));
      }
      
      // Status filtering
      if (filterStatus !== 'all') {
        conditions.push(where('status', '==', filterStatus));
      }
      
      if (conditions.length > 0) {
        driverQuery = query(driverQuery, ...conditions);
      }

      const snapshot = await getDocs(driverQuery);
      const driverList = [];
      const missingCountryDrivers = [];
      
      for (const docSnapshot of snapshot.docs) {
        const data = docSnapshot.data();
        const driverData = { id: docSnapshot.id, ...data };
        
        // Auto-migrate missing country field
        if (!data.country && data.userId && isSuperAdmin) {
          missingCountryDrivers.push({ docRef: docSnapshot.ref, data: driverData });
        }
        
        driverList.push(driverData);
      }
      
      // Fix missing country data
      for (const { docRef, data } of missingCountryDrivers) {
        try {
          const userDoc = await getDoc(doc(db, 'users', data.userId));
          let countryToSet = 'LK';
          let countryNameToSet = 'Sri Lanka';
          
          if (userDoc.exists()) {
            const userData = userDoc.data();
            if (userData.countryCode) {
              countryToSet = userData.countryCode;
              countryNameToSet = userData.countryName || 'Unknown';
            }
          }
          
          await updateDoc(docRef, {
            country: countryToSet,
            countryName: countryNameToSet,
            updatedAt: Timestamp.now()
          });
          
          const driverIndex = driverList.findIndex(d => d.id === data.id);
          if (driverIndex !== -1) {
            driverList[driverIndex].country = countryToSet;
            driverList[driverIndex].countryName = countryNameToSet;
          }
        } catch (error) {
          console.error(`Failed to update country for driver ${data.fullName}:`, error);
        }
      }
      
      // Sort by created date
      driverList.sort((a, b) => {
        const aTime = a.submittedAt?.toDate?.() || a.createdAt?.toDate?.() || new Date(0);
        const bTime = b.submittedAt?.toDate?.() || b.createdAt?.toDate?.() || new Date(0);
        return bTime - aTime;
      });
      
      setDrivers(driverList);
      console.log(`Loaded ${driverList.length} drivers`);
    } catch (error) {
      console.error('Error loading drivers:', error);
    } finally {
      setLoading(false);
    }
  };

  const getStatusColor = (status) => {
    switch (status?.toLowerCase()) {
      case 'approved': return 'success';
      case 'rejected': return 'error';
      case 'pending': return 'warning';
      default: return 'default';
    }
  };

  const getStatusIcon = (status) => {
    switch (status?.toLowerCase()) {
      case 'approved': return <CheckIcon />;
      case 'rejected': return <ErrorIcon />;
      case 'pending': return <PendingIcon />;
      default: return <PendingIcon />;
    }
  };

  const getDocumentStatus = (driver, docType) => {
    const docVerification = driver.documentVerification?.[docType];
    if (docVerification?.status) return docVerification.status;
    
    // Fallback to flat status fields
    switch (docType) {
      case 'licenseImage': return driver.licenseImageStatus || 'pending';
      case 'idImage': return driver.idImageStatus || 'pending';
      case 'vehicleRegistration': return driver.vehicleRegistrationStatus || 'pending';
      case 'profileImage': return driver.profileImageStatus || 'pending';
      // Support for new document types
      case 'driverImage': return driver.driverImageStatus || 'pending';
      case 'licenseFront': return driver.licenseFrontStatus || 'pending';
      case 'licenseBack': return driver.licenseBackStatus || 'pending';
      case 'vehicleInsurance': return driver.vehicleInsuranceStatus || 'pending';
      default: return 'pending';
    }
  };

  const getVehicleIcon = (vehicleType) => {
    switch (vehicleType?.toLowerCase()) {
      case 'bicycle':
      case 'bike':
        return <TwoWheeler sx={{ fontSize: 40 }} />;
      case 'car':
      case 'sedan':
      case 'hatchback':
        return <DirectionsCar sx={{ fontSize: 40 }} />;
      case 'taxi':
        return <LocalTaxi sx={{ fontSize: 40 }} />;
      case 'van':
      case 'minivan':
        return <AirportShuttle sx={{ fontSize: 40 }} />;
      case 'bus':
        return <People sx={{ fontSize: 40 }} />;
      case 'truck':
        return <LocalShipping sx={{ fontSize: 40 }} />;
      default:
        return <CarIcon sx={{ fontSize: 40 }} />;
    }
  };

  const getDocumentUrl = (driver, docType) => {
    switch (docType) {
      case 'licenseImage': return driver.licenseImageUrl;
      case 'idImage': return driver.idImageUrl;
      case 'vehicleRegistration': return driver.vehicleRegistrationUrl;
      case 'profileImage': return driver.profileImageUrl;
      // Support for new document types
      case 'driverImage': return driver.driverImageUrl;
      case 'licenseFront': return driver.licenseFrontUrl;
      case 'licenseBack': return driver.licenseBackUrl;
      case 'licenseDocument': return driver.licenseDocumentUrl;
      case 'vehicleInsurance': return driver.vehicleInsuranceUrl;
      default: return null;
    }
  };

  const handleDocumentAction = async (driver, docType, action) => {
    if (action === 'reject') {
      setRejectionDialog({ 
        open: true, 
        target: driver,
        type: 'document',
        docType: docType
      });
      return;
    }

    setActionLoading(true);
    try {
      const updateData = {
        [`documentVerification.${docType}.status`]: action,
        [`${docType}Status`]: action,
        updatedAt: Timestamp.now()
      };

      if (action === 'approved') {
        updateData[`documentVerification.${docType}.approvedAt`] = Timestamp.now();
      }

      await updateDoc(doc(db, 'new_driver_verifications', driver.id), updateData);
      await loadDrivers(); // Refresh data
      console.log(`✅ Document ${docType} ${action} for ${driver.fullName}`);
    } catch (error) {
      console.error(`Error updating document status:`, error);
    } finally {
      setActionLoading(false);
    }
  };

  const handleDriverAction = async (driver, action) => {
    if (action === 'reject') {
      setRejectionDialog({ 
        open: true, 
        target: driver,
        type: 'driver'
      });
      return;
    }

    if (action === 'approve') {
      // Check if all documents are approved
      const docTypes = ['licenseImage', 'idImage', 'vehicleRegistration', 'profileImage'];
      const allDocsApproved = docTypes.every(docType => {
        const status = getDocumentStatus(driver, docType);
        const url = getDocumentUrl(driver, docType);
        return !url || status === 'approved'; // Skip missing documents
      });

      if (!allDocsApproved) {
        alert('All submitted documents must be approved before approving the driver.');
        return;
      }

      // Check contact verification (similar to business verification)
      try {
        const userDoc = await getDoc(doc(db, 'users', driver.userId));
        if (userDoc.exists()) {
          const userData = userDoc.data();
          const linkedCredentials = userData.linkedCredentials || {};
          const phoneVerified = linkedCredentials.linkedPhoneVerified || false;
          const emailVerified = linkedCredentials.linkedEmailVerified || false;

          if (!phoneVerified || !emailVerified) {
            const missing = [];
            if (!phoneVerified) missing.push('phone');
            if (!emailVerified) missing.push('email');
            alert(`Cannot approve driver. User must verify: ${missing.join(', ')}`);
            return;
          }
        }
      } catch (error) {
        console.error('Error checking contact verification:', error);
      }
    }

    setActionLoading(true);
    try {
      const updateData = {
        status: action,
        updatedAt: Timestamp.now()
      };

      if (action === 'approved') {
        updateData.approvedAt = Timestamp.now();
        updateData.isVerified = true;
      }

      await updateDoc(doc(db, 'new_driver_verifications', driver.id), updateData);
      await loadDrivers();
      console.log(`✅ Driver ${action}: ${driver.fullName}`);
    } catch (error) {
      console.error(`Error ${action} driver:`, error);
    } finally {
      setActionLoading(false);
    }
  };

  const handleRejection = async () => {
    if (!rejectionReason.trim()) {
      alert('Please provide a reason for rejection');
      return;
    }

    const { target, type, docType } = rejectionDialog;
    setActionLoading(true);

    try {
      let updateData = {
        updatedAt: Timestamp.now()
      };

      if (type === 'document') {
        updateData[`documentVerification.${docType}.status`] = 'rejected';
        updateData[`documentVerification.${docType}.rejectionReason`] = rejectionReason;
        updateData[`documentVerification.${docType}.rejectedAt`] = Timestamp.now();
        updateData[`${docType}Status`] = 'rejected';
        updateData[`${docType}RejectionReason`] = rejectionReason;
      } else {
        updateData.status = 'rejected';
        updateData.rejectionReason = rejectionReason;
        updateData.rejectedAt = Timestamp.now();
        updateData.isVerified = false;
      }

      await updateDoc(doc(db, 'new_driver_verifications', target.id), updateData);
      await loadDrivers();
      
      setRejectionDialog({ open: false, target: null, type: '' });
      setRejectionReason('');
      console.log(`✅ ${type} rejected: ${target.fullName}`);
    } catch (error) {
      console.error(`Error rejecting ${type}:`, error);
    } finally {
      setActionLoading(false);
    }
  };

  const viewDocument = (url, title = 'Document') => {
    if (url) {
      setFullscreenImage({ open: true, url, title });
    }
  };

  const renderDriverCard = (driver) => {
    const overallStatus = driver.status || 'pending';
    const documentsCount = ['licenseImage', 'idImage', 'vehicleRegistration', 'profileImage']
      .filter(docType => getDocumentUrl(driver, docType)).length;
    const approvedDocsCount = ['licenseImage', 'idImage', 'vehicleRegistration', 'profileImage']
      .filter(docType => {
        const url = getDocumentUrl(driver, docType);
        const status = getDocumentStatus(driver, docType);
        return url && status === 'approved';
      }).length;

    return (
      <Card key={driver.id} sx={{ mb: 2 }}>
        <CardContent>
          <Box display="flex" justifyContent="space-between" alignItems="flex-start">
            <Box flex={1}>
              <Box display="flex" alignItems="center" gap={1} mb={1}>
                <PersonIcon color="primary" />
                <Typography variant="h6">{driver.fullName || 'Unknown Driver'}</Typography>
                <Chip 
                  label={overallStatus}
                  color={getStatusColor(overallStatus)}
                  size="small"
                  icon={getStatusIcon(overallStatus)}
                />
              </Box>
              
              <Grid container spacing={1} sx={{ mb: 2 }}>
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <LocationIcon fontSize="small" color="action" />
                    <Typography variant="body2">{driver.country || 'Unknown'} • {driver.address || 'No address'}</Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <EmailIcon fontSize="small" color="action" />
                    <Typography variant="body2">{driver.email || 'No email'}</Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <PhoneIcon fontSize="small" color="action" />
                    <Typography variant="body2">{driver.phoneNumber || 'No phone'}</Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <CarIcon fontSize="small" color="action" />
                    <Typography variant="body2">{driver.vehicleType || 'No vehicle'}</Typography>
                  </Box>
                </Grid>
                <Grid item xs={12}>
                  <Typography variant="body2">
                    Applied: {driver.submittedAt?.toDate?.()?.toLocaleDateString() || 'Unknown'}
                  </Typography>
                </Grid>
              </Grid>

              <Box display="flex" alignItems="center" gap={2}>
                <Typography variant="body2" color="text.secondary">
                  Documents: {approvedDocsCount}/{documentsCount} approved
                </Typography>
              </Box>
            </Box>

            <Box display="flex" flexDirection="column" gap={1}>
              <Button
                startIcon={<ViewIcon />}
                onClick={() => { setSelectedDriver(driver); setDetailsOpen(true); }}
                size="small"
              >
                View Details
              </Button>
              
              {driver.status === 'pending' && (
                <>
                  <Button
                    startIcon={<ApproveIcon />}
                    color="success"
                    onClick={() => handleDriverAction(driver, 'approve')}
                    disabled={actionLoading}
                    size="small"
                  >
                    Approve
                  </Button>
                  <Button
                    startIcon={<RejectIcon />}
                    color="error"
                    onClick={() => handleDriverAction(driver, 'reject')}
                    disabled={actionLoading}
                    size="small"
                  >
                    Reject
                  </Button>
                </>
              )}
            </Box>
          </Box>
        </CardContent>
      </Card>
    );
  };

  // Helper function to get document icons
  const getDocumentIcon = (docType) => {
    switch (docType) {
      case 'driverImage': return <PersonIcon />;
      case 'licenseFront': return <AssignmentIcon />;
      case 'licenseBack': return <AssignmentIcon />;
      case 'licenseDocument': return <DescriptionIcon />;
      case 'vehicleInsurance': return <SecurityIcon />;
      case 'vehicleRegistration': return <AssignmentIcon />;
      default: return <DescriptionIcon />;
    }
  };

  const renderDocumentCard = (driver, docType, title, description = 'Document verification', required = true) => {
    const url = getDocumentUrl(driver, docType);
    const status = getDocumentStatus(driver, docType);
    const rejectionReason = driver.documentVerification?.[docType]?.rejectionReason || 
                           driver[`${docType}RejectionReason`];
    
    // Determine if driver is already approved - if so, all docs should show as approved
    const isDriverApproved = driver.status === 'approved';
    const displayStatus = isDriverApproved ? 'approved' : status;

    return (
      <Grid item xs={12} md={6} key={docType}>
        <Card 
          variant="outlined" 
          sx={{ 
            height: '100%',
            opacity: !url ? 0.7 : 1,
            border: displayStatus === 'approved' ? 2 : 1,
            borderColor: displayStatus === 'approved' ? 'success.main' : 
                        displayStatus === 'rejected' ? 'error.main' : 'divider'
          }}
        >
          <CardHeader
            avatar={
              <Avatar sx={{ 
                bgcolor: displayStatus === 'approved' ? 'success.main' : 
                        displayStatus === 'rejected' ? 'error.main' : 'grey.400' 
              }}>
                {getDocumentIcon(docType)}
              </Avatar>
            }
            title={
              <Box display="flex" alignItems="center" gap={1}>
                <Typography variant="subtitle1">{title}</Typography>
                {required && displayStatus !== 'approved' && !isDriverApproved && (
                  <Chip label="Required" size="small" color="warning" />
                )}
                {displayStatus === 'approved' && (
                  <Chip label="Verified" size="small" color="success" />
                )}
              </Box>
            }
            subheader={description}
            action={
              <Chip 
                label={displayStatus ? displayStatus.charAt(0).toUpperCase() + displayStatus.slice(1) : 'Not Submitted'} 
                color={getStatusColor(displayStatus)} 
                icon={getStatusIcon(displayStatus)}
                variant="filled"
                size="small"
              />
            }
          />
          
          {url && (
            <CardMedia
              component="img"
              height="120"
              image={url}
              alt={title}
              sx={{ 
                objectFit: 'cover',
                cursor: 'pointer',
                '&:hover': { opacity: 0.8 }
              }}
              onClick={() => viewDocument(url)}
            />
          )}
          
          <CardContent>
            {!url ? (
              <Alert severity="warning" size="small">
                Document not submitted
              </Alert>
            ) : (
              <Box>
                {displayStatus === 'approved' && isDriverApproved && (
                  <Alert severity="success" size="small" sx={{ mb: 1 }}>
                    <Typography variant="caption">
                      <strong>Document Verified:</strong> This document has been approved as part of the driver verification.
                    </Typography>
                  </Alert>
                )}
                
                {rejectionReason && displayStatus === 'rejected' && (
                  <Alert severity="error" size="small" sx={{ mb: 1 }}>
                    <Typography variant="caption">
                      <strong>Rejection Reason:</strong> {rejectionReason}
                    </Typography>
                  </Alert>
                )}
                
                <Box display="flex" justifyContent="space-between" alignItems="center" mt={1}>
                  <Button
                    size="small"
                    startIcon={<ViewIcon />}
                    onClick={() => viewDocument(url)}
                  >
                    View Full Size
                  </Button>
                </Box>
              </Box>
            )}
          </CardContent>
          
          {url && displayStatus === 'pending' && !isDriverApproved && (
            <CardActions>
              <Button 
                size="small"
                color="success"
                startIcon={<CheckIcon />}
                onClick={() => handleDocumentAction(driver, docType, 'approved')}
                disabled={actionLoading}
              >
                Approve
              </Button>
              <Button 
                size="small"
                color="error"
                startIcon={<ErrorIcon />}
                onClick={() => handleDocumentAction(driver, docType, 'reject')}
                disabled={actionLoading}
              >
                Reject
              </Button>
            </CardActions>
          )}
          
          {displayStatus === 'approved' && (
            <CardActions>
              <Box display="flex" alignItems="center" gap={1} px={1}>
                <CheckIcon color="success" fontSize="small" />
                <Typography variant="caption" color="success.main">
                  Document verified and approved
                </Typography>
              </Box>
            </CardActions>
          )}
        </Card>
      </Grid>
    );
  };

  const renderEnhancedDocumentCard = (docType, title, description, required) => {
    const url = getDocumentUrl(selectedDriver, docType);
    const status = getDocumentStatus(selectedDriver, docType);
    const rejectionReason = selectedDriver.documentVerification?.[docType]?.rejectionReason || 
                           selectedDriver[`${docType}RejectionReason`];
    
    // Determine if driver is already approved - if so, all docs should show as approved
    const isDriverApproved = selectedDriver.status === 'approved';
    const displayStatus = isDriverApproved ? 'approved' : status;

    return (
      <Grid item xs={12} md={6} key={docType}>
        <Card 
          variant="outlined" 
          sx={{ 
            height: '100%',
            opacity: !url && !required ? 0.7 : 1,
            border: displayStatus === 'approved' ? 2 : 1,
            borderColor: displayStatus === 'approved' ? 'success.main' : 
                        displayStatus === 'rejected' ? 'error.main' : 'divider'
          }}
        >
          <CardHeader
            avatar={
              <Avatar sx={{ 
                bgcolor: displayStatus === 'approved' ? 'success.main' : 
                        displayStatus === 'rejected' ? 'error.main' : 
                        !url ? 'grey.300' : 'primary.main' 
              }}>
                {getDocumentIcon(docType)}
              </Avatar>
            }
            title={
              <Box display="flex" alignItems="center" gap={1}>
                <Typography variant="subtitle1" fontWeight="medium">
                  {title}
                </Typography>
                {required && (
                  <Chip 
                    label="Required" 
                    size="small" 
                    color="warning" 
                    variant="outlined"
                  />
                )}
                {displayStatus === 'approved' && (
                  <Chip 
                    label="Verified" 
                    size="small" 
                    color="success" 
                    icon={<CheckIcon />}
                  />
                )}
              </Box>
            }
            subheader={description}
            action={
              <Chip 
                label={displayStatus ? displayStatus.charAt(0).toUpperCase() + displayStatus.slice(1) : 'Not Submitted'} 
                color={getStatusColor(displayStatus)} 
                icon={getStatusIcon(displayStatus)}
                variant="filled"
                size="small"
              />
            }
          />
          
          {url ? (
            <CardMedia
              component="img"
              height="200"
              image={url}
              alt={title}
              sx={{ 
                objectFit: 'cover',
                cursor: 'pointer',
                '&:hover': { 
                  opacity: 0.9,
                  transform: 'scale(1.02)',
                  transition: 'all 0.2s ease-in-out'
                }
              }}
              onClick={() => viewDocument(url, title)}
            />
          ) : (
            <Box 
              sx={{ 
                height: 200, 
                display: 'flex', 
                alignItems: 'center', 
                justifyContent: 'center',
                bgcolor: 'grey.50',
                color: 'text.secondary'
              }}
            >
              <Box textAlign="center">
                <ImageIcon sx={{ fontSize: 48, opacity: 0.3 }} />
                <Typography variant="body2" mt={1}>
                  No document uploaded
                </Typography>
              </Box>
            </Box>
          )}
          
          <CardContent>
            {!url && required && (
              <Alert severity="warning" size="small" sx={{ mb: 2 }}>
                <Typography variant="caption">
                  <strong>Required Document:</strong> This document must be submitted for verification.
                </Typography>
              </Alert>
            )}
            
            {!url && !required && (
              <Alert severity="info" size="small" sx={{ mb: 2 }}>
                <Typography variant="caption">
                  <strong>Optional Document:</strong> Not submitted.
                </Typography>
              </Alert>
            )}
            
            {displayStatus === 'approved' && isDriverApproved && (
              <Alert severity="success" size="small" sx={{ mb: 2 }}>
                <Typography variant="caption">
                  <strong>Document Verified:</strong> This document has been approved as part of the driver verification.
                </Typography>
              </Alert>
            )}
            
            {rejectionReason && displayStatus === 'rejected' && (
              <Alert severity="error" size="small" sx={{ mb: 2 }}>
                <Typography variant="caption">
                  <strong>Rejection Reason:</strong> {rejectionReason}
                </Typography>
              </Alert>
            )}
            
            {url && (
              <Box display="flex" justifyContent="space-between" alignItems="center">
                <Button
                  size="small"
                  startIcon={<ViewIcon />}
                  onClick={() => viewDocument(url, title)}
                  variant="outlined"
                >
                  View Full Size
                </Button>
                <Button
                  size="small"
                  startIcon={<DownloadIcon />}
                  onClick={() => window.open(url, '_blank')}
                  variant="text"
                >
                  Download
                </Button>
              </Box>
            )}
          </CardContent>
          
          {url && displayStatus === 'pending' && !isDriverApproved && (
            <CardActions sx={{ justifyContent: 'space-between', px: 2, py: 1.5 }}>
              <Button 
                size="small"
                color="success"
                startIcon={<CheckIcon />}
                onClick={() => handleDocumentAction(selectedDriver, docType, 'approved')}
                disabled={actionLoading}
                variant="contained"
                sx={{ minWidth: 100 }}
              >
                Approve
              </Button>
              <Button 
                size="small"
                color="error"
                startIcon={<ErrorIcon />}
                onClick={() => handleDocumentAction(selectedDriver, docType, 'reject')}
                disabled={actionLoading}
                variant="outlined"
                sx={{ minWidth: 100 }}
              >
                Reject
              </Button>
            </CardActions>
          )}
          
          {displayStatus === 'approved' && (
            <CardActions sx={{ px: 2, py: 1.5 }}>
              <Box display="flex" alignItems="center" gap={1} width="100%">
                <CheckIcon color="success" fontSize="small" />
                <Typography variant="caption" color="success.main" fontWeight="medium">
                  Document verified and approved
                </Typography>
              </Box>
            </CardActions>
          )}
          
          {displayStatus === 'rejected' && (
            <CardActions sx={{ px: 2, py: 1.5 }}>
              <Box display="flex" alignItems="center" gap={1} width="100%">
                <ErrorIcon color="error" fontSize="small" />
                <Typography variant="caption" color="error.main" fontWeight="medium">
                  Document rejected - needs resubmission
                </Typography>
              </Box>
            </CardActions>
          )}
        </Card>
      </Grid>
    );
  };

  const renderDriverDetails = () => {
    if (!selectedDriver) return null;

    return (
      <Dialog open={detailsOpen} onClose={() => setDetailsOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          <Box display="flex" alignItems="center" gap={2}>
            <PersonIcon />
            <Box>
              <Typography variant="h6">{selectedDriver.fullName}</Typography>
              <Chip 
                label={selectedDriver.status || 'pending'} 
                color={getStatusColor(selectedDriver.status)} 
                size="small"
              />
            </Box>
          </Box>
        </DialogTitle>
        
        <DialogContent>
          <Tabs value={tabValue} onChange={(e, v) => setTabValue(v)}>
            <Tab label="Driver Info" />
            <Tab label="Documents" />
            <Tab label="Vehicle Info" />
          </Tabs>

          {tabValue === 0 && (
            <Box sx={{ mt: 2 }}>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="Full Name"
                    value={selectedDriver.fullName || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="Date of Birth"
                    value={selectedDriver.dateOfBirth || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="Email"
                    value={selectedDriver.email || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="Phone"
                    value={selectedDriver.phoneNumber || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    label="Address"
                    value={selectedDriver.address || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="License Number"
                    value={selectedDriver.licenseNumber || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="ID Number"
                    value={selectedDriver.idNumber || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
              </Grid>
            </Box>
          )}

          {tabValue === 1 && (
            <Box>
              <Alert severity="info" sx={{ mb: 3 }}>
                <Typography variant="subtitle2" gutterBottom>
                  Document Verification Requirements
                </Typography>
                <Typography variant="body2">
                  All documents must be clear, readable, and match the driver information provided. 
                  Click on any document to view it in full screen.
                </Typography>
              </Alert>
              
              <Grid container spacing={2}>
                {renderEnhancedDocumentCard('profileImage', 'Driver Photo', 'Professional driver identification photo', true)}
                {renderEnhancedDocumentCard('driverImage', 'Driver ID Photo', 'Driver identification image', false)}
                {renderEnhancedDocumentCard('licenseImage', 'Driver License', 'Driver license document', true)}
                {renderEnhancedDocumentCard('licenseFront', 'License (Front)', 'Front side of driving license', false)}
                {renderEnhancedDocumentCard('licenseBack', 'License (Back)', 'Back side of driving license', false)}
                {renderEnhancedDocumentCard('idImage', 'National ID', 'National identification document', true)}
                {renderEnhancedDocumentCard('vehicleRegistration', 'Vehicle Registration', 'Official vehicle registration document', true)}
                {renderEnhancedDocumentCard('vehicleInsurance', 'Vehicle Insurance', 'Valid vehicle insurance certificate', false)}
              </Grid>
            </Box>
          )}

          {tabValue === 2 && (
            <Box sx={{ mt: 2 }}>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="Vehicle Type"
                    value={selectedDriver.vehicleType || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="Vehicle Make"
                    value={selectedDriver.vehicleMake || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="Vehicle Model"
                    value={selectedDriver.vehicleModel || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="Vehicle Year"
                    value={selectedDriver.vehicleYear || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="License Plate"
                    value={selectedDriver.licensePlate || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="Vehicle Color"
                    value={selectedDriver.vehicleColor || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
              </Grid>
            </Box>
          )}
        </DialogContent>

        <DialogActions>
          <Button onClick={() => setDetailsOpen(false)}>Close</Button>
          {selectedDriver.status === 'pending' && (
            <>
              <Button 
                color="error"
                onClick={() => handleDriverAction(selectedDriver, 'reject')}
                disabled={actionLoading}
              >
                Reject Driver
              </Button>
              <Button 
                color="success" 
                variant="contained"
                onClick={() => handleDriverAction(selectedDriver, 'approve')}
                disabled={actionLoading}
              >
                Approve Driver
              </Button>
            </>
          )}
        </DialogActions>
      </Dialog>
    );
  };

  if (loading) {
    return (
      <Container maxWidth="lg" sx={{ mt: 4 }}>
        <Box display="flex" justifyContent="center" alignItems="center" minHeight="200px">
          <CircularProgress />
        </Box>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      <Typography variant="h4" gutterBottom>
        Driver Verification
      </Typography>
      
      <Typography variant="subtitle1" color="text.secondary" gutterBottom>
        Manage driver verifications for {adminData?.country || 'all countries'}
      </Typography>

      <Box display="flex" gap={2} mb={3}>
        <FormControl size="small" sx={{ minWidth: 120 }}>
          <InputLabel>Status Filter</InputLabel>
          <Select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            label="Status Filter"
          >
            <MenuItem value="all">All Status</MenuItem>
            <MenuItem value="pending">Pending</MenuItem>
            <MenuItem value="approved">Approved</MenuItem>
            <MenuItem value="rejected">Rejected</MenuItem>
          </Select>
        </FormControl>
        
        <Button variant="outlined" onClick={loadDrivers}>
          Refresh
        </Button>
      </Box>

      {drivers.length === 0 ? (
        <Alert severity="info">
          No driver verifications found for the selected filters.
        </Alert>
      ) : (
        drivers.map(renderDriverCard)
      )}

      {renderDriverDetails()}

      {/* Rejection Dialog */}
      <Dialog open={rejectionDialog.open} onClose={() => setRejectionDialog({ open: false, target: null, type: '' })}>
        <DialogTitle>
          Reject {rejectionDialog.type === 'document' ? 'Document' : 'Driver'}
        </DialogTitle>
        <DialogContent>
          <Typography variant="body2" sx={{ mb: 2 }}>
            Please provide a reason for rejection:
          </Typography>
          <TextField
            fullWidth
            multiline
            rows={3}
            value={rejectionReason}
            onChange={(e) => setRejectionReason(e.target.value)}
            placeholder="Enter rejection reason..."
            variant="outlined"
          />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setRejectionDialog({ open: false, target: null, type: '' })}>
            Cancel
          </Button>
          <Button 
            color="error" 
            variant="contained"
            onClick={handleRejection}
            disabled={actionLoading || !rejectionReason.trim()}
          >
            Confirm Rejection
          </Button>
        </DialogActions>
      </Dialog>

      {/* Fullscreen Image Dialog */}
      <Dialog 
        open={fullscreenImage.open} 
        onClose={() => setFullscreenImage({ open: false, url: '', title: '' })}
        maxWidth="md"
        fullWidth
      >
        <DialogTitle>
          <Box display="flex" justifyContent="space-between" alignItems="center">
            <Typography variant="h6">{fullscreenImage.title}</Typography>
            <IconButton 
              onClick={() => setFullscreenImage({ open: false, url: '', title: '' })}
              size="large"
            >
              <CloseIcon />
            </IconButton>
          </Box>
        </DialogTitle>
        <DialogContent sx={{ p: 0 }}>
          <Box sx={{ textAlign: 'center' }}>
            <img 
              src={fullscreenImage.url} 
              alt={fullscreenImage.title}
              style={{ 
                width: '100%', 
                height: 'auto', 
                maxHeight: '70vh',
                objectFit: 'contain'
              }}
            />
          </Box>
        </DialogContent>
        <DialogActions>
          <Button 
            startIcon={<DownloadIcon />}
            onClick={() => window.open(fullscreenImage.url, '_blank')}
          >
            Download
          </Button>
          <Button 
            onClick={() => setFullscreenImage({ open: false, url: '', title: '' })}
          >
            Close
          </Button>
        </DialogActions>
      </Dialog>
    </Container>
  );
};

export default DriverVerificationEnhanced;
