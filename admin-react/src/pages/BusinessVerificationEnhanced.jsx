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
  Tabs,
  Tab,
  Badge,
  Accordion,
  AccordionSummary,
  AccordionDetails
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
  Visibility as ViewIcon,
  Image as ImageIcon,
  ExpandMore as ExpandMoreIcon,
  Warning as WarningIcon,
  CheckCircleOutline as CheckIcon,
  RadioButtonUnchecked as PendingIcon,
  Error as ErrorIcon
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

const BusinessVerificationEnhanced = () => {
  const { adminData, isCountryAdmin, isSuperAdmin } = useAuth();
  const [businesses, setBusinesses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedBusiness, setSelectedBusiness] = useState(null);
  const [detailsOpen, setDetailsOpen] = useState(false);
  const [filterStatus, setFilterStatus] = useState('all');
  const [tabValue, setTabValue] = useState(0);
  
  // Document verification states
  const [documentDialog, setDocumentDialog] = useState({ open: false, document: null, type: '' });
  const [rejectionDialog, setRejectionDialog] = useState({ open: false, target: null, type: '' });
  const [rejectionReason, setRejectionReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    loadBusinesses();
  }, [filterStatus]);

  const loadBusinesses = async () => {
    try {
      setLoading(true);
      console.log('🔄 Loading businesses...');
      
      let businessQuery = collection(db, 'new_business_verifications');
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
        businessQuery = query(businessQuery, ...conditions);
      }

      const snapshot = await getDocs(businessQuery);
      const businessList = [];
      const missingCountryBusinesses = [];
      
      for (const docSnapshot of snapshot.docs) {
        const data = docSnapshot.data();
        const businessData = { id: docSnapshot.id, ...data };
        
        // Auto-migrate missing country field
        if (!data.country && data.userId && isSuperAdmin) {
          missingCountryBusinesses.push({ docRef: docSnapshot.ref, data: businessData });
        }
        
        businessList.push(businessData);
      }
      
      // Fix missing country data
      for (const { docRef, data } of missingCountryBusinesses) {
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
          
          const businessIndex = businessList.findIndex(b => b.id === data.id);
          if (businessIndex !== -1) {
            businessList[businessIndex].country = countryToSet;
            businessList[businessIndex].countryName = countryNameToSet;
          }
        } catch (error) {
          console.error(`Failed to update country for ${data.businessName}:`, error);
        }
      }
      
      // Sort by created date
      businessList.sort((a, b) => {
        const aTime = a.submittedAt?.toDate?.() || a.createdAt?.toDate?.() || new Date(0);
        const bTime = b.submittedAt?.toDate?.() || b.createdAt?.toDate?.() || new Date(0);
        return bTime - aTime;
      });
      
      setBusinesses(businessList);
      console.log(`Loaded ${businessList.length} businesses`);
    } catch (error) {
      console.error('Error loading businesses:', error);
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

  const getDocumentStatus = (business, docType) => {
    const docVerification = business.documentVerification?.[docType];
    if (docVerification?.status) return docVerification.status;
    
    // Fallback to flat status fields
    switch (docType) {
      case 'businessLicense': return business.businessLicenseStatus || 'pending';
      case 'taxCertificate': return business.taxCertificateStatus || 'pending';
      case 'insuranceDocument': return business.insuranceDocumentStatus || 'pending';
      case 'businessLogo': return business.businessLogoStatus || 'pending';
      default: return 'pending';
    }
  };

  const getDocumentUrl = (business, docType) => {
    switch (docType) {
      case 'businessLicense': return business.businessLicenseUrl;
      case 'taxCertificate': return business.taxCertificateUrl;
      case 'insuranceDocument': return business.insuranceDocumentUrl;
      case 'businessLogo': return business.businessLogoUrl;
      default: return null;
    }
  };

  const handleDocumentAction = async (business, docType, action) => {
    if (action === 'reject') {
      setRejectionDialog({ 
        open: true, 
        target: business,
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

      await updateDoc(doc(db, 'new_business_verifications', business.id), updateData);
      await loadBusinesses(); // Refresh data
      console.log(`✅ Document ${docType} ${action} for ${business.businessName}`);
    } catch (error) {
      console.error(`Error updating document status:`, error);
    } finally {
      setActionLoading(false);
    }
  };

  const handleBusinessAction = async (business, action) => {
    if (action === 'reject') {
      setRejectionDialog({ 
        open: true, 
        target: business,
        type: 'business'
      });
      return;
    }

    if (action === 'approve') {
      // Check if all documents are approved
      const docTypes = ['businessLicense', 'taxCertificate', 'insuranceDocument', 'businessLogo'];
      const allDocsApproved = docTypes.every(docType => {
        const status = getDocumentStatus(business, docType);
        const url = getDocumentUrl(business, docType);
        return !url || status === 'approved'; // Skip missing documents
      });

      if (!allDocsApproved) {
        alert('All submitted documents must be approved before approving the business.');
        return;
      }

      // Check contact verification
      try {
        const userDoc = await getDoc(doc(db, 'users', business.userId));
        if (userDoc.exists()) {
          const userData = userDoc.data();
          const linkedCredentials = userData.linkedCredentials || {};
          const phoneVerified = linkedCredentials.linkedPhoneVerified || false;
          const emailVerified = linkedCredentials.linkedEmailVerified || false;

          if (!phoneVerified || !emailVerified) {
            const missing = [];
            if (!phoneVerified) missing.push('phone');
            if (!emailVerified) missing.push('email');
            alert(`Cannot approve business. User must verify: ${missing.join(', ')}`);
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

      await updateDoc(doc(db, 'new_business_verifications', business.id), updateData);
      await loadBusinesses();
      console.log(`✅ Business ${action}: ${business.businessName}`);
    } catch (error) {
      console.error(`Error ${action} business:`, error);
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

      await updateDoc(doc(db, 'new_business_verifications', target.id), updateData);
      await loadBusinesses();
      
      setRejectionDialog({ open: false, target: null, type: '' });
      setRejectionReason('');
      console.log(`✅ ${type} rejected: ${target.businessName}`);
    } catch (error) {
      console.error(`Error rejecting ${type}:`, error);
    } finally {
      setActionLoading(false);
    }
  };

  const viewDocument = (url) => {
    if (url) {
      window.open(url, '_blank');
    }
  };

  const renderBusinessCard = (business) => {
    const overallStatus = business.status || 'pending';
    const documentsCount = ['businessLicense', 'taxCertificate', 'insuranceDocument', 'businessLogo']
      .filter(docType => getDocumentUrl(business, docType)).length;
    const approvedDocsCount = ['businessLicense', 'taxCertificate', 'insuranceDocument', 'businessLogo']
      .filter(docType => {
        const url = getDocumentUrl(business, docType);
        const status = getDocumentStatus(business, docType);
        return url && status === 'approved';
      }).length;

    return (
      <Card key={business.id} sx={{ mb: 2 }}>
        <CardContent>
          <Box display="flex" justifyContent="space-between" alignItems="flex-start">
            <Box flex={1}>
              <Box display="flex" alignItems="center" gap={1} mb={1}>
                <BusinessIcon color="primary" />
                <Typography variant="h6">{business.businessName || 'Unknown Business'}</Typography>
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
                    <Typography variant="body2">{business.country || 'Unknown'} • {business.businessAddress || 'No address'}</Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <EmailIcon fontSize="small" color="action" />
                    <Typography variant="body2">{business.businessEmail || 'No email'}</Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Box display="flex" alignItems="center" gap={1}>
                    <PhoneIcon fontSize="small" color="action" />
                    <Typography variant="body2">{business.businessPhone || 'No phone'}</Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Typography variant="body2">
                    Applied: {business.submittedAt?.toDate?.()?.toLocaleDateString() || 'Unknown'}
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
                onClick={() => { setSelectedBusiness(business); setDetailsOpen(true); }}
                size="small"
              >
                View Details
              </Button>
              
              {business.status === 'pending' && (
                <>
                  <Button
                    startIcon={<ApproveIcon />}
                    color="success"
                    onClick={() => handleBusinessAction(business, 'approve')}
                    disabled={actionLoading}
                    size="small"
                  >
                    Approve
                  </Button>
                  <Button
                    startIcon={<RejectIcon />}
                    color="error"
                    onClick={() => handleBusinessAction(business, 'reject')}
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

  const renderDocumentCard = (business, docType, title) => {
    const url = getDocumentUrl(business, docType);
    const status = getDocumentStatus(business, docType);
    const rejectionReason = business.documentVerification?.[docType]?.rejectionReason || 
                           business[`${docType}RejectionReason`];

    if (!url) {
      return (
        <Card sx={{ mb: 1, opacity: 0.6 }}>
          <CardContent>
            <Box display="flex" justifyContent="space-between" alignItems="center">
              <Typography variant="subtitle2" color="text.secondary">
                {title} (Not submitted)
              </Typography>
              <Chip label="N/A" size="small" variant="outlined" />
            </Box>
          </CardContent>
        </Card>
      );
    }

    return (
      <Card sx={{ mb: 1 }}>
        <CardContent>
          <Box display="flex" justifyContent="space-between" alignItems="center">
            <Box>
              <Typography variant="subtitle2">{title}</Typography>
              <Chip 
                label={status} 
                color={getStatusColor(status)} 
                size="small" 
                icon={getStatusIcon(status)}
              />
              {rejectionReason && (
                <Typography variant="caption" color="error" display="block" sx={{ mt: 1 }}>
                  Reason: {rejectionReason}
                </Typography>
              )}
            </Box>
            
            <Box display="flex" gap={1}>
              <IconButton onClick={() => viewDocument(url)} size="small">
                <ViewIcon />
              </IconButton>
              
              {status === 'pending' && (
                <>
                  <IconButton 
                    onClick={() => handleDocumentAction(business, docType, 'approved')}
                    color="success"
                    size="small"
                    disabled={actionLoading}
                  >
                    <CheckIcon />
                  </IconButton>
                  <IconButton 
                    onClick={() => handleDocumentAction(business, docType, 'reject')}
                    color="error"
                    size="small"
                    disabled={actionLoading}
                  >
                    <ErrorIcon />
                  </IconButton>
                </>
              )}
            </Box>
          </Box>
        </CardContent>
      </Card>
    );
  };

  const renderBusinessDetails = () => {
    if (!selectedBusiness) return null;

    return (
      <Dialog open={detailsOpen} onClose={() => setDetailsOpen(false)} maxWidth="md" fullWidth>
        <DialogTitle>
          <Box display="flex" alignItems="center" gap={2}>
            <BusinessIcon />
            <Box>
              <Typography variant="h6">{selectedBusiness.businessName}</Typography>
              <Chip 
                label={selectedBusiness.status || 'pending'} 
                color={getStatusColor(selectedBusiness.status)} 
                size="small"
              />
            </Box>
          </Box>
        </DialogTitle>
        
        <DialogContent>
          <Tabs value={tabValue} onChange={(e, v) => setTabValue(v)}>
            <Tab label="Business Info" />
            <Tab label="Documents" />
            <Tab label="Contact Verification" />
          </Tabs>

          {tabValue === 0 && (
            <Box sx={{ mt: 2 }}>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="Business Name"
                    value={selectedBusiness.businessName || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="Category"
                    value={selectedBusiness.businessCategory || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    label="Description"
                    value={selectedBusiness.businessDescription || ''}
                    fullWidth
                    disabled
                    multiline
                    rows={3}
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="Email"
                    value={selectedBusiness.businessEmail || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="Phone"
                    value={selectedBusiness.businessPhone || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12}>
                  <TextField
                    label="Address"
                    value={selectedBusiness.businessAddress || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="License Number"
                    value={selectedBusiness.licenseNumber || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <TextField
                    label="Tax ID"
                    value={selectedBusiness.taxId || ''}
                    fullWidth
                    disabled
                    margin="normal"
                  />
                </Grid>
              </Grid>
            </Box>
          )}

          {tabValue === 1 && (
            <Box sx={{ mt: 2 }}>
              {renderDocumentCard(selectedBusiness, 'businessLicense', 'Business License')}
              {renderDocumentCard(selectedBusiness, 'taxCertificate', 'Tax Certificate')}
              {renderDocumentCard(selectedBusiness, 'insuranceDocument', 'Insurance Document')}
              {renderDocumentCard(selectedBusiness, 'businessLogo', 'Business Logo')}
            </Box>
          )}

          {tabValue === 2 && (
            <Box sx={{ mt: 2 }}>
              <Alert severity="info" sx={{ mb: 2 }}>
                Contact verification is handled by the user in the mobile app. 
                Both phone and email must be verified before business approval.
              </Alert>
              
              <Typography variant="subtitle1" gutterBottom>
                Contact Information:
              </Typography>
              <Box display="flex" alignItems="center" gap={1} mb={1}>
                <PhoneIcon />
                <Typography>{selectedBusiness.businessPhone || 'No phone'}</Typography>
              </Box>
              <Box display="flex" alignItems="center" gap={1}>
                <EmailIcon />
                <Typography>{selectedBusiness.businessEmail || 'No email'}</Typography>
              </Box>
            </Box>
          )}
        </DialogContent>

        <DialogActions>
          <Button onClick={() => setDetailsOpen(false)}>Close</Button>
          {selectedBusiness.status === 'pending' && (
            <>
              <Button 
                color="error"
                onClick={() => handleBusinessAction(selectedBusiness, 'reject')}
                disabled={actionLoading}
              >
                Reject Business
              </Button>
              <Button 
                color="success" 
                variant="contained"
                onClick={() => handleBusinessAction(selectedBusiness, 'approve')}
                disabled={actionLoading}
              >
                Approve Business
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
        Business Verification
      </Typography>
      
      <Typography variant="subtitle1" color="text.secondary" gutterBottom>
        Manage business verifications for {adminData?.country || 'all countries'}
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
        
        <Button variant="outlined" onClick={loadBusinesses}>
          Refresh
        </Button>
      </Box>

      {businesses.length === 0 ? (
        <Alert severity="info">
          No business verifications found for the selected filters.
        </Alert>
      ) : (
        businesses.map(renderBusinessCard)
      )}

      {renderBusinessDetails()}

      {/* Rejection Dialog */}
      <Dialog open={rejectionDialog.open} onClose={() => setRejectionDialog({ open: false, target: null, type: '' })}>
        <DialogTitle>
          Reject {rejectionDialog.type === 'document' ? 'Document' : 'Business'}
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
    </Container>
  );
};

export default BusinessVerificationEnhanced;
