// Enhanced admin driver verification modal
function showDriverVerificationModal(driverId) {
    const modal = document.createElement('div');
    modal.innerHTML = `
        <div class="modal fade" id="driverVerificationModal" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-xl">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fas fa-user-check me-2"></i>
                            Driver Verification Center
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div id="verificationContent" class="container-fluid">
                            <div class="text-center">
                                <div class="spinner-border text-primary" role="status">
                                    <span class="visually-hidden">Loading...</span>
                                </div>
                                <p class="mt-2">Loading driver details...</p>
                            </div>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                        <button type="button" id="approveDriverBtn" class="btn btn-success" style="display:none;">
                            <i class="fas fa-check me-2"></i>Approve Driver
                        </button>
                        <button type="button" id="rejectDriverBtn" class="btn btn-danger" style="display:none;">
                            <i class="fas fa-times me-2"></i>Reject Driver
                        </button>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    
    const bootstrapModal = new bootstrap.Modal(document.getElementById('driverVerificationModal'));
    bootstrapModal.show();
    
    // Load driver verification data
    loadDriverVerificationData(driverId);
    
    // Clean up modal when closed
    document.getElementById('driverVerificationModal').addEventListener('hidden.bs.modal', () => {
        document.body.removeChild(modal);
    });
}

async function loadDriverVerificationData(driverId) {
    try {
        // Load driver profile
        const driverDoc = await getDoc(doc(db, 'drivers', driverId));
        if (!driverDoc.exists()) {
            throw new Error('Driver not found');
        }
        
        const driverData = { id: driverDoc.id, ...driverDoc.data() };
        
        // Load verification documents from driver's documentVerification field
        let verificationData = {};
        console.log('Full driver data:', driverData); // Enhanced debug log
        
        if (driverData.documentVerification) {
            verificationData = driverData.documentVerification;
            console.log('Found documentVerification:', verificationData);
        } else {
            console.log('No documentVerification found, trying driver_verifications collection');
            // Fallback: try the separate driver_verifications collection
            const verificationDoc = await getDoc(doc(db, 'driver_verifications', driverData.userId || driverId));
            verificationData = verificationDoc.exists() ? verificationDoc.data() : {};
            console.log('Fallback verification data:', verificationData);
        }
        
        // Also check if documents might be stored directly in driver data
        console.log('Checking for direct document storage...');
        ['driverPhoto', 'license', 'nationalId', 'vehicleRegistration', 'insurance'].forEach(docType => {
            if (driverData[docType]) {
                console.log(`Found direct ${docType}:`, driverData[docType]);
                if (!verificationData[docType]) {
                    verificationData[docType] = driverData[docType];
                }
            }
        });
        
        console.log('Final verification data:', verificationData); // Debug log
        
        renderDriverVerificationContent(driverData, verificationData);
        
    } catch (error) {
        console.error('Error loading driver verification data:', error);
        document.getElementById('verificationContent').innerHTML = `
            <div class="alert alert-danger">
                <i class="fas fa-exclamation-triangle me-2"></i>
                Error loading driver data: ${error.message}
            </div>
        `;
    }
}

function renderDriverVerificationContent(driverData, verificationData) {
    const documentTypes = [
        { key: 'driverPhoto', title: 'Driver Photo', icon: 'fas fa-user' },
        { key: 'license', title: 'Driving License', icon: 'fas fa-id-card' },
        { key: 'nationalId', title: 'National ID', icon: 'fas fa-id-badge' },
        { key: 'vehicleRegistration', title: 'Vehicle Registration', icon: 'fas fa-car' },
        { key: 'insurance', title: 'Insurance Certificate', icon: 'fas fa-shield-alt' },
        { key: 'vehiclePhotos', title: 'Vehicle Photos', icon: 'fas fa-camera' }
    ];
    
    const overallStatus = getOverallVerificationStatus(verificationData, documentTypes);
    
    const content = `
        <div class="row">
            <!-- Driver Profile Summary -->
            <div class="col-md-4">
                <div class="card h-100">
                    <div class="card-header bg-primary text-white">
                        <h6 class="mb-0">
                            <i class="fas fa-user me-2"></i>Driver Profile
                        </h6>
                    </div>
                    <div class="card-body">
                        <div class="text-center mb-3">
                            <div class="driver-avatar">
                                ${driverData.photoUrl ? 
                                    `<img src="${driverData.photoUrl}" class="rounded-circle" width="80" height="80" style="object-fit: cover;">` :
                                    `<div class="bg-primary rounded-circle d-flex align-items-center justify-content-center" style="width: 80px; height: 80px;">
                                        <i class="fas fa-user text-white fa-2x"></i>
                                    </div>`
                                }
                            </div>
                            <h6 class="mt-2 mb-1">${driverData.name || 'N/A'}</h6>
                            <small class="text-muted">${driverData.email || 'No email'}</small>
                        </div>
                        
                        <div class="verification-status mb-3">
                            <div class="d-flex justify-content-between align-items-center">
                                <span>Overall Status:</span>
                                <span class="badge bg-${getStatusColor(overallStatus)}">${overallStatus}</span>
                            </div>
                        </div>
                        
                        <hr>
                        
                        <div class="driver-details">
                            <div class="detail-row">
                                <small class="text-muted">Phone:</small>
                                <div>${driverData.phoneNumber || 'N/A'}</div>
                            </div>
                            <div class="detail-row">
                                <small class="text-muted">License Number:</small>
                                <div>${driverData.licenseNumber || 'N/A'}</div>
                            </div>
                            <div class="detail-row">
                                <small class="text-muted">Vehicle Type:</small>
                                <div>${driverData.vehicleType || 'N/A'}</div>
                            </div>
                            <div class="detail-row">
                                <small class="text-muted">Vehicle Number:</small>
                                <div>${driverData.vehicleNumber || 'N/A'}</div>
                            </div>
                            <div class="detail-row">
                                <small class="text-muted">Vehicle Model:</small>
                                <div>${driverData.vehicleModel || 'N/A'}</div>
                            </div>
                            <div class="detail-row">
                                <small class="text-muted">Registration Date:</small>
                                <div>${driverData.createdAt ? formatDate(driverData.createdAt.toDate()) : 'N/A'}</div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <!-- Document Verification -->
            <div class="col-md-8">
                <div class="card h-100">
                    <div class="card-header bg-info text-white">
                        <h6 class="mb-0">
                            <i class="fas fa-file-check me-2"></i>Document Verification
                        </h6>
                    </div>
                    <div class="card-body">
                        <div class="row">
                            ${documentTypes.map(docType => {
                                let docData = {};
                                let documentUrl = null;
                                let status = 'notSubmitted';
                                
                                if (docType.key === 'vehiclePhotos') {
                                    // Handle vehicle photos separately - they're stored as an array
                                    const vehicleImages = driverData.vehicleImageUrls || [];
                                    if (vehicleImages.length > 0) {
                                        documentUrl = vehicleImages[0]; // Show first image as preview
                                        status = vehicleImages.length >= 4 ? 'approved' : 'pending';
                                        docData = {
                                            documentUrl: documentUrl,
                                            status: status,
                                            count: vehicleImages.length,
                                            allImages: vehicleImages
                                        };
                                    }
                                } else {
                                    // Handle regular documents from documentVerification
                                    docData = verificationData[docType.key] || {};
                                    status = docData.status || 'notSubmitted';
                                    // Check multiple possible field names for document URL
                                    documentUrl = docData.documentUrl || docData.url || docData.imageUrl || docData.fileUrl;
                                }
                                
                                console.log(`Document ${docType.key}:`, docData, 'URL:', documentUrl); // Debug log
                                
                                return `
                                    <div class="col-md-6 mb-3">
                                        <div class="document-card border rounded p-3">
                                            <div class="d-flex justify-content-between align-items-start mb-2">
                                                <div class="d-flex align-items-center">
                                                    <i class="${docType.icon} me-2"></i>
                                                    <strong>${docType.title}</strong>
                                                    ${docType.key === 'vehiclePhotos' && docData.count ? `<small class="ms-2 text-muted">(${docData.count} images)</small>` : ''}
                                                </div>
                                                <span class="badge bg-${getDocumentStatusColor(status)}">${formatStatus(status)}</span>
                                            </div>
                                            
                                            ${documentUrl && documentUrl.trim() !== '' ? `
                                                <div class="document-preview mb-2">
                                                    <div class="preview-container border rounded" style="height: 100px; overflow: hidden;">
                                                        ${documentUrl.toLowerCase().includes('.pdf') ? 
                                                            `<div class="d-flex align-items-center justify-content-center h-100 bg-light">
                                                                <i class="fas fa-file-pdf fa-2x text-danger"></i>
                                                            </div>` :
                                                            `<img src="${documentUrl}" class="img-fluid w-100 h-100" style="object-fit: cover;">`
                                                        }
                                                    </div>
                                                </div>
                                                <div class="document-actions">
                                                    <button type="button" class="btn btn-sm btn-outline-primary me-1" onclick="viewDocument('${documentUrl}', '${docType.title}')">
                                                        <i class="fas fa-eye"></i> View
                                                    </button>
                                                    ${status === 'pending' ? `
                                                        <button type="button" class="btn btn-sm btn-success me-1" onclick="approveDocument('${driverData.id}', '${docType.key}')">
                                                            <i class="fas fa-check"></i> Approve
                                                        </button>
                                                        <button type="button" class="btn btn-sm btn-danger" onclick="rejectDocument('${driverData.id}', '${docType.key}')">
                                                            <i class="fas fa-times"></i> Reject
                                                        </button>
                                                    ` : status === 'approved' ? `
                                                        <button type="button" class="btn btn-sm btn-warning me-1" onclick="rejectDocument('${driverData.id}', '${docType.key}')">
                                                            <i class="fas fa-times"></i> Reject
                                                        </button>
                                                    ` : status === 'rejected' ? `
                                                        <button type="button" class="btn btn-sm btn-success me-1" onclick="approveDocument('${driverData.id}', '${docType.key}')">
                                                            <i class="fas fa-check"></i> Re-approve
                                                        </button>
                                                    ` : ''}
                                                </div>
                                            ` : `
                                                <div class="text-center text-muted py-3">
                                                    <i class="fas fa-upload fa-2x mb-2"></i>
                                                    <div>Document not submitted</div>
                                                </div>
                                            `}
                                            
                                            ${docData.rejectionReason ? `
                                                <div class="alert alert-danger alert-sm mt-2">
                                                    <small><strong>Rejection Reason:</strong> ${docData.rejectionReason}</small>
                                                </div>
                                            ` : ''}
                                            
                                            ${docData.submittedAt ? `
                                                <div class="text-muted small mt-2">
                                                    Submitted: ${formatDate(docData.submittedAt.toDate())}
                                                </div>
                                            ` : ''}
                                            
                                            ${docData.reviewedAt ? `
                                                <div class="text-muted small">
                                                    Reviewed: ${formatDate(docData.reviewedAt.toDate())}
                                                </div>
                                            ` : ''}
                                        </div>
                                    </div>
                                `;
                            }).join('')}
                        </div>
                        
                        <hr>
                        
                        <!-- Verification Summary -->
                        <div class="verification-summary">
                            <h6>Verification Summary</h6>
                            <div class="row">
                                <div class="col-md-3 text-center">
                                    <div class="stat-item">
                                        <h4 class="text-success">${getDocumentCount(verificationData, 'approved')}</h4>
                                        <small>Approved</small>
                                    </div>
                                </div>
                                <div class="col-md-3 text-center">
                                    <div class="stat-item">
                                        <h4 class="text-warning">${getDocumentCount(verificationData, 'pending')}</h4>
                                        <small>Pending</small>
                                    </div>
                                </div>
                                <div class="col-md-3 text-center">
                                    <div class="stat-item">
                                        <h4 class="text-danger">${getDocumentCount(verificationData, 'rejected')}</h4>
                                        <small>Rejected</small>
                                    </div>
                                </div>
                                <div class="col-md-3 text-center">
                                    <div class="stat-item">
                                        <h4 class="text-muted">${getDocumentCount(verificationData, 'notSubmitted')}</h4>
                                        <small>Not Submitted</small>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        
        <style>
            .detail-row {
                margin-bottom: 8px;
            }
            .detail-row small {
                font-size: 0.8rem;
            }
            .document-card {
                background: #f8f9fa;
            }
            .document-card:hover {
                background: #e9ecef;
            }
            .preview-container {
                cursor: pointer;
            }
            .stat-item h4 {
                margin-bottom: 0;
                font-weight: bold;
            }
            .alert-sm {
                padding: 0.5rem;
                font-size: 0.875rem;
            }
        </style>
    `;
    
    document.getElementById('verificationContent').innerHTML = content;
    
    // Show appropriate action buttons
    const approveBtn = document.getElementById('approveDriverBtn');
    const rejectBtn = document.getElementById('rejectDriverBtn');
    
    if (overallStatus === 'Approved') {
        approveBtn.style.display = 'none';
        rejectBtn.style.display = 'none';
    } else if (overallStatus === 'Pending Review') {
        approveBtn.style.display = 'inline-block';
        rejectBtn.style.display = 'inline-block';
        
        approveBtn.onclick = () => approveDriver(driverData.id);
        rejectBtn.onclick = () => rejectDriver(driverData.id);
    }
}

// Helper functions
function getOverallVerificationStatus(verificationData, documentTypes) {
    const statuses = documentTypes.map(docType => {
        const docData = verificationData[docType.key] || {};
        return docData.status || 'notSubmitted';
    });
    
    if (statuses.every(status => status === 'approved')) {
        return 'Approved';
    } else if (statuses.some(status => status === 'rejected')) {
        return 'Rejected';
    } else if (statuses.some(status => status === 'pending')) {
        return 'Pending Review';
    } else {
        return 'Not Submitted';
    }
}

function getStatusColor(status) {
    switch (status) {
        case 'Approved': return 'success';
        case 'Rejected': return 'danger';
        case 'Pending Review': return 'warning';
        default: return 'secondary';
    }
}

function getDocumentStatusColor(status) {
    switch (status) {
        case 'approved': return 'success';
        case 'rejected': return 'danger';
        case 'pending': return 'warning';
        default: return 'secondary';
    }
}

function formatStatus(status) {
    switch (status) {
        case 'approved': return 'Approved';
        case 'rejected': return 'Rejected';
        case 'pending': return 'Pending';
        case 'notSubmitted': return 'Not Submitted';
        default: return 'Unknown';
    }
}

function getDocumentCount(verificationData, status) {
    const documentTypes = ['driverPhoto', 'license', 'nationalId', 'vehicleRegistration', 'insuranceCertificate', 'vehiclePhotos'];
    return documentTypes.filter(docType => {
        const docData = verificationData[docType] || {};
        const docStatus = docData.status || 'notSubmitted';
        return docStatus === status;
    }).length;
}

function formatDate(date) {
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
}

function viewDocument(documentUrl, title) {
    const modal = document.createElement('div');
    modal.innerHTML = `
        <div class="modal fade" id="documentViewModal" tabindex="-1" aria-hidden="true">
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">${title}</h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body text-center">
                        ${documentUrl.toLowerCase().includes('.pdf') ? 
                            `<embed src="${documentUrl}" type="application/pdf" width="100%" height="500px">` :
                            `<img src="${documentUrl}" class="img-fluid" style="max-height: 500px;">`
                        }
                    </div>
                    <div class="modal-footer">
                        <a href="${documentUrl}" target="_blank" class="btn btn-primary">
                            <i class="fas fa-external-link-alt me-2"></i>Open in New Tab
                        </a>
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    const bootstrapModal = new bootstrap.Modal(document.getElementById('documentViewModal'));
    bootstrapModal.show();
    
    document.getElementById('documentViewModal').addEventListener('hidden.bs.modal', () => {
        document.body.removeChild(modal);
    });
}

async function approveDocument(driverId, documentType) {
    try {
        const driverDoc = await getDoc(doc(db, 'drivers', driverId));
        const driverData = driverDoc.data();
        const userId = driverData.userId || driverId;
        
        await updateDoc(doc(db, 'driver_verifications', userId), {
            [`${documentType}.status`]: 'approved',
            [`${documentType}.reviewedAt`]: Timestamp.now(),
            [`${documentType}.rejectionReason`]: null
        });
        
        showSuccess(`${documentType} document approved successfully!`);
        loadDriverVerificationData(driverId); // Reload the modal content
        
    } catch (error) {
        console.error('Error approving document:', error);
        showError('Error approving document: ' + error.message);
    }
}

async function rejectDocument(driverId, documentType) {
    const reason = prompt('Please provide a reason for rejection:');
    if (!reason) return;
    
    try {
        const driverDoc = await getDoc(doc(db, 'drivers', driverId));
        const driverData = driverDoc.data();
        const userId = driverData.userId || driverId;
        
        await updateDoc(doc(db, 'driver_verifications', userId), {
            [`${documentType}.status`]: 'rejected',
            [`${documentType}.reviewedAt`]: Timestamp.now(),
            [`${documentType}.rejectionReason`]: reason
        });
        
        showSuccess(`${documentType} document rejected.`);
        loadDriverVerificationData(driverId); // Reload the modal content
        
    } catch (error) {
        console.error('Error rejecting document:', error);
        showError('Error rejecting document: ' + error.message);
    }
}

async function approveDriver(driverId) {
    const confirmed = confirm('Are you sure you want to approve this driver? This will activate their account.');
    if (!confirmed) return;
    
    try {
        await updateDoc(doc(db, 'drivers', driverId), {
            status: 'approved',
            isVerified: true,
            isActive: true,
            approvedAt: Timestamp.now(),
            updatedAt: Timestamp.now()
        });
        
        showSuccess('Driver approved successfully!');
        bootstrap.Modal.getInstance(document.getElementById('driverVerificationModal')).hide();
        loadDrivers(); // Refresh the drivers table
        
    } catch (error) {
        console.error('Error approving driver:', error);
        showError('Error approving driver: ' + error.message);
    }
}

async function rejectDriver(driverId) {
    const reason = prompt('Please provide a reason for rejecting this driver:');
    if (!reason) return;
    
    try {
        await updateDoc(doc(db, 'drivers', driverId), {
            status: 'rejected',
            isVerified: false,
            isActive: false,
            rejectionReason: reason,
            rejectedAt: Timestamp.now(),
            updatedAt: Timestamp.now()
        });
        
        showSuccess('Driver rejected.');
        bootstrap.Modal.getInstance(document.getElementById('driverVerificationModal')).hide();
        loadDrivers(); // Refresh the drivers table
        
    } catch (error) {
        console.error('Error rejecting driver:', error);
        showError('Error rejecting driver: ' + error.message);
    }
}
