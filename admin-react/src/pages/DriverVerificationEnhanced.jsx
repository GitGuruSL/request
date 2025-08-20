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
  CardActions,
  LinearProgress,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Paper
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
  Info as InfoIcon,
  Visibility as VisibilityIcon,
  AccessTime as AccessTimeIcon
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import api from '../services/apiClient';

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
  
  // City and Vehicle Type mapping
  const [cityNames, setCityNames] = useState({});
  const [vehicleTypeNames, setVehicleTypeNames] = useState({});

  useEffect(() => {
    loadDrivers();
    loadCityNames();
    loadVehicleTypeNames();
  }, [filterStatus]);

  const loadDrivers = async () => {
    try {
      setLoading(true);
      const params = {};
      if (isCountryAdmin && adminData?.country) params.country = adminData.country;
      if (filterStatus !== 'all') params.status = filterStatus;
      
      console.log('🔍 Loading drivers with params:', params);
      const res = await api.get('/driver-verifications', { params });
      console.log('📥 Driver API response:', res.data);
      
      const list = Array.isArray(res.data) ? res.data : res.data?.data || [];
      console.log('📋 Processed driver list:', list);
      console.log('🔍 First driver object keys:', list[0] ? Object.keys(list[0]) : 'No drivers');
      console.log('🔍 First driver object:', list[0]);
      
      const sorted = [...list].sort((a,b)=> new Date(b.submittedAt || b.createdAt || 0) - new Date(a.submittedAt || a.createdAt || 0));
      setDrivers(sorted);
    } catch (e) {
      console.error('❌ Error loading drivers:', e);
      console.error('Full error details:', e.response?.data || e.message);
    } finally { 
      setLoading(false);
    } 
  };

  const loadCityNames = async () => {
    try { 
      const res = await api.get('/cities'); 
      const map = {}; 
      // Handle nested data structure: res.data.data or res.data
      const cities = res.data?.data || res.data || [];
      cities.forEach(c => { 
        map[c.id] = c.name || c.cityName || c.displayName || c.id; 
      }); 
      setCityNames(map);
    } catch(e) { 
      console.error('Error loading city names', e);
    } 
  };

  const loadVehicleTypeNames = async () => { 
    try { 
      const res = await api.get('/vehicle-types'); 
      const map = {}; 
      // Handle nested data structure: res.data.data or res.data
      const vehicleTypes = res.data?.data || res.data || [];
      vehicleTypes.forEach(v => { 
        map[v.id] = v.name || v.typeName || v.displayName || v.id; 
      }); 
      setVehicleTypeNames(map);
    } catch(e) { 
      console.error('Error loading vehicle types', e);
    } 
  };

  // Phone verification helper function
  const getPhoneVerificationStatus = (driverData) => {
    // If phoneVerified is explicitly set, use that
    if (typeof driverData.phoneVerified === 'boolean') {
      return {
        isVerified: driverData.phoneVerified,
        source: driverData.phoneVerified ? 'firebase_auth' : 'pending_verification',
        needsManualVerification: !driverData.phoneVerified
      };
    }

    // Auto-verify if phone matches user's auth phone (assuming they registered with this number)
    // This logic assumes if they have a userId, their phone was verified during registration
    if (driverData.userId && driverData.phoneNumber) {
      return {
        isVerified: true,
        source: 'firebase_auth_registration',
        needsManualVerification: false
      };
    }

    // Default to not verified, needs manual verification
    return {
      isVerified: false,
      source: 'not_verified',
      needsManualVerification: true
    };
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
      // Support for new document types from mobile app
      case 'driverImage': return driver.driverImageStatus || 'pending';
      case 'licenseFront': return driver.licenseFrontStatus || 'pending';
      case 'licenseBack': return driver.licenseBackStatus || 'pending';
      case 'licenseDocument': return driver.licenseDocumentStatus || 'pending';
      case 'nicFront': return driver.nicFrontStatus || 'pending';
      case 'nicBack': return driver.nicBackStatus || 'pending';
      case 'billingProof': return driver.billingProofStatus || 'pending';
      case 'vehicleInsurance': return driver.vehicleInsuranceStatus || 'pending';
      default: return 'pending';
    }
  };

  const getVehicleImageStatus = (driver, imageIndex) => {
    const vehicleImageVerification = driver.vehicleImageVerification?.[imageIndex];
    if (vehicleImageVerification?.status) {
      return vehicleImageVerification.status;
    }
    return 'pending';
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
      // Support for new document types from mobile app
      case 'driverImage': return driver.driverImageUrl;
      case 'licenseFront': return driver.licenseFrontUrl;
      case 'licenseBack': return driver.licenseBackUrl;
      case 'licenseDocument': return driver.licenseDocumentUrl;
      case 'nicFront': return driver.nicFrontUrl;
      case 'nicBack': return driver.nicBackUrl;
      case 'billingProof': return driver.billingProofUrl;
      case 'vehicleInsurance': return driver.vehicleInsuranceUrl || driver.insuranceDocumentUrl;
      default: return null;
    }
  };

  const getCityName = (cityId) => {
    return cityNames[cityId] || cityId || 'Unknown City';
  };

  const getVehicleTypeName = (vehicleTypeId) => {
    return vehicleTypeNames[vehicleTypeId] || vehicleTypeId || 'Unknown Vehicle Type';
  };

  const handleDocumentApprovalWithClose = async (driver, docType, action) => {
    setActionLoading(true);
    try {
      await api.put(`/driver-verifications/${driver.id}/document-status`, { 
        documentType: docType, 
        status: action 
      });
      await loadDrivers();
      // Refresh selected driver
      const res = await api.get(`/driver-verifications/${driver.id}`);
      if (res.data) setSelectedDriver(res.data);
      console.log(`✅ Document ${docType} ${action} for ${driver.fullName}`);
    } catch (error) {
      console.error(`Error updating document status:`, error);
    } finally {
      setActionLoading(false);
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
    await api.put(`/driver-verifications/${driver.id}/document-status`, { 
      documentType: docType, 
      status: action 
    }); 
    await loadDrivers(); 
    console.log(`✅ Document ${docType} ${action} for ${driver.fullName}`);
  } catch (error){ 
    console.error('Error updating document status', error);
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
      // Define all possible document types (both new and legacy)
      const allDocTypes = [
        // New mobile app documents (mandatory)
        'driverImage', 'licenseFront', 'licenseBack', 'vehicleInsurance', 'vehicleRegistration',
        // Legacy documents (for backward compatibility)  
        'profileImage', 'licenseImage', 'idImage'
      ];
      
      // Find which documents this driver actually has
      const availableDocuments = allDocTypes.filter(docType => getDocumentUrl(driver, docType));
      
      // Check if all available documents are approved
      const allDocsApproved = availableDocuments.every(docType => {
        const status = getDocumentStatus(driver, docType);
        return status === 'approved';
      });

      if (!allDocsApproved) {
        alert('All submitted documents must be approved before approving the driver.');
        return;
      }

      // Check contact verification (similar to business verification)
  try { if (driver.userId){ const res = await api.get(`/users/${driver.userId}`); const u=res.data||{}; const creds=u.linkedCredentials||{}; const phoneVerified=creds.linkedPhoneVerified||u.phoneVerified; const emailVerified=creds.linkedEmailVerified||u.emailVerified; if (!phoneVerified || !emailVerified){ const missing=[]; if(!phoneVerified) missing.push('phone'); if(!emailVerified) missing.push('email'); alert(`Cannot approve driver. User must verify: ${missing.join(', ')}`); return; } } } catch(err){ console.warn('Proceeding without strict contact check', err);} 
    }

  setActionLoading(true);
  try { await api.put(`/driver-verifications/${driver.id}/status`, { status: action === 'approve' ? 'approved' : action }); await loadDrivers(); console.log(`✅ Driver ${action}: ${driver.fullName}`);} catch (error){ console.error(`Error ${action} driver`, error);} finally { setActionLoading(false);} 
  };

  const handleVehicleImageAction = async (driver, imageIndex, action) => {
    if (action === 'reject') {
      setRejectionDialog({ 
        open: true, 
        target: driver,
        type: 'vehicleImage',
        imageIndex: imageIndex
      });
      return;
    }

  setActionLoading(true);
  try { await api.put(`/driver-verifications/${driver.id}/vehicle-images/${imageIndex}`, { status: action }); await loadDrivers(); console.log(`✅ Vehicle image ${imageIndex} ${action}: ${driver.fullName}`);} catch (error){ console.error(`Error ${action} vehicle image`, error);} finally { setActionLoading(false);} 
  };

  const handleRejection = async () => {
    if (!rejectionReason.trim()) {
      alert('Please provide a reason for rejection');
      return;
    }

    const { target, type, docType } = rejectionDialog;
    setActionLoading(true);

    try {
      if (type === 'document') {
        await api.put(`/driver-verifications/${target.id}/document-status`, { 
          documentType: docType, 
          status: 'rejected', 
          rejectionReason 
        });
      } else if (type === 'vehicleImage') {
        const { imageIndex } = rejectionDialog;
        await api.put(`/driver-verifications/${target.id}/vehicle-images/${imageIndex}`, { status: 'rejected', rejectionReason });
      } else {
        await api.put(`/driver-verifications/${target.id}/status`, { status: 'rejected', rejectionReason });
      }
      await loadDrivers();
      
      // Update selected driver data to show new status immediately
      if (selectedDriver && selectedDriver.id === target.id) {
        if (type === 'document') {
          const updatedDriver = { ...selectedDriver, documentVerification: { ...selectedDriver.documentVerification, [docType]: { ...selectedDriver.documentVerification?.[docType], status: 'rejected', rejectionReason } } };
          setSelectedDriver(updatedDriver);
        }
      }
      
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
                    <Typography variant="body2">{getCityName(driver.cityId) || driver.cityName} • {driver.address || driver.fullAddress || 'No address'}</Typography>
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
                    <Typography variant="body2">{driver.vehicleTypeName || 'Unknown Vehicle Type'}</Typography>
                  </Box>
                </Grid>
                <Grid item xs={12}>
                  <Typography variant="body2">
                    Applied: {
                      (driver.submissionDate && new Date(driver.submissionDate).toLocaleDateString()) ||
                      (driver.createdAt && new Date(driver.createdAt).toLocaleDateString()) ||
                      (driver.submittedAt && new Date(driver.submittedAt).toLocaleDateString()) ||
                      'Unknown'
                    }
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
              height="140"
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
                height: 140, 
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

  const renderDocumentListItem = (docType, title, description, required) => {
    const url = getDocumentUrl(selectedDriver, docType);
    const status = getDocumentStatus(selectedDriver, docType);
    const rejectionReason = selectedDriver.documentVerification?.[docType]?.rejectionReason || 
                           selectedDriver[`${docType}RejectionReason`];
    
    // Determine if driver is already approved - if so, all docs should show as approved
    const isDriverApproved = selectedDriver.status === 'approved';
    const displayStatus = isDriverApproved ? 'approved' : status;
    
    const isApproved = displayStatus === 'approved';
    const isPending = displayStatus === 'pending' || !displayStatus;
    const isRejected = displayStatus === 'rejected';

    return (
      <TableRow 
        key={docType}
        sx={{ 
          backgroundColor: isApproved ? 'success.50' : isPending ? 'warning.50' : 'error.50',
          '&:hover': { 
            backgroundColor: isApproved ? 'success.100' : isPending ? 'warning.100' : 'error.100' 
          }
        }}
      >
        <TableCell>
          <Box display="flex" alignItems="center" gap={2}>
            <Avatar sx={{ 
              bgcolor: isApproved ? 'success.main' : isPending ? 'warning.main' : 'error.main',
              width: 32, 
              height: 32
            }}>
              {getDocumentIcon(docType)}
            </Avatar>
            <Box>
              <Typography variant="body2" fontWeight="bold">
                {title}
              </Typography>
              <Typography variant="caption" color="text.secondary">
                {description}
              </Typography>
              {rejectionReason && isRejected && (
                <Typography variant="caption" color="error.main" display="block" sx={{ mt: 0.5 }}>
                  <strong>Reason:</strong> {rejectionReason}
                </Typography>
              )}
            </Box>
          </Box>
        </TableCell>
        <TableCell>
          <Chip 
            label={isApproved ? 'Approved' : isPending ? 'Pending' : 'Rejected'} 
            color={isApproved ? 'success' : isPending ? 'warning' : 'error'}
            size="small"
            icon={isApproved ? <CheckIcon /> : isPending ? <AccessTimeIcon /> : <ErrorIcon />}
          />
        </TableCell>
        <TableCell>
          <Chip 
            label={required ? 'Required' : 'Optional'} 
            variant="outlined"
            size="small" 
            color={required ? (isApproved ? 'success' : 'error') : 'default'}
          />
        </TableCell>
        <TableCell align="center">
          <Box display="flex" gap={1} justifyContent="center" alignItems="center">
            <Button
              variant="outlined"
              size="small"
              startIcon={<VisibilityIcon />}
              onClick={() => viewDocument(url, title)}
            >
              View Document
            </Button>
            <Button
              variant="text"
              size="small"
              startIcon={<DownloadIcon />}
              onClick={() => window.open(url, '_blank')}
            >
              Download
            </Button>
            {isPending && !isDriverApproved && (
              <>
                <Button
                  variant="contained"
                  color="success"
                  size="small"
                  startIcon={<CheckIcon />}
                  onClick={() => handleDocumentApprovalWithClose(selectedDriver, docType, 'approved')}
                  disabled={actionLoading}
                >
                  Approve
                </Button>
                <Button
                  variant="outlined"
                  color="error"
                  size="small"
                  startIcon={<ErrorIcon />}
                  onClick={() => handleDocumentAction(selectedDriver, docType, 'reject')}
                  disabled={actionLoading}
                >
                  Reject
                </Button>
              </>
            )}
          </Box>
        </TableCell>
      </TableRow>
    );
  };

  const calculateVerificationCompletion = (driver) => {
    // Define all possible document types (both new and legacy)
    const allDocTypes = [
      // New mobile app documents (mandatory)
      'driverImage', 'licenseFront', 'licenseBack', 'vehicleInsurance', 'vehicleRegistration',
      // Legacy documents (for backward compatibility)  
      'profileImage', 'licenseImage', 'idImage'
    ];
    
    // Find which documents this driver actually has
    const availableDocuments = allDocTypes.filter(docType => getDocumentUrl(driver, docType));
    
    // If no documents found, return 0
    if (availableDocuments.length === 0) return 0;
    
    // Calculate how many of the available documents are approved
    const approvedDocuments = availableDocuments.filter(docType => {
      const status = getDocumentStatus(driver, docType);
      return status === 'approved';
    });
    
    // Calculate percentage based on approved vs available documents
    const completionPercentage = (approvedDocuments.length / availableDocuments.length) * 100;
    
    return Math.round(completionPercentage);
  };

  const renderDriverDetails = () => {
    if (!selectedDriver) return null;

    const completionPercentage = calculateVerificationCompletion(selectedDriver);
    const isApproved = selectedDriver.status === 'approved';

    return (
      <Dialog open={detailsOpen} onClose={() => setDetailsOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle sx={{ pb: 0 }}>
          <Box display="flex" alignItems="center" gap={2} mb={2}>
            <Avatar sx={{ 
              bgcolor: isApproved ? 'success.main' : 
                      selectedDriver.status === 'rejected' ? 'error.main' : 'primary.main',
              width: 48, 
              height: 48 
            }}>
              <PersonIcon />
            </Avatar>
            <Box flex={1}>
              <Typography variant="h5" fontWeight="bold">
                {selectedDriver.fullName || selectedDriver.name || 'Unknown Driver'}
              </Typography>
              <Box display="flex" alignItems="center" gap={2} mt={1}>
                <Chip 
                  label={isApproved ? 'approved' : selectedDriver.status || 'pending'} 
                  color={getStatusColor(selectedDriver.status)} 
                  icon={getStatusIcon(selectedDriver.status)}
                  size="medium"
                />
                <Chip 
                  label={`${completionPercentage}% Complete`}
                  variant="outlined"
                  size="small"
                />
                <Typography variant="body2" color="text.secondary">
                  Submitted: {selectedDriver.createdAt ? 
                    new Date(selectedDriver.createdAt).toLocaleDateString() : 
                    selectedDriver.submissionDate ? 
                    new Date(selectedDriver.submissionDate).toLocaleDateString() :
                    'Unknown'
                  }
                </Typography>
              </Box>
            </Box>
            <IconButton onClick={() => setDetailsOpen(false)} size="large">
              <CloseIcon />
            </IconButton>
          </Box>
          
          {/* Progress Bar */}
          <Box sx={{ width: '100%', mb: 2 }}>
            <Box display="flex" alignItems="center" gap={1} mb={1}>
              <Typography variant="body2" color="text.secondary">
                Verification Progress
              </Typography>
              <Typography variant="body2" color="primary" fontWeight="medium">
                {completionPercentage}%
              </Typography>
            </Box>
            <Box sx={{ 
              height: 6, 
              bgcolor: 'grey.200', 
              borderRadius: 3,
              overflow: 'hidden'
            }}>
              <Box sx={{ 
                height: '100%',
                width: `${completionPercentage}%`,
                bgcolor: isApproved ? 'success.main' : 
                        selectedDriver.status === 'rejected' ? 'error.main' : 'primary.main',
                transition: 'width 0.3s ease',
                borderRadius: 3
              }} />
            </Box>
          </Box>
        </DialogTitle>
        
        <DialogContent>
          <Tabs value={tabValue} onChange={(e, v) => setTabValue(v)}>
            <Tab label="Driver Info" />
            <Tab label="Documents" />
            <Tab label="Contact Info" />
            <Tab label="Vehicle Info" />
            <Tab label="Verification History" />
          </Tabs>

          {tabValue === 0 && (
            <Box sx={{ mt: 2 }}>
              <Grid container spacing={3}>
                {/* Personal Information Card */}
                <Grid item xs={12} md={6}>
                  <Card variant="outlined" sx={{ height: 'fit-content' }}>
                    <CardHeader 
                      avatar={<PersonIcon color="primary" />}
                      title="Personal Information"
                      subheader="Basic personal details"
                    />
                    <CardContent>
                      <Grid container spacing={2}>
                        <Grid item xs={12}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              Full Name
                            </Typography>
                            <Typography variant="body1" fontWeight="medium">
                              {selectedDriver.fullName || selectedDriver.name || 
                               (selectedDriver.firstName && selectedDriver.lastName ? 
                                `${selectedDriver.firstName} ${selectedDriver.lastName}` : 'Not provided')}
                            </Typography>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={6}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              Gender
                            </Typography>
                            <Typography variant="body1">
                              {selectedDriver.gender || 'Not provided'}
                            </Typography>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={6}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              Date of Birth
                            </Typography>
                            <Typography variant="body1">
                              {selectedDriver.dateOfBirth ? 
                                new Date(selectedDriver.dateOfBirth).toLocaleDateString() : 
                                'Not provided'}
                            </Typography>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={12}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              NIC Number
                            </Typography>
                            <Typography variant="body1" fontFamily="monospace">
                              {selectedDriver.nicNumber || 'Not provided'}
                            </Typography>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={12}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              City
                            </Typography>
                            <Typography variant="body1">
                              {getCityName(selectedDriver.cityId) || selectedDriver.cityName || 'Not provided'}
                            </Typography>
                          </Box>
                        </Grid>
                      </Grid>
                    </CardContent>
                  </Card>
                </Grid>

                {/* Contact Information Card */}
                <Grid item xs={12} md={6}>
                  <Card variant="outlined" sx={{ height: 'fit-content' }}>
                    <CardHeader 
                      avatar={<PhoneIcon color="primary" />}
                      title="Contact Information"
                      subheader="Phone and email details"
                    />
                    <CardContent>
                      <Grid container spacing={2}>
                        <Grid item xs={12}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              Email Address
                            </Typography>
                            <Typography variant="body1">
                              {selectedDriver.email || 'Not provided'}
                            </Typography>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={12}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              Primary Phone
                            </Typography>
                            <Typography variant="body1" fontFamily="monospace">
                              {selectedDriver.phoneNumber || 'Not provided'}
                            </Typography>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={12}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              Secondary Mobile
                            </Typography>
                            <Typography variant="body1" fontFamily="monospace">
                              {selectedDriver.secondaryMobile || 'Not provided'}
                            </Typography>
                          </Box>
                        </Grid>
                      </Grid>
                    </CardContent>
                  </Card>
                </Grid>

                {/* License Information Card */}
                <Grid item xs={12} md={6}>
                  <Card variant="outlined" sx={{ height: 'fit-content' }}>
                    <CardHeader 
                      avatar={<AssignmentIcon color="primary" />}
                      title="License Information"
                      subheader="Driving license details"
                    />
                    <CardContent>
                      <Grid container spacing={2}>
                        <Grid item xs={12}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              License Number
                            </Typography>
                            <Typography variant="body1" fontFamily="monospace">
                              {selectedDriver.licenseNumber || 'Not provided'}
                            </Typography>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={12}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              License Expiry Date
                            </Typography>
                            <Typography variant="body1">
                              {selectedDriver.licenseHasNoExpiry ? (
                                <Chip label="No Expiry Date" color="success" size="small" />
                              ) : selectedDriver.licenseExpiry ? 
                                new Date(selectedDriver.licenseExpiry).toLocaleDateString() : 
                                'Not provided'}
                            </Typography>
                          </Box>
                        </Grid>
                      </Grid>
                    </CardContent>
                  </Card>
                </Grid>

                {/* Vehicle Ownership & Registration Card */}
                <Grid item xs={12} md={6}>
                  <Card variant="outlined" sx={{ height: 'fit-content' }}>
                    <CardHeader 
                      avatar={<CarIcon color="primary" />}
                      title="Vehicle Ownership & Registration"
                      subheader="Vehicle ownership status and registration date"
                    />
                    <CardContent>
                      <Grid container spacing={2}>
                        <Grid item xs={12}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              Ownership Status
                            </Typography>
                            <Typography variant="body1">
                              {selectedDriver.isVehicleOwner !== undefined ? (
                                <Chip 
                                  label={selectedDriver.isVehicleOwner ? 'Vehicle Owner' : 'Not Vehicle Owner'} 
                                  color={selectedDriver.isVehicleOwner ? 'success' : 'default'} 
                                  size="small" 
                                />
                              ) : 'Not specified'}
                            </Typography>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={12}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              Country
                            </Typography>
                            <Typography variant="body1">
                              {selectedDriver.country || 'Not provided'}
                            </Typography>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={12}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              Registration Date
                            </Typography>
                            <Typography variant="body1">
                              {selectedDriver.createdAt ? 
                                new Date(selectedDriver.createdAt).toLocaleString() : 
                                selectedDriver.submissionDate ? 
                                new Date(selectedDriver.submissionDate).toLocaleString() :
                                'Not available'}
                            </Typography>
                          </Box>
                        </Grid>
                      </Grid>
                    </CardContent>
                  </Card>
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
                  Click "View Document" to review each submitted document.
                </Typography>
              </Alert>
              
              <TableContainer component={Paper}>
                <Table>
                  <TableHead>
                    <TableRow>
                      <TableCell><strong>Document Type</strong></TableCell>
                      <TableCell><strong>Status</strong></TableCell>
                      <TableCell><strong>Required</strong></TableCell>
                      <TableCell align="center"><strong>Actions</strong></TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    {/* Mandatory Documents */}
                    {getDocumentUrl(selectedDriver, 'driverImage') && renderDocumentListItem('driverImage', 'Driver Photo', 'Driver identification photo (Profile Photo)', true)}
                    {getDocumentUrl(selectedDriver, 'licenseFront') && renderDocumentListItem('licenseFront', 'License (Front)', 'Front side of driving license', true)}
                    {getDocumentUrl(selectedDriver, 'licenseBack') && renderDocumentListItem('licenseBack', 'License (Back)', 'Back side of driving license', true)}
                    {getDocumentUrl(selectedDriver, 'vehicleInsurance') && renderDocumentListItem('vehicleInsurance', 'Vehicle Insurance', 'Vehicle insurance certificate', true)}
                    {getDocumentUrl(selectedDriver, 'vehicleRegistration') && renderDocumentListItem('vehicleRegistration', 'Vehicle Registration', 'Official vehicle registration document', true)}
                    
                    {/* Optional Documents */}
                    {getDocumentUrl(selectedDriver, 'nicFront') && renderDocumentListItem('nicFront', 'NIC (Front)', 'Front side of National Identity Card', false)}
                    {getDocumentUrl(selectedDriver, 'nicBack') && renderDocumentListItem('nicBack', 'NIC (Back)', 'Back side of National Identity Card', false)}
                    {getDocumentUrl(selectedDriver, 'billingProof') && renderDocumentListItem('billingProof', 'Billing Proof', 'Utility bill or bank statement for address verification', false)}
                    {getDocumentUrl(selectedDriver, 'licenseDocument') && renderDocumentListItem('licenseDocument', 'License Document', 'Additional license document if available', false)}
                    
                    {/* Legacy Documents */}
                    {getDocumentUrl(selectedDriver, 'profileImage') && renderDocumentListItem('profileImage', 'Profile Photo (Legacy)', 'Driver profile image', true)}
                    {getDocumentUrl(selectedDriver, 'licenseImage') && renderDocumentListItem('licenseImage', 'Driver License (Legacy)', 'Driver license document', true)}
                    {getDocumentUrl(selectedDriver, 'idImage') && renderDocumentListItem('idImage', 'National ID (Legacy)', 'National identification document', true)}
                  </TableBody>
                </Table>
              </TableContainer>

              {/* Vehicle Photos Section - show if they exist or if there are vehicle image verifications */}
              {(() => {
                const hasVehicleImageUrls = Array.isArray(selectedDriver.vehicleImageUrls) && selectedDriver.vehicleImageUrls.length > 0;
                const hasVehicleImageUrlsObject = selectedDriver.vehicleImageUrls && 
                  typeof selectedDriver.vehicleImageUrls === 'object' && 
                  Object.values(selectedDriver.vehicleImageUrls).some(url => url);
                const hasVehicleImages = Array.isArray(selectedDriver.vehicleImages) && selectedDriver.vehicleImages.length > 0;
                const hasVehicleImageVerification = selectedDriver.vehicleImageVerification && 
                  Object.keys(selectedDriver.vehicleImageVerification).length > 0;
                
                return (hasVehicleImageUrls || hasVehicleImageUrlsObject || hasVehicleImages || hasVehicleImageVerification);
              })() && (
                <Box sx={{ mt: 4 }}>
                  <Typography variant="h6" gutterBottom sx={{ mb: 3, fontWeight: 'bold', color: 'primary.main' }}>
                    Vehicle Photos
                  </Typography>
                  <Alert severity="info" sx={{ mb: 3 }}>
                    <Typography variant="body2">
                      {(() => {
                        let vehicleImageUrlsCount = 0;
                        
                        if (Array.isArray(selectedDriver.vehicleImageUrls)) {
                          vehicleImageUrlsCount = selectedDriver.vehicleImageUrls.length;
                        } else if (selectedDriver.vehicleImageUrls && typeof selectedDriver.vehicleImageUrls === 'object') {
                          // Count non-null values in the object
                          vehicleImageUrlsCount = Object.values(selectedDriver.vehicleImageUrls).filter(url => url).length;
                        }
                        
                        const vehicleImagesCount = Array.isArray(selectedDriver.vehicleImages) ? selectedDriver.vehicleImages.length : 0;
                        const totalCount = Math.max(vehicleImageUrlsCount, vehicleImagesCount);
                        return `${totalCount} of 6 photos uploaded. Minimum 4 required for approval.`;
                      })()}
                    </Typography>
                  </Alert>
                  
                  <TableContainer component={Paper} variant="outlined">
                    <Table size="medium">
                      <TableHead>
                        <TableRow>
                          <TableCell><strong>Vehicle Photo Type</strong></TableCell>
                          <TableCell><strong>Status</strong></TableCell>
                          <TableCell><strong>Required</strong></TableCell>
                          <TableCell align="center"><strong>Actions</strong></TableCell>
                        </TableRow>
                      </TableHead>
                      <TableBody>
                        {(() => {
                          // Debug: Log the available vehicle fields
                          console.log('Vehicle Photo Debug:', {
                            hasVehicleImageUrls: Array.isArray(selectedDriver.vehicleImageUrls),
                            vehicleImageUrlsCount: selectedDriver.vehicleImageUrls?.length,
                            hasVehicleImages: Array.isArray(selectedDriver.vehicleImages),
                            vehicleImagesCount: selectedDriver.vehicleImages?.length,
                            vehicleImageVerification: selectedDriver.vehicleImageVerification,
                            allKeys: Object.keys(selectedDriver)
                          });
                          
                          // Handle vehicleImageUrls which can be either array or object
                          let vehiclePhotos = [];
                          
                          if (Array.isArray(selectedDriver.vehicleImageUrls)) {
                            vehiclePhotos = selectedDriver.vehicleImageUrls;
                          } else if (selectedDriver.vehicleImageUrls && typeof selectedDriver.vehicleImageUrls === 'object') {
                            // Convert object with numeric keys to array
                            const urlsObj = selectedDriver.vehicleImageUrls;
                            const maxIndex = Math.max(...Object.keys(urlsObj).map(Number).filter(n => !isNaN(n)));
                            vehiclePhotos = [];
                            for (let i = 0; i <= maxIndex; i++) {
                              if (urlsObj[i]) {
                                vehiclePhotos[i] = urlsObj[i];
                              }
                            }
                          } else if (Array.isArray(selectedDriver.vehicleImages)) {
                            vehiclePhotos = selectedDriver.vehicleImages;
                          }
                          
                          if (vehiclePhotos.length === 0) {
                            return (
                              <TableRow>
                                <TableCell colSpan={4} align="center" sx={{ py: 4 }}>
                                  <Typography variant="body2" color="text.secondary">
                                    No vehicle photos uploaded yet
                                  </Typography>
                                </TableCell>
                              </TableRow>
                            );
                          }
                          
                          return vehiclePhotos.map((imageUrl, index) => {
                          const vehicleStatus = selectedDriver.vehicleImageVerification?.[index]?.status || 'pending';
                          const isDriverApproved = selectedDriver.status === 'approved';
                          const displayStatus = isDriverApproved ? 'approved' : vehicleStatus;
                          
                          const getVehiclePhotoTitle = (index) => {
                            switch (index) {
                              case 0: return 'Front View with Number Plate';
                              case 1: return 'Rear View with Number Plate'; 
                              default: return `Vehicle Photo ${index + 1}`;
                            }
                          };

                          const getVehiclePhotoDescription = (index) => {
                            switch (index) {
                              case 0: return 'Clear front view showing number plate';
                              case 1: return 'Clear rear view showing number plate';
                              default: return 'Additional vehicle photo';
                            }
                          };

                          const isRequired = index < 2; // First two photos are required
                          
                          return (
                            <TableRow key={index} hover>
                              <TableCell>
                                <Box display="flex" alignItems="center" gap={2}>
                                  <Avatar sx={{ 
                                    bgcolor: displayStatus === 'approved' ? 'success.main' : 
                                            displayStatus === 'rejected' ? 'error.main' : 'grey.400',
                                    width: 40, height: 40
                                  }}>
                                    <ImageIcon />
                                  </Avatar>
                                  <Box>
                                    <Typography variant="subtitle1" fontWeight="medium">
                                      {getVehiclePhotoTitle(index)}
                                    </Typography>
                                    <Typography variant="body2" color="text.secondary">
                                      {getVehiclePhotoDescription(index)}
                                    </Typography>
                                  </Box>
                                </Box>
                              </TableCell>
                              <TableCell>
                                <Chip 
                                  label={displayStatus ? displayStatus.charAt(0).toUpperCase() + displayStatus.slice(1) : 'Pending'} 
                                  color={getStatusColor(displayStatus)} 
                                  icon={getStatusIcon(displayStatus)}
                                  size="small"
                                />
                              </TableCell>
                              <TableCell>
                                <Chip 
                                  label={isRequired ? "Required" : "Optional"} 
                                  color={isRequired ? "warning" : "default"} 
                                  size="small"
                                  variant="outlined"
                                />
                              </TableCell>
                              <TableCell align="center">
                                <Box display="flex" gap={1} justifyContent="center" alignItems="center">
                                  <Button
                                    size="small"
                                    startIcon={<ViewIcon />}
                                    onClick={() => viewDocument(imageUrl, getVehiclePhotoTitle(index))}
                                    variant="outlined"
                                    color="primary"
                                  >
                                    View
                                  </Button>
                                  <Button
                                    size="small"
                                    startIcon={<DownloadIcon />}
                                    onClick={() => window.open(imageUrl, '_blank')}
                                    variant="text"
                                    color="primary"
                                  >
                                    Download
                                  </Button>
                                  {displayStatus === 'pending' && !isDriverApproved && (
                                    <>
                                      <Button 
                                        size="small"
                                        color="success"
                                        startIcon={<CheckIcon />}
                                        onClick={() => handleVehicleImageAction(selectedDriver, index, 'approved')}
                                        disabled={actionLoading}
                                        variant="contained"
                                        sx={{ ml: 1 }}
                                      >
                                        APPROVE
                                      </Button>
                                      <Button 
                                        size="small"
                                        color="error"
                                        startIcon={<CloseIcon />}
                                        onClick={() => handleVehicleImageAction(selectedDriver, index, 'reject')}
                                        disabled={actionLoading}
                                        variant="outlined"
                                        sx={{ ml: 1 }}
                                      >
                                        REJECT
                                      </Button>
                                    </>
                                  )}
                                </Box>
                              </TableCell>
                            </TableRow>
                          );
                          });
                        })()}
                      </TableBody>
                    </Table>
                  </TableContainer>
                </Box>
              )}
            </Box>
          )}

          {tabValue === 2 && (
            <Box sx={{ mt: 2 }}>
              <Alert severity="info" sx={{ mb: 3 }}>
                <Typography variant="subtitle2" gutterBottom>
                  Contact Verification Status
                </Typography>
                <Typography variant="body2">
                  Phone number verification is mandatory and handled automatically in the mobile app. Phone must be verified before driver approval.
                </Typography>
              </Alert>
              
              <Grid container spacing={3}>
                <Grid item xs={12} md={6}>
                  <Card variant="outlined">
                    <CardHeader
                      avatar={
                        <Avatar sx={{ bgcolor: (() => {
                          const phoneStatus = getPhoneVerificationStatus(selectedDriver);
                          return phoneStatus.isVerified ? 'success.main' : 'grey.400';
                        })() }}>
                          <PhoneIcon />
                        </Avatar>
                      }
                      title="Phone Verification"
                      subheader="Primary contact number"
                    />
                    <CardContent>
                      <Box mb={2}>
                        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                          Phone Number
                        </Typography>
                        <Typography variant="body1" fontWeight="medium">
                          {selectedDriver.phoneNumber || 'Not provided'}
                        </Typography>
                      </Box>
                      <Box mb={2}>
                        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                          Verification Status
                        </Typography>
                        {(() => {
                          const phoneStatus = getPhoneVerificationStatus(selectedDriver);
                          return (
                            <Chip 
                              label={phoneStatus.isVerified ? 'Verified' : 'Not Verified'}
                              color={phoneStatus.isVerified ? 'success' : 'default'}
                              icon={phoneStatus.isVerified ? <CheckIcon /> : <ErrorIcon />}
                            />
                          );
                        })()}
                      </Box>
                      {(() => {
                        const phoneStatus = getPhoneVerificationStatus(selectedDriver);
                        if (phoneStatus.isVerified) {
                          return (
                            <Box mb={1}>
                              <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                Verified Via
                              </Typography>
                              <Typography variant="body2">
                                {phoneStatus.source === 'firebase_auth' ? 'Firebase Authentication' : 
                                 phoneStatus.source === 'firebase_auth_registration' ? 'Firebase Auth (Registration)' : 
                                 'Manual Verification'}
                              </Typography>
                            </Box>
                          );
                        } else if (phoneStatus.needsManualVerification) {
                          return (
                            <Box mb={1}>
                              <Alert severity="warning" sx={{ mb: 2 }}>
                                <Typography variant="body2">
                                  Phone number needs verification. Driver should verify this number in the mobile app.
                                </Typography>
                              </Alert>
                              <Button
                                variant="outlined"
                                color="primary"
                                startIcon={<PhoneIcon />}
                                size="small"
                                onClick={() => {
                                  // TODO: Implement manual verification trigger
                                  alert('Manual verification will be implemented for different phone numbers');
                                }}
                              >
                                Trigger Manual Verification
                              </Button>
                            </Box>
                          );
                        }
                        return null;
                      })()}
                    </CardContent>
                  </Card>
                </Grid>
                
                <Grid item xs={12} md={6}>
                  <Card variant="outlined">
                    <CardHeader
                      avatar={
                        <Avatar sx={{ bgcolor: selectedDriver.emailVerified ? 'success.main' : 'grey.400' }}>
                          <EmailIcon />
                        </Avatar>
                      }
                      title="Email Verification"
                      subheader="Primary contact email"
                    />
                    <CardContent>
                      <Box mb={2}>
                        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                          Email Address
                        </Typography>
                        <Typography variant="body1" fontWeight="medium">
                          {selectedDriver.email || 'Not provided'}
                        </Typography>
                      </Box>
                      <Box mb={2}>
                        <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                          Verification Status
                        </Typography>
                        <Chip 
                          label={selectedDriver.emailVerified ? 'Verified' : 'Not Verified'}
                          color={selectedDriver.emailVerified ? 'success' : 'default'}
                          icon={selectedDriver.emailVerified ? <CheckIcon /> : <ErrorIcon />}
                        />
                      </Box>
                      {selectedDriver.emailVerified && (
                        <Box mb={1}>
                          <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                            Verified On
                          </Typography>
                          <Typography variant="body2">
                            Verified via mobile app registration
                          </Typography>
                        </Box>
                      )}
                    </CardContent>
                  </Card>
                </Grid>
              </Grid>
            </Box>
          )}

          {tabValue === 3 && (
            <Box sx={{ mt: 2 }}>
              <Grid container spacing={3}>
                {/* Vehicle Details Card */}
                <Grid item xs={12} md={6}>
                  <Card variant="outlined" sx={{ height: 'fit-content' }}>
                    <CardHeader
                      avatar={
                        <Avatar sx={{ bgcolor: 'primary.main', width: 48, height: 48 }}>
                          {getVehicleIcon(selectedDriver.vehicleTypeName)}
                        </Avatar>
                      }
                      title="Vehicle Details"
                      subheader="Primary vehicle information"
                    />
                    <CardContent>
                      <Grid container spacing={2}>
                        <Grid item xs={12}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              Vehicle Type
                            </Typography>
                            <Typography variant="body1" fontWeight="medium">
                              {selectedDriver.vehicleType ? (
                                <Box display="flex" alignItems="center" gap={1}>
                                  <Chip 
                                    label={selectedDriver.vehicleTypeName || 'Unknown'} 
                                    color="primary" 
                                    size="small" 
                                    variant="outlined"
                                  />
                                </Box>
                              ) : (
                                <Typography color="text.secondary" variant="body2">Not specified</Typography>
                              )}
                            </Typography>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={6}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              Make
                            </Typography>
                            <Typography variant="body1" fontWeight="medium">
                              {selectedDriver.vehicleMake || 'Not provided'}
                            </Typography>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={6}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              Model
                            </Typography>
                            <Typography variant="body1">
                              {selectedDriver.vehicleModel || 'Not provided'}
                            </Typography>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={6}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              Year
                            </Typography>
                            <Typography variant="body1">
                              {selectedDriver.vehicleYear || 'Not provided'}
                            </Typography>
                          </Box>
                        </Grid>
                        
                        <Grid item xs={6}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              Color
                            </Typography>
                            <Typography variant="body1">
                              {selectedDriver.vehicleColor || 'Not provided'}
                            </Typography>
                          </Box>
                        </Grid>
                      </Grid>
                    </CardContent>
                  </Card>
                </Grid>

                {/* License Plate & Registration Card */}
                <Grid item xs={12} md={6}>
                  <Card variant="outlined" sx={{ height: 'fit-content' }}>
                    <CardHeader
                      avatar={<AssignmentIcon color="primary" />}
                      title="Registration Details"
                      subheader="License plate and registration info"
                    />
                    <CardContent>
                      <Grid container spacing={2}>
                        <Grid item xs={12}>
                          <Box mb={2}>
                            <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                              License Plate Number
                            </Typography>
                            <Typography variant="h6" fontFamily="monospace" color="primary">
                              {selectedDriver.vehicleNumber || 'Not provided'}
                            </Typography>
                          </Box>
                        </Grid>
                        
                        {selectedDriver.vehicleRegistration && (
                          <Grid item xs={12}>
                            <Box mb={2}>
                              <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                                Registration Status
                              </Typography>
                              <Chip 
                                label="Registration Document Submitted" 
                                color="success" 
                                size="small" 
                                icon={<CheckIcon />}
                              />
                            </Box>
                          </Grid>
                        )}
                      </Grid>
                    </CardContent>
                  </Card>
                </Grid>

                {/* Vehicle Images Section */}
                <Grid item xs={12}>
                  <Card variant="outlined">
                    <CardHeader
                      avatar={<ImageIcon color="primary" />}
                      title="Vehicle Photos"
                      subheader="Submitted vehicle images for verification"
                    />
                    <CardContent>
                      {Array.isArray(selectedDriver.vehicleImages) && selectedDriver.vehicleImages.length > 0 ? (
                        <Grid container spacing={2}>
                          {selectedDriver.vehicleImages.map((imageUrl, index) => {
                            if (!imageUrl) return null;
                            
                            const status = getVehicleImageStatus(selectedDriver, index);
                            const isDriverApproved = selectedDriver.status === 'approved';
                            const displayStatus = isDriverApproved ? 'approved' : status;
                            
                            return (
                              <Grid item xs={12} sm={6} md={4} key={index}>
                                <Card 
                                  variant="outlined" 
                                  sx={{ 
                                    height: '100%',
                                    border: displayStatus === 'approved' ? 2 : 1,
                                    borderColor: displayStatus === 'approved' ? 'success.main' : 
                                                displayStatus === 'rejected' ? 'error.main' : 'divider'
                                  }}
                                >
                                  <Box sx={{ position: 'relative' }}>
                                    <CardMedia
                                      component="img"
                                      height="120"
                                      image={imageUrl}
                                      alt={`Vehicle Image ${index + 1}`}
                                      sx={{ 
                                        objectFit: 'cover',
                                        cursor: 'pointer',
                                        '&:hover': { 
                                          opacity: 0.9
                                        }
                                      }}
                                      onClick={() => viewDocument(imageUrl, `Vehicle Photo ${index + 1}`)}
                                    />
                                    <Box 
                                      sx={{ 
                                        position: 'absolute',
                                        top: 8,
                                        right: 8,
                                        bgcolor: 'rgba(0,0,0,0.7)',
                                        borderRadius: 1,
                                        p: 0.5
                                      }}
                                    >
                                      <Chip 
                                        label={displayStatus ? displayStatus.charAt(0).toUpperCase() + displayStatus.slice(1) : 'Pending'} 
                                        color={getStatusColor(displayStatus)} 
                                        size="small"
                                        sx={{ fontSize: '0.7rem', height: 20 }}
                                      />
                                    </Box>
                                  </Box>
                                  
                                  <CardContent sx={{ p: 1.5, '&:last-child': { pb: 1.5 } }}>
                                    <Typography variant="caption" color="text.secondary" display="block" gutterBottom>
                                      Vehicle Photo {index + 1}
                                    </Typography>
                                    <Box display="flex" gap={1}>
                                      <Button
                                        size="small"
                                        startIcon={<ViewIcon />}
                                        onClick={() => viewDocument(imageUrl, `Vehicle Photo ${index + 1}`)}
                                        variant="outlined"
                                        sx={{ fontSize: '0.7rem', py: 0.5 }}
                                      >
                                        View
                                      </Button>
                                      <Button
                                        size="small"
                                        startIcon={<DownloadIcon />}
                                        onClick={() => window.open(imageUrl, '_blank')}
                                        variant="text"
                                        sx={{ fontSize: '0.7rem', py: 0.5 }}
                                      >
                                        Download
                                      </Button>
                                    </Box>
                                  </CardContent>
                                </Card>
                              </Grid>
                            );
                          })}
                        </Grid>
                      ) : (
                        <Box 
                          sx={{ 
                            display: 'flex', 
                            alignItems: 'center', 
                            justifyContent: 'center',
                            py: 4,
                            bgcolor: 'grey.50',
                            borderRadius: 1
                          }}
                        >
                          <Box textAlign="center">
                            <ImageIcon sx={{ fontSize: 48, opacity: 0.3, color: 'text.secondary' }} />
                            <Typography variant="body2" color="text.secondary" mt={1}>
                              No vehicle photos submitted
                            </Typography>
                          </Box>
                        </Box>
                      )}
                    </CardContent>
                  </Card>
                </Grid>
              </Grid>
            </Box>
          )}

          {tabValue === 4 && (
            <Box sx={{ mt: 2 }}>
              <Card variant="outlined">
                <CardHeader
                  avatar={<TimeIcon color="primary" />}
                  title="Verification Timeline"
                  subheader="Driver verification process history"
                />
                <CardContent>
                  <Box>
                    <Box display="flex" alignItems="center" gap={2} mb={2} p={2} 
                         sx={{ bgcolor: 'primary.50', borderRadius: 1 }}>
                      <Avatar sx={{ bgcolor: 'primary.main', width: 32, height: 32 }}>
                        <CheckIcon fontSize="small" />
                      </Avatar>
                      <Box flex={1}>
                        <Typography variant="subtitle2" fontWeight="medium">
                          Application Submitted
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {selectedDriver.createdAt ? 
                            new Date(selectedDriver.createdAt).toLocaleString() : 
                            selectedDriver.submissionDate ? 
                            new Date(selectedDriver.submissionDate).toLocaleString() :
                            'Unknown'
                          }
                        </Typography>
                      </Box>
                      <Chip label="Completed" color="primary" size="small" />
                    </Box>

                    {selectedDriver.status === 'approved' && (
                      <Box display="flex" alignItems="center" gap={2} mb={2} p={2} 
                           sx={{ bgcolor: 'success.50', borderRadius: 1 }}>
                        <Avatar sx={{ bgcolor: 'success.main', width: 32, height: 32 }}>
                          <VerifiedIcon fontSize="small" />
                        </Avatar>
                        <Box flex={1}>
                          <Typography variant="subtitle2" fontWeight="medium">
                            Driver Approved
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            Driver verification completed successfully
                          </Typography>
                        </Box>
                        <Chip label="Approved" color="success" size="small" />
                      </Box>
                    )}

                    {selectedDriver.status === 'rejected' && (
                      <Box display="flex" alignItems="center" gap={2} mb={2} p={2} 
                           sx={{ bgcolor: 'error.50', borderRadius: 1 }}>
                        <Avatar sx={{ bgcolor: 'error.main', width: 32, height: 32 }}>
                          <ErrorIcon fontSize="small" />
                        </Avatar>
                        <Box flex={1}>
                          <Typography variant="subtitle2" fontWeight="medium">
                            Driver Rejected
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {selectedDriver.rejectionReason || 'Verification requirements not met'}
                          </Typography>
                        </Box>
                        <Chip label="Rejected" color="error" size="small" />
                      </Box>
                    )}

                    {selectedDriver.status === 'pending' && (
                      <Box display="flex" alignItems="center" gap={2} mb={2} p={2} 
                           sx={{ bgcolor: 'warning.50', borderRadius: 1 }}>
                        <Avatar sx={{ bgcolor: 'warning.main', width: 32, height: 32 }}>
                          <PendingIcon fontSize="small" />
                        </Avatar>
                        <Box flex={1}>
                          <Typography variant="subtitle2" fontWeight="medium">
                            Pending Review
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            Awaiting admin verification and approval
                          </Typography>
                        </Box>
                        <Chip label="Pending" color="warning" size="small" />
                      </Box>
                    )}
                  </Box>
                </CardContent>
              </Card>
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
