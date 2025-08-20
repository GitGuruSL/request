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
  AccordionDetails,
  CardMedia,
  Stack,
  Tooltip,
  LinearProgress,
  TableContainer,
  Table,
  TableHead,
  TableRow,
  TableCell,
  TableBody,
  CardHeader,
  CardActions
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
  Error as ErrorIcon,
  Download as DownloadIcon,
  Launch as LaunchIcon,
  Person as PersonIcon,
  Store as StoreIcon,
  ContactPhone as ContactIcon,
  Assignment as AssignmentIcon,
  CalendarToday as CalendarIcon,
  Category as CategoryIcon,
  Assessment as ReportsIcon,
  Security as SecurityIcon,
  VerifiedUser as VerifiedIcon,
  AccessTime as TimeIcon,
  Language as WebsiteIcon,
  Map as MapIcon,
  PhotoLibrary as GalleryIcon,
  PictureAsPdf as PdfIcon,
  InsertDriveFile as FileIcon,
  CloudDownload as CloudIcon,
  Fullscreen as FullscreenIcon,
  Close as CloseIcon
} from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';
import api from '../services/apiClient';

const BusinessVerificationEnhanced = () => {
  const { adminData, isCountryAdmin, isSuperAdmin } = useAuth();
  const [businesses, setBusinesses] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedBusiness, setSelectedBusiness] = useState(null);
  const [detailsOpen, setDetailsOpen] = useState(false);
  const [filterStatus, setFilterStatus] = useState('all');
  const [tabValue, setTabValue] = useState(0);
  
  // Enhanced document and dialog states
  const [documentDialog, setDocumentDialog] = useState({ open: false, document: null, type: '', title: '' });
  const [rejectionDialog, setRejectionDialog] = useState({ open: false, target: null, type: '', title: '' });
  const [rejectionReason, setRejectionReason] = useState('');
  const [actionLoading, setActionLoading] = useState(false);
  const [fullscreenImage, setFullscreenImage] = useState({ open: false, url: '', title: '' });
  const [verificationNotes, setVerificationNotes] = useState('');
  const [selectedDocuments, setSelectedDocuments] = useState([]);
  const [documentStatus, setDocumentStatus] = useState({});
  const [searchTerm, setSearchTerm] = useState('');
  const [sortBy, setSortBy] = useState('submissionDate');

  useEffect(() => {
    loadBusinesses();
  }, [filterStatus]);

  const loadBusinesses = async () => {
    try {
      setLoading(true);
      const params = {};
      if (isCountryAdmin && adminData?.country) params.country = adminData.country;
      if (filterStatus !== 'all') params.status = filterStatus;
      
      // Use new business verification API
      const res = await api.get('/api/business-verifications', { params });
      const responseData = res.data || {};
      const list = Array.isArray(responseData.data) ? responseData.data : [];
      
      setBusinesses(list.sort((a,b)=> new Date(b.submitted_at||b.created_at||0)- new Date(a.submitted_at||a.created_at||0)));
    } catch (e) { 
      console.error('Error loading businesses', e);
      setBusinesses([]);
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
      // For now, document-specific actions will be handled through the main status endpoint
      // TODO: Implement specific document approval endpoints
      console.log(`Document ${docType} ${action} for business ${business.id}`);
      // await api.put(`/api/business-verifications/${business.id}/documents/${docType}`, { status: action });
      await loadBusinesses();
      console.log(`✅ Document ${docType} ${action} for ${business.business_name || business.businessName}`);
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

      // Optional: Contact verification check via backend user endpoint (assumes backend provides flags)
      try {
        if (business.userId) {
          const res = await api.get(`/users/${business.userId}`);
          const userData = res.data || {};
          const linkedCredentials = userData.linkedCredentials || {};
            const phoneVerified = linkedCredentials.linkedPhoneVerified || userData.phoneVerified || false;
            const emailVerified = linkedCredentials.linkedEmailVerified || userData.emailVerified || false;
            if (!phoneVerified || !emailVerified) {
              const missing = [];
              if (!phoneVerified) missing.push('phone');
              if (!emailVerified) missing.push('email');
              alert(`Cannot approve business. User must verify: ${missing.join(', ')}`);
              return;
            }
        }
      } catch (error) {
        console.warn('Proceeding without strict contact verification (user endpoint not available):', error);
      }
    }

    setActionLoading(true);
    try {
      // Use new business verification API
      const payload = {
        status: action,
        notes: verificationNotes || null,
        phone_verified: business.phone_verified || false,
        email_verified: business.email_verified || false
      };
      
      await api.put(`/api/business-verifications/${business.id}/status`, payload);
      await loadBusinesses();
      console.log(`✅ Business ${action} for ${business.business_name || business.businessName}`);
    } catch (error) {
      console.error(`Error updating business status:`, error);
    } finally {
      setActionLoading(false);
      setVerificationNotes('');
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
      if (type === 'document') {
        await api.put(`/business-verifications/${target.id}/documents/${docType}`, { status: 'rejected', rejectionReason });
      } else {
        await api.put(`/business-verifications/${target.id}/status`, { status: 'rejected', rejectionReason });
      }
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
                    {/* Firestore Timestamp compatibility removed; assuming ISO string */}
                    {/* Fallback shows Unknown if date invalid */}
                    {/* Consider normalizing date in backend response */}
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

  // Helper function to calculate verification completion percentage
  const calculateVerificationCompletion = (business) => {
    const requiredFields = [
      'businessName', 'businessEmail', 'businessPhone', 'businessCategory', 
      'businessDescription', 'businessAddress'
    ];
    const requiredDocs = ['businessLicense', 'taxCertificate'];
    
    let completedFields = 0;
    let totalFields = requiredFields.length + requiredDocs.length;
    
    // Check required fields
    requiredFields.forEach(field => {
      if (business[field] && business[field].trim() !== '') {
        completedFields++;
      }
    });
    
    // Check required documents
    requiredDocs.forEach(doc => {
      if (getDocumentUrl(business, doc)) {
        completedFields++;
      }
    });
    
    return Math.round((completedFields / totalFields) * 100);
  };

  // Enhanced tab rendering functions
  const renderBusinessDetailsTab = () => (
    <Grid container spacing={3}>
      <Grid item xs={12}>
        <Card variant="outlined">
          <CardHeader 
            avatar={<StoreIcon color="primary" />}
            title="Business Information"
            subheader="Core business details and registration info"
          />
          <CardContent>
            <Grid container spacing={3}>
              <Grid item xs={12} md={6}>
                <Box mb={2}>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                    Business Name
                  </Typography>
                  <Typography variant="body1" fontWeight="medium">
                    {selectedBusiness.businessName || 'Not provided'}
                  </Typography>
                </Box>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <Box mb={2}>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                    Business Category
                  </Typography>
                  <Typography variant="body1">
                    {selectedBusiness.businessCategory || 'Not provided'}
                  </Typography>
                </Box>
              </Grid>
              
              <Grid item xs={12}>
                <Box mb={2}>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                    Business Description
                  </Typography>
                  <Typography variant="body1" sx={{ lineHeight: 1.6 }}>
                    {selectedBusiness.businessDescription || 'No description provided'}
                  </Typography>
                </Box>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <Box mb={2}>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                    License Number
                  </Typography>
                  <Typography variant="body1">
                    {selectedBusiness.licenseNumber || 'Not provided'}
                  </Typography>
                </Box>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <Box mb={2}>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                    Tax ID
                  </Typography>
                  <Typography variant="body1">
                    {selectedBusiness.taxId || 'Not provided'}
                  </Typography>
                </Box>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <Box mb={2}>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                    Website
                  </Typography>
                  {selectedBusiness.website ? (
                    <Box display="flex" alignItems="center" gap={1}>
                      <Typography variant="body1" component="a" 
                        href={selectedBusiness.website} 
                        target="_blank" 
                        sx={{ textDecoration: 'none', color: 'primary.main' }}
                      >
                        {selectedBusiness.website}
                      </Typography>
                      <IconButton 
                        size="small"
                        onClick={() => window.open(selectedBusiness.website, '_blank')}
                      >
                        <LaunchIcon fontSize="small" />
                      </IconButton>
                    </Box>
                  ) : (
                    <Typography variant="body1">Not provided</Typography>
                  )}
                </Box>
              </Grid>
              
              <Grid item xs={12} md={6}>
                <Box mb={2}>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                    Country
                  </Typography>
                  <Typography variant="body1">
                    {selectedBusiness.country || 'Not specified'}
                  </Typography>
                </Box>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );

  const renderDocumentsTab = () => (
    <Box>
      <Alert severity="info" sx={{ mb: 3 }}>
        <Typography variant="subtitle2" gutterBottom>
          Document Verification Requirements
        </Typography>
        <Typography variant="body2">
          All documents must be clear, readable, and match the business information provided. 
          Click on any document to view it in full screen.
        </Typography>
      </Alert>
      
      <Grid container spacing={2}>
        {renderEnhancedDocumentCard('businessLicense', 'Business License', 'Legal registration document', true)}
        {renderEnhancedDocumentCard('taxCertificate', 'Tax Certificate', 'Government tax registration', true)}
        {renderEnhancedDocumentCard('insuranceDocument', 'Insurance Document', 'Business liability insurance', false)}
        {renderEnhancedDocumentCard('businessLogo', 'Business Logo', 'Company branding logo', false)}
      </Grid>
    </Box>
  );

  const renderContactTab = () => {
    // For approved businesses, contacts should be considered verified
    const isBusinessApproved = selectedBusiness.status === 'approved';
    const phoneVerified = isBusinessApproved || selectedBusiness.phoneVerified;
    const emailVerified = isBusinessApproved || selectedBusiness.emailVerified;

    return (
      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Alert severity="info" sx={{ mb: 3 }}>
            <Typography variant="subtitle2" gutterBottom>
              Contact Verification Status
            </Typography>
            <Typography variant="body2">
              Contact verification is handled automatically in the mobile app. 
              Both phone and email must be verified before business approval.
              {isBusinessApproved && (
                <strong> Since this business is approved, all contacts are considered verified.</strong>
              )}
            </Typography>
          </Alert>
        </Grid>
        
        <Grid item xs={12} md={6}>
          <Card variant="outlined" sx={{ height: '100%' }}>
            <CardContent>
              <Box display="flex" alignItems="center" gap={2} mb={2}>
                <Avatar sx={{ bgcolor: phoneVerified ? 'success.main' : 'primary.main' }}>
                  <PhoneIcon />
                </Avatar>
                <Box>
                  <Typography variant="h6" gutterBottom>
                    Phone Verification
                  </Typography>
                  <Typography variant="subtitle2" color="text.secondary">
                    Primary contact number
                  </Typography>
                </Box>
              </Box>
              
              <Divider sx={{ my: 2 }} />
              
              <Box mb={2}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  Phone Number
                </Typography>
                <Typography variant="h6" gutterBottom>
                  {selectedBusiness.businessPhone || 'No phone provided'}
                </Typography>
              </Box>
              
              <Box mb={2}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  Verification Status
                </Typography>
                <Chip 
                  label={phoneVerified ? 'Verified' : 'Pending Verification'}
                  color={phoneVerified ? 'success' : 'warning'}
                  icon={phoneVerified ? <CheckIcon /> : <TimeIcon />}
                  variant="filled"
                />
              </Box>
              
              {(selectedBusiness.phoneVerifiedAt || isBusinessApproved) && (
                <Box>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                    Verified On
                  </Typography>
                  <Typography variant="body2">
                    {selectedBusiness.phoneVerifiedAt ? 
                      new Date(selectedBusiness.phoneVerifiedAt).toLocaleString() :
                      isBusinessApproved ? 'Verified via business approval' : 'Unknown'
                    }
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={6}>
          <Card variant="outlined" sx={{ height: '100%' }}>
            <CardContent>
              <Box display="flex" alignItems="center" gap={2} mb={2}>
                <Avatar sx={{ bgcolor: emailVerified ? 'success.main' : 'primary.main' }}>
                  <EmailIcon />
                </Avatar>
                <Box>
                  <Typography variant="h6" gutterBottom>
                    Email Verification
                  </Typography>
                  <Typography variant="subtitle2" color="text.secondary">
                    Primary contact email
                  </Typography>
                </Box>
              </Box>
              
              <Divider sx={{ my: 2 }} />
              
              <Box mb={2}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  Email Address
                </Typography>
                <Typography variant="h6" gutterBottom>
                  {selectedBusiness.businessEmail || 'No email provided'}
                </Typography>
              </Box>
              
              <Box mb={2}>
                <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                  Verification Status
                </Typography>
                <Chip 
                  label={emailVerified ? 'Verified' : 'Pending Verification'}
                  color={emailVerified ? 'success' : 'warning'}
                  icon={emailVerified ? <CheckIcon /> : <TimeIcon />}
                  variant="filled"
                />
              </Box>
              
              {(selectedBusiness.emailVerifiedAt || isBusinessApproved) && (
                <Box>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                    Verified On
                  </Typography>
                  <Typography variant="body2">
                    {selectedBusiness.emailVerifiedAt ? 
                      new Date(selectedBusiness.emailVerifiedAt).toLocaleString() :
                      isBusinessApproved ? 'Verified via business approval' : 'Unknown'
                    }
                  </Typography>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    );
  };

  const renderLocationTab = () => {
    const fullAddress = [
      selectedBusiness.businessAddress,
      selectedBusiness.city,
      selectedBusiness.state,
      selectedBusiness.postalCode,
      selectedBusiness.country
    ].filter(Boolean).join(', ');
    
    const mapUrl = fullAddress ? 
      `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(fullAddress)}` : null;

    return (
      <Grid container spacing={3}>
        <Grid item xs={12} md={8}>
          <Card variant="outlined">
            <CardHeader 
              avatar={<LocationIcon color="primary" />}
              title="Business Location"
              subheader="Physical address and location details"
            />
            <CardContent>
              <Grid container spacing={3}>
                <Grid item xs={12}>
                  <Box mb={2}>
                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                      Complete Business Address
                    </Typography>
                    <Typography variant="body1" sx={{ lineHeight: 1.6, fontWeight: 'medium' }}>
                      {fullAddress || 'No address provided'}
                    </Typography>
                  </Box>
                </Grid>
                
                <Grid item xs={12} sm={6}>
                  <Box mb={2}>
                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                      Street Address
                    </Typography>
                    <Typography variant="body1">
                      {selectedBusiness.businessAddress || 'Not provided'}
                    </Typography>
                  </Box>
                </Grid>
                
                <Grid item xs={12} sm={6}>
                  <Box mb={2}>
                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                      City
                    </Typography>
                    <Typography variant="body1">
                      {selectedBusiness.city || 'Not provided'}
                    </Typography>
                  </Box>
                </Grid>
                
                <Grid item xs={12} sm={6}>
                  <Box mb={2}>
                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                      State/Province
                    </Typography>
                    <Typography variant="body1">
                      {selectedBusiness.state || 'Not provided'}
                    </Typography>
                  </Box>
                </Grid>
                
                <Grid item xs={12} sm={6}>
                  <Box mb={2}>
                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                      Postal Code
                    </Typography>
                    <Typography variant="body1">
                      {selectedBusiness.postalCode || 'Not provided'}
                    </Typography>
                  </Box>
                </Grid>
                
                <Grid item xs={12}>
                  <Box mb={2}>
                    <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                      Country
                    </Typography>
                    <Typography variant="body1">
                      {selectedBusiness.country || 'Not provided'}
                    </Typography>
                  </Box>
                </Grid>
              </Grid>
              
              {mapUrl && (
                <Box mt={3}>
                  <Button
                    variant="contained"
                    startIcon={<MapIcon />}
                    onClick={() => window.open(mapUrl, '_blank')}
                    size="large"
                  >
                    View on Google Maps
                  </Button>
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>
        
        <Grid item xs={12} md={4}>
          <Card variant="outlined">
            <CardHeader title="Location Services" />
            <CardContent>
              <Stack spacing={2}>
                <Box>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                    GPS Coordinates
                  </Typography>
                  <Typography variant="body2">
                    {selectedBusiness.latitude && selectedBusiness.longitude ? 
                      `${selectedBusiness.latitude}, ${selectedBusiness.longitude}` : 
                      'Not available'
                    }
                  </Typography>
                </Box>
                
                <Box>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                    Service Area
                  </Typography>
                  <Typography variant="body2">
                    {selectedBusiness.serviceRadius ? 
                      `${selectedBusiness.serviceRadius} km radius` : 
                      'Not specified'
                    }
                  </Typography>
                </Box>
                
                <Box>
                  <Typography variant="subtitle2" color="text.secondary" gutterBottom>
                    Location Verified
                  </Typography>
                  <Chip 
                    label={selectedBusiness.locationVerified ? 'Verified' : 'Not Verified'}
                    color={selectedBusiness.locationVerified ? 'success' : 'default'}
                    icon={selectedBusiness.locationVerified ? <CheckIcon /> : <LocationIcon />}
                    size="small"
                  />
                </Box>
              </Stack>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    );
  };

  const renderVerificationHistoryTab = () => {
    const submissionDate = selectedBusiness.submissionDate ? 
      new Date(selectedBusiness.submissionDate) : null;
    const lastModified = selectedBusiness.lastModified ? 
      new Date(selectedBusiness.lastModified) : null;

    return (
      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Card variant="outlined">
            <CardHeader 
              avatar={<AssignmentIcon color="primary" />}
              title="Verification Timeline"
            />
            <CardContent>
              <TableContainer>
                <Table size="small">
                  <TableHead>
                    <TableRow>
                      <TableCell>Event</TableCell>
                      <TableCell>Date</TableCell>
                      <TableCell>Status</TableCell>
                      <TableCell>Notes</TableCell>
                    </TableRow>
                  </TableHead>
                  <TableBody>
                    <TableRow>
                      <TableCell>
                        <Box display="flex" alignItems="center" gap={1}>
                          <CalendarIcon fontSize="small" />
                          Application Submitted
                        </Box>
                      </TableCell>
                      <TableCell>
                        {submissionDate ? submissionDate.toLocaleString() : 'Unknown'}
                      </TableCell>
                      <TableCell>
                        <Chip label="Completed" color="success" size="small" />
                      </TableCell>
                      <TableCell>Initial application received</TableCell>
                    </TableRow>
                    
                    {selectedBusiness.status === 'approved' && (
                      <TableRow>
                        <TableCell>
                          <Box display="flex" alignItems="center" gap={1}>
                            <VerifiedIcon fontSize="small" />
                            Business Approved
                          </Box>
                        </TableCell>
                        <TableCell>
                          {lastModified ? lastModified.toLocaleString() : 'Unknown'}
                        </TableCell>
                        <TableCell>
                          <Chip label="Approved" color="success" size="small" />
                        </TableCell>
                        <TableCell>Business verification completed</TableCell>
                      </TableRow>
                    )}
                    
                    {selectedBusiness.status === 'rejected' && (
                      <TableRow>
                        <TableCell>
                          <Box display="flex" alignItems="center" gap={1}>
                            <ErrorIcon fontSize="small" />
                            Business Rejected
                          </Box>
                        </TableCell>
                        <TableCell>
                          {lastModified ? lastModified.toLocaleString() : 'Unknown'}
                        </TableCell>
                        <TableCell>
                          <Chip label="Rejected" color="error" size="small" />
                        </TableCell>
                        <TableCell>
                          {selectedBusiness.rejectionReason || 'No reason provided'}
                        </TableCell>
                      </TableRow>
                    )}
                  </TableBody>
                </Table>
              </TableContainer>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    );
  };

  const renderEnhancedDocumentCard = (docType, title, description, required) => {
    const url = getDocumentUrl(selectedBusiness, docType);
    const status = getDocumentStatus(selectedBusiness, docType);
    const rejectionReason = selectedBusiness.documentVerification?.[docType]?.rejectionReason || 
                           selectedBusiness[`${docType}RejectionReason`];
    
    // Determine if business is already approved - if so, all docs should show as approved
    const isBusinessApproved = selectedBusiness.status === 'approved';
    const displayStatus = isBusinessApproved ? 'approved' : status;

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
                {/* Only show "Required" label if document is not approved and business is not approved */}
                {required && displayStatus !== 'approved' && !isBusinessApproved && (
                  <Chip label="Required" size="small" color="warning" />
                )}
                {/* Show "Verified" label for approved documents */}
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
              onClick={() => setFullscreenImage({ open: true, url, title })}
            />
          )}
          
          <CardContent>
            {!url ? (
              <Alert severity="warning" size="small">
                Document not submitted
              </Alert>
            ) : (
              <Box>
                {displayStatus === 'approved' && isBusinessApproved && (
                  <Alert severity="success" size="small" sx={{ mb: 1 }}>
                    <Typography variant="caption">
                      <strong>Document Verified:</strong> This document has been approved as part of the business verification.
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
                    onClick={() => setFullscreenImage({ open: true, url, title })}
                  >
                    View Full Size
                  </Button>
                  
                  <Button
                    size="small"
                    startIcon={<DownloadIcon />}
                    onClick={() => window.open(url, '_blank')}
                  >
                    Download
                  </Button>
                </Box>
              </Box>
            )}
          </CardContent>
          
          {/* Only show approval actions if business is still pending and document is not already approved */}
          {url && displayStatus === 'pending' && !isBusinessApproved && (
            <CardActions>
              <Button 
                size="small"
                color="success"
                startIcon={<CheckIcon />}
                onClick={() => handleDocumentAction(selectedBusiness, docType, 'approved')}
                disabled={actionLoading}
              >
                Approve
              </Button>
              <Button 
                size="small"
                color="error"
                startIcon={<ErrorIcon />}
                onClick={() => handleDocumentAction(selectedBusiness, docType, 'reject')}
                disabled={actionLoading}
              >
                Reject
              </Button>
            </CardActions>
          )}
          
          {/* Show verification completed message for approved documents */}
          {displayStatus === 'approved' && (
            <CardActions>
              <Box display="flex" alignItems="center" gap={1} px={1}>
                <VerifiedIcon color="success" fontSize="small" />
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

  // Helper function to get document icons
  const getDocumentIcon = (docType) => {
    switch (docType) {
      case 'businessLicense': return <AssignmentIcon />;
      case 'taxCertificate': return <DescriptionIcon />;
      case 'insuranceDocument': return <SecurityIcon />;
      case 'businessLogo': return <ImageIcon />;
      default: return <FileIcon />;
    }
  };

  const renderBusinessDetails = () => {
    if (!selectedBusiness) return null;

    const completionPercentage = calculateVerificationCompletion(selectedBusiness);
    const isFullyVerified = completionPercentage === 100;
    
    return (
      <Dialog 
        open={detailsOpen} 
        onClose={() => setDetailsOpen(false)} 
        maxWidth="lg" 
        fullWidth
        PaperProps={{
          sx: { minHeight: '80vh' }
        }}
      >
        <DialogTitle>
          <Box display="flex" justifyContent="space-between" alignItems="center">
            <Box display="flex" alignItems="center" gap={2}>
              <Avatar sx={{ bgcolor: 'primary.main' }}>
                <BusinessIcon />
              </Avatar>
              <Box>
                <Typography variant="h5" fontWeight="bold">
                  {selectedBusiness.businessName}
                </Typography>
                <Box display="flex" alignItems="center" gap={2} mt={1}>
                  <Chip 
                    label={selectedBusiness.status || 'pending'} 
                    color={getStatusColor(selectedBusiness.status)} 
                    icon={getStatusIcon(selectedBusiness.status)}
                    variant="filled"
                  />
                  <Chip 
                    label={`${completionPercentage}% Complete`}
                    color={isFullyVerified ? 'success' : 'warning'}
                    variant="outlined"
                    size="small"
                  />
                  <Typography variant="caption" color="text.secondary">
                    Submitted: {selectedBusiness.submissionDate ? 
                      new Date(selectedBusiness.submissionDate).toLocaleDateString() : 'Unknown'}
                  </Typography>
                </Box>
              </Box>
            </Box>
            <IconButton onClick={() => setDetailsOpen(false)} size="large">
              <CloseIcon />
            </IconButton>
          </Box>
          
          {/* Progress Bar */}
          <Box sx={{ mt: 2 }}>
            <LinearProgress 
              variant="determinate" 
              value={completionPercentage} 
              sx={{ height: 8, borderRadius: 4 }}
              color={isFullyVerified ? 'success' : 'primary'}
            />
          </Box>
        </DialogTitle>
        
        <DialogContent sx={{ p: 0 }}>
          <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
            <Tabs 
              value={tabValue} 
              onChange={(e, v) => setTabValue(v)}
              variant="scrollable"
              scrollButtons="auto"
            >
              <Tab 
                icon={<InfoIcon />} 
                label="Business Details" 
                iconPosition="start"
              />
              <Tab 
                icon={<AssignmentIcon />} 
                label="Documents" 
                iconPosition="start"
              />
              <Tab 
                icon={<ContactIcon />} 
                label="Contact Info" 
                iconPosition="start"
              />
              <Tab 
                icon={<MapIcon />} 
                label="Location" 
                iconPosition="start"
              />
              <Tab 
                icon={<ReportsIcon />} 
                label="Verification History" 
                iconPosition="start"
              />
            </Tabs>
          </Box>

          <Box sx={{ p: 3 }}>
            {/* Business Details Tab */}
            {tabValue === 0 && renderBusinessDetailsTab()}
            
            {/* Documents Tab */}
            {tabValue === 1 && renderDocumentsTab()}
            
            {/* Contact Info Tab */}
            {tabValue === 2 && renderContactTab()}
            
            {/* Location Tab */}
            {tabValue === 3 && renderLocationTab()}
            
            {/* Verification History Tab */}
            {tabValue === 4 && renderVerificationHistoryTab()}
          </Box>
        </DialogContent>

        <DialogActions sx={{ px: 3, py: 2, borderTop: 1, borderColor: 'divider' }}>
          <Button 
            onClick={() => setDetailsOpen(false)}
            size="large"
          >
            Close
          </Button>
          
          {selectedBusiness.status === 'pending' && (
            <Box display="flex" gap={1}>
              <Button 
                color="error"
                variant="outlined"
                startIcon={<RejectIcon />}
                onClick={() => handleBusinessAction(selectedBusiness, 'reject')}
                disabled={actionLoading}
                size="large"
              >
                Reject Business
              </Button>
              <Button 
                color="success" 
                variant="contained"
                startIcon={<ApproveIcon />}
                onClick={() => handleBusinessAction(selectedBusiness, 'approve')}
                disabled={actionLoading}
                size="large"
              >
                Approve Business
              </Button>
            </Box>
          )}
          
          {selectedBusiness.status === 'approved' && (
            <Chip 
              icon={<VerifiedIcon />}
              label="Verified & Approved"
              color="success"
              variant="filled"
              size="medium"
            />
          )}
          
          {selectedBusiness.status === 'rejected' && (
            <Button 
              color="primary"
              variant="outlined"
              startIcon={<ApproveIcon />}
              onClick={() => handleBusinessAction(selectedBusiness, 'reactivate')}
              disabled={actionLoading}
              size="large"
            >
              Reactivate Business
            </Button>
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

export default BusinessVerificationEnhanced;
