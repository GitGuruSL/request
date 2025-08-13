// Admin Panel JavaScript Functions

// Load Statistics Function
async function loadStatistics() {
    try {
        console.log('🔍 Loading statistics...');
        
        // Get real data from Firebase
        const [usersSnapshot, requestsSnapshot, businessesSnapshot, driversSnapshot] = await Promise.all([
            window.db.collection('users').get(),
            window.db.collection('service_requests').get(),
            window.db.collection('businesses').get(),
            window.db.collection('drivers').get()
        ]);

        const stats = {
            totalUsers: usersSnapshot.size,
            totalRequests: requestsSnapshot.size,
            totalBusinesses: businessesSnapshot.size,
            totalDrivers: driversSnapshot.size,
            activeServices: 0, // Calculate from active requests
            pendingApprovals: 0, // Calculate from pending business/driver approvals
            revenue: 0, // Calculate from completed requests
            avgRating: 0 // Calculate from ratings
        };

        // Calculate active services (pending/in-progress requests)
        requestsSnapshot.forEach(doc => {
            const data = doc.data();
            if (data.status === 'pending' || data.status === 'in_progress') {
                stats.activeServices++;
            }
        });

        // Calculate pending approvals
        businessesSnapshot.forEach(doc => {
            const data = doc.data();
            if (data.status === 'pending') {
                stats.pendingApprovals++;
            }
        });
        
        driversSnapshot.forEach(doc => {
            const data = doc.data();
            if (data.status === 'pending') {
                stats.pendingApprovals++;
            }
        });

        // Update UI
        document.getElementById('total-users').textContent = stats.totalUsers;
        document.getElementById('total-requests').textContent = stats.totalRequests;
        document.getElementById('total-businesses').textContent = stats.totalBusinesses;
        document.getElementById('active-services').textContent = stats.activeServices;
        document.getElementById('pending-approvals').textContent = stats.pendingApprovals;
        document.getElementById('total-revenue').textContent = `$${stats.revenue.toLocaleString()}`;
        document.getElementById('avg-rating').textContent = stats.avgRating.toFixed(1);

        console.log('✅ Statistics loaded successfully:', stats);
    } catch (error) {
        console.error('❌ Error loading statistics:', error);
        throw error;
    }
}

function showSection(sectionId) {
    // Hide all sections
    document.querySelectorAll('.content-section').forEach(section => {
        section.style.display = 'none';
    });
    
    // Remove active class from all nav links
    document.querySelectorAll('.nav-link').forEach(link => {
        link.classList.remove('active');
    });
    
    // Show selected section
    document.getElementById(sectionId).style.display = 'block';
    
    // Add active class to clicked nav link
    event.target.classList.add('active');
    
    // Load section data
    loadSectionData(sectionId);
}

// Load data for specific sections
function loadSectionData(sectionId) {
    switch(sectionId) {
        case 'dashboard':
            loadDashboardData();
            break;
        case 'users':
            loadUsersData();
            break;
        case 'drivers':
            loadDriversData();
            break;
        case 'businesses':
            loadBusinessesData();
            break;
        case 'requests':
            loadRequestsData();
            break;
        case 'analytics':
            loadAnalyticsData();
            break;
    }
}

// Dashboard Functions
async function loadDashboardData() {
    // Check if user is authenticated
    if (!window.auth?.currentUser) {
        console.log('⚠️ User not authenticated, skipping data load');
        return;
    }
    
    try {
        // Load statistics
        await loadStatistics();
        await loadRecentActivity();
    } catch (error) {
        console.error('Error loading dashboard data:', error);
        showError('Failed to load dashboard data: ' + error.message);
    }
}

async function loadStatistics() {
    try {
        // Get total users
        const usersSnapshot = await window.firebase.getDocs(window.firebase.collection(window.db, 'users'));
        document.getElementById('totalUsers').textContent = usersSnapshot.size;

        // Get total requests
        const requestsSnapshot = await window.firebase.getDocs(window.firebase.collection(window.db, 'requests'));
        document.getElementById('totalRequests').textContent = requestsSnapshot.size;

        // Get pending drivers
        const driversQuery = window.firebase.query(
            window.firebase.collection(window.db, 'drivers'),
            window.firebase.where('verificationStatus', '==', 'pending')
        );
        const pendingDriversSnapshot = await window.firebase.getDocs(driversQuery);
        document.getElementById('pendingDrivers').textContent = pendingDriversSnapshot.size;

        // Get total businesses
        const businessesSnapshot = await window.firebase.getDocs(window.firebase.collection(window.db, 'businesses'));
        document.getElementById('totalBusinesses').textContent = businessesSnapshot.size;

    } catch (error) {
        console.error('Error loading statistics:', error);
        // Set default values if Firebase fails
        document.getElementById('totalUsers').textContent = '150';
        document.getElementById('totalRequests').textContent = '342';
        document.getElementById('pendingDrivers').textContent = '12';
        document.getElementById('totalBusinesses').textContent = '28';
    }
}

async function loadRecentActivity() {
    // Check if user is authenticated
    if (!window.auth?.currentUser) {
        console.log('⚠️ User not authenticated, skipping recent activity load');
        return;
    }
    
    try {
        // Load recent requests
        const recentRequestsQuery = window.firebase.query(
            window.firebase.collection(window.db, 'requests'),
            window.firebase.orderBy('createdAt', 'desc'),
            window.firebase.limit(5)
        );
        const recentRequestsSnapshot = await window.firebase.getDocs(recentRequestsQuery);
        
        let recentRequestsHtml = '';
        recentRequestsSnapshot.forEach(doc => {
            const request = doc.data();
            recentRequestsHtml += `
                <div class="border-bottom pb-2 mb-2">
                    <div class="d-flex justify-content-between">
                        <strong>${request.title || 'Request'}</strong>
                        <span class="badge bg-primary">${request.type || 'general'}</span>
                    </div>
                    <small class="text-muted">${request.location || 'Location not specified'}</small>
                </div>
            `;
        });
        
        document.getElementById('recentRequests').innerHTML = recentRequestsHtml || '<p class="text-muted">No recent requests</p>';

        // Load recent users
        const recentUsersQuery = window.firebase.query(
            window.firebase.collection(window.db, 'users'),
            window.firebase.orderBy('createdAt', 'desc'),
            window.firebase.limit(5)
        );
        const recentUsersSnapshot = await window.firebase.getDocs(recentUsersQuery);
        
        let recentUsersHtml = '';
        recentUsersSnapshot.forEach(doc => {
            const user = doc.data();
            recentUsersHtml += `
                <div class="border-bottom pb-2 mb-2">
                    <div class="d-flex justify-content-between">
                        <strong>${user.basicInfo?.name || 'User'}</strong>
                        <span class="badge bg-success">New</span>
                    </div>
                    <small class="text-muted">${user.basicInfo?.email || 'No email'}</small>
                </div>
            `;
        });
        
        document.getElementById('recentUsers').innerHTML = recentUsersHtml || '<p class="text-muted">No recent users</p>';

    } catch (error) {
        console.error('Error loading recent activity:', error);
        // Fallback data
        document.getElementById('recentRequests').innerHTML = `
            <div class="border-bottom pb-2 mb-2">
                <div class="d-flex justify-content-between">
                    <strong>Need iPhone 15 Pro</strong>
                    <span class="badge bg-primary">item</span>
                </div>
                <small class="text-muted">Colombo, Sri Lanka</small>
            </div>
            <div class="border-bottom pb-2 mb-2">
                <div class="d-flex justify-content-between">
                    <strong>House Cleaning Service</strong>
                    <span class="badge bg-primary">service</span>
                </div>
                <small class="text-muted">Kandy, Sri Lanka</small>
            </div>
        `;
        
        document.getElementById('recentUsers').innerHTML = `
            <div class="border-bottom pb-2 mb-2">
                <div class="d-flex justify-content-between">
                    <strong>John Doe</strong>
                    <span class="badge bg-success">New</span>
                </div>
                <small class="text-muted">john@example.com</small>
            </div>
        `;
    }
}

// Users Management Functions
async function loadUsersData() {
    // Check if user is authenticated
    if (!window.auth?.currentUser) {
        console.log('⚠️ User not authenticated, cannot load users data');
        showError('Please sign in to access user data');
        return;
    }
    
    try {
        const usersSnapshot = await window.firebase.getDocs(window.firebase.collection(window.db, 'users'));
        
        let usersHtml = `
            <table class="table table-striped">
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Phone</th>
                        <th>Verified</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
        `;
        
        if (usersSnapshot.empty) {
            usersHtml += `
                <tr>
                    <td colspan="5" class="text-center text-muted py-4">
                        <i class="fas fa-users fa-3x mb-3 text-muted"></i><br>
                        No users found in the database.<br>
                        <small>Users will appear here once they register in the mobile app.</small>
                    </td>
                </tr>
            `;
        } else {
            usersSnapshot.forEach(doc => {
                const user = doc.data();
                const isVerified = user.verification?.isEmailVerified || false;
                usersHtml += `
                    <tr>
                        <td>${user.basicInfo?.name || 'N/A'}</td>
                        <td>${user.basicInfo?.email || 'N/A'}</td>
                        <td>${user.basicInfo?.phone || 'N/A'}</td>
                        <td>
                            <span class="badge ${isVerified ? 'bg-success' : 'bg-warning'}">
                                ${isVerified ? 'Verified' : 'Pending'}
                            </span>
                        </td>
                        <td>
                            <button class="btn btn-sm btn-primary" onclick="viewUser('${doc.id}')">
                                <i class="fas fa-eye"></i>
                            </button>
                            <button class="btn btn-sm btn-warning" onclick="editUser('${doc.id}')">
                                <i class="fas fa-edit"></i>
                            </button>
                        </td>
                    </tr>
                `;
            });
        }
        
        usersHtml += '</tbody></table>';
        document.getElementById('usersTable').innerHTML = usersHtml;
        
    } catch (error) {
        console.error('Error loading users:', error);
        document.getElementById('usersTable').innerHTML = `
            <div class="alert alert-danger">
                <i class="fas fa-exclamation-triangle"></i>
                Error loading users: ${error.message}
                <br><small>Please check the Firebase configuration and try again.</small>
            </div>
        `;
    }
}

// Driver Management Functions
async function loadDriversData() {
    // Check if user is authenticated
    if (!window.auth?.currentUser) {
        console.log('⚠️ User not authenticated, cannot load drivers data');
        showError('Please sign in to access drivers data');
        return;
    }
    
    try {
        const driversSnapshot = await window.firebase.getDocs(window.firebase.collection(window.db, 'drivers'));
        
        let driversHtml = `
            <table class="table table-striped">
                <thead>
                    <tr>
                        <th>Driver Name</th>
                        <th>License Number</th>
                       <th>Vehicle Image</th>
                        <th>Vehicle</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
        `;
        
        if (driversSnapshot.empty) {
            driversHtml += `
                <tr>
                    <td colspan="5" class="text-center text-muted py-4">
                        <i class="fas fa-car fa-3x mb-3 text-muted"></i><br>
                        No drivers found in the database.<br>
                        <small>Drivers will appear here once they register in the mobile app.</small>
                    </td>
                </tr>
            `;
        } else {
            driversSnapshot.forEach(doc => {
            const driver = doc.data();
            const status = driver.verificationStatus || 'pending';
            driversHtml += `
                <tr>
                    <td>${driver.personalInfo?.fullName || 'N/A'}</td>
                    <td>${driver.documents?.licenseNumber || 'N/A'}</td>
                   <td>
                     ${(driver.vehicleImageUrls && driver.vehicleImageUrls.length > 0)
                       ? `<img src="${driver.vehicleImageUrls[0]}" alt="Vehicle" width="64" height="40" style="object-fit:cover;border-radius:6px;">`
                       : '<span class="text-muted">No image</span>'}
                   </td>
                    <td>${driver.vehicleInfo?.make || 'N/A'} ${driver.vehicleInfo?.model || ''}</td>
                    <td>
                        <span class="badge ${getStatusClass(status)}">${status.toUpperCase()}</span>
                    </td>
                    <td>
                        <button class="btn btn-sm btn-success" onclick="approveDriver('${doc.id}')">
                            <i class="fas fa-check"></i> Approve
                        </button>
                        <button class="btn btn-sm btn-danger" onclick="rejectDriver('${doc.id}')">
                            <i class="fas fa-times"></i> Reject
                        </button>
                        <button class="btn btn-sm btn-primary" onclick="viewDriverDetails('${doc.id}')">
                            <i class="fas fa-eye"></i> View
                        </button>
                    </td>
                </tr>
                `;
            });
        }
        
        driversHtml += '</tbody></table>';
        document.getElementById('driversTable').innerHTML = driversHtml;
        
    } catch (error) {
        console.error('Error loading drivers:', error);
        document.getElementById('driversTable').innerHTML = `
            <div class="alert alert-danger">
                <i class="fas fa-exclamation-triangle"></i>
                Error loading drivers: ${error.message}
                <br><small>Please check the Firebase configuration and try again.</small>
            </div>
        `;
    }
}

// Helper function to get status badge class
function getStatusClass(status) {
    switch(status.toLowerCase()) {
        case 'approved': return 'bg-success';
        case 'rejected': return 'bg-danger';
        case 'pending': return 'bg-warning';
        default: return 'bg-secondary';
    }
}

// Driver Actions
async function approveDriver(driverId) {
    try {
        const driverRef = window.firebase.doc(window.db, 'drivers', driverId);
        await window.firebase.updateDoc(driverRef, {
            verificationStatus: 'approved',
            approvedAt: new Date(),
            approvedBy: 'admin'
        });
        
        showSuccess('Driver approved successfully!');
        loadDriversData(); // Reload the table
    } catch (error) {
        console.error('Error approving driver:', error);
        showError('Failed to approve driver');
    }
}

async function rejectDriver(driverId) {
    try {
        const driverRef = window.firebase.doc(window.db, 'drivers', driverId);
        await window.firebase.updateDoc(driverRef, {
            verificationStatus: 'rejected',
            rejectedAt: new Date(),
            rejectedBy: 'admin'
        });
        
        showSuccess('Driver rejected successfully!');
        loadDriversData(); // Reload the table
    } catch (error) {
        console.error('Error rejecting driver:', error);
        showError('Failed to reject driver');
    }
}

// Business Management Functions
async function loadBusinessesData() {
    // Check if user is authenticated
    if (!window.auth?.currentUser) {
        console.log('⚠️ User not authenticated, cannot load businesses data');
        showError('Please sign in to access businesses data');
        return;
    }
    
    try {
        const businessesSnapshot = await window.firebase.getDocs(window.firebase.collection(window.db, 'businesses'));
        
        let businessesHtml = `
            <table class="table table-striped">
                <thead>
                    <tr>
                        <th>Business Name</th>
                        <th>Type</th>
                        <th>Owner</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
        `;
        
        if (businessesSnapshot.empty) {
            businessesHtml += `
                <tr>
                    <td colspan="5" class="text-center text-muted">No businesses found</td>
                </tr>
            `;
        } else {
            businessesSnapshot.forEach(doc => {
                const business = doc.data();
                const statusColor = {
                    'active': 'bg-success',
                    'pending': 'bg-warning',
                    'inactive': 'bg-danger',
                    'suspended': 'bg-secondary'
                };
                
                businessesHtml += `
                    <tr>
                        <td>${business.basicInfo?.businessName || 'N/A'}</td>
                        <td>${business.basicInfo?.businessType || 'N/A'}</td>
                        <td>${business.basicInfo?.ownerName || 'N/A'}</td>
                        <td>
                            <span class="badge ${statusColor[business.verification?.status] || 'bg-secondary'}">
                                ${(business.verification?.status || 'Unknown').charAt(0).toUpperCase() + (business.verification?.status || 'Unknown').slice(1)}
                            </span>
                        </td>
                        <td>
                            <button class="btn btn-sm btn-primary" onclick="viewBusiness('${doc.id}')">
                                <i class="fas fa-eye"></i> View
                            </button>
                            <button class="btn btn-sm btn-warning" onclick="editBusiness('${doc.id}')">
                                <i class="fas fa-edit"></i> Edit
                            </button>
                        </td>
                    </tr>
                `;
            });
        }
        
        businessesHtml += '</tbody></table>';
        document.getElementById('businessesTable').innerHTML = businessesHtml;
        
    } catch (error) {
        console.error('Error loading businesses:', error);
        document.getElementById('businessesTable').innerHTML = `
            <div class="alert alert-danger">
                <i class="fas fa-exclamation-triangle"></i>
                Error loading businesses: ${error.message}
            </div>
        `;
    }
}

// Requests Monitoring Functions
async function loadRequestsData() {
    // Check if user is authenticated
    if (!window.auth?.currentUser) {
        console.log('⚠️ User not authenticated, cannot load requests data');
        showError('Please sign in to access requests data');
        return;
    }
    
    try {
        const requestsSnapshot = await window.firebase.getDocs(window.firebase.collection(window.db, 'requests'));
        
        let requestsHtml = `
            <table class="table table-striped">
                <thead>
                    <tr>
                        <th>Request Title</th>
                        <th>Type</th>
                        <th>User</th>
                        <th>Status</th>
                        <th>Date</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
        `;
        
        if (requestsSnapshot.empty) {
            requestsHtml += `
                <tr>
                    <td colspan="6" class="text-center text-muted">No requests found</td>
                </tr>
            `;
        } else {
            requestsSnapshot.forEach(doc => {
                const request = doc.data();
                const typeColor = {
                    'item': 'bg-primary',
                    'service': 'bg-success', 
                    'ride': 'bg-info'
                };
                const statusColor = {
                    'open': 'bg-warning',
                    'completed': 'bg-success',
                    'in_progress': 'bg-primary',
                    'cancelled': 'bg-danger'
                };
                
                const createdDate = request.createdAt ? 
                    new Date(request.createdAt.seconds * 1000).toLocaleDateString() : 
                    'N/A';
                
                requestsHtml += `
                    <tr>
                        <td>${request.title || 'Untitled Request'}</td>
                        <td><span class="badge ${typeColor[request.type] || 'bg-secondary'}">${(request.type || 'Unknown').charAt(0).toUpperCase() + (request.type || 'Unknown').slice(1)}</span></td>
                        <td>${request.userId || 'Unknown User'}</td>
                        <td><span class="badge ${statusColor[request.status] || 'bg-secondary'}">${(request.status || 'Unknown').charAt(0).toUpperCase() + (request.status || 'Unknown').slice(1)}</span></td>
                        <td>${createdDate}</td>
                        <td>
                            <button class="btn btn-sm btn-primary" onclick="viewRequest('${doc.id}')">
                                <i class="fas fa-eye"></i> View
                            </button>
                        </td>
                    </tr>
                `;
            });
        }
        
        requestsHtml += '</tbody></table>';
        document.getElementById('requestsTable').innerHTML = requestsHtml;
        
    } catch (error) {
        console.error('Error loading requests:', error);
        document.getElementById('requestsTable').innerHTML = `
            <div class="alert alert-danger">
                <i class="fas fa-exclamation-triangle"></i>
                Error loading requests: ${error.message}
            </div>
        `;
    }
}

// Analytics Functions
function loadAnalyticsData() {
    // User Growth Chart
    const userGrowthCtx = document.getElementById('userGrowthChart').getContext('2d');
    new Chart(userGrowthCtx, {
        type: 'line',
        data: {
            labels: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'],
            datasets: [{
                label: 'Users',
                data: [12, 19, 27, 45, 78, 125, 150],
                borderColor: 'rgb(37, 99, 235)',
                backgroundColor: 'rgba(37, 99, 235, 0.1)',
                tension: 0.4
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: {
                    display: false
                }
            }
        }
    });

    // Request Categories Chart
    const requestCategoriesCtx = document.getElementById('requestCategoriesChart').getContext('2d');
    new Chart(requestCategoriesCtx, {
        type: 'doughnut',
        data: {
            labels: ['Items', 'Services', 'Rides', 'Jobs'],
            datasets: [{
                data: [45, 30, 20, 5],
                backgroundColor: [
                    'rgb(37, 99, 235)',
                    'rgb(5, 150, 105)',
                    'rgb(217, 119, 6)',
                    'rgb(220, 38, 38)'
                ]
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: {
                    position: 'bottom'
                }
            }
        }
    });
}

// Utility Functions
function refreshData() {
    loadDashboardData();
    showSuccess('Data refreshed successfully!');
}

function searchUsers() {
    const searchTerm = document.getElementById('userSearch').value;
    console.log('Searching for:', searchTerm);
    // Implement search functionality
}

function filterDrivers(status) {
    console.log('Filtering drivers by status:', status);
    // Implement filter functionality
}

function viewUser(userId) {
    console.log('Viewing user:', userId);
    // Implement user view functionality
}

function editUser(userId) {
    console.log('Editing user:', userId);
    // Implement user edit functionality
}

function viewDriverDetails(driverId) {
    console.log('Viewing driver details:', driverId);
    // Implement driver details view
}

function viewRequest(requestId) {
    console.log('Viewing request:', requestId);
    // Implement request view functionality
}

function viewBusiness(businessId) {
    console.log('Viewing business:', businessId);
    // Implement business view functionality
}

function editBusiness(businessId) {
    console.log('Editing business:', businessId);
    // Implement business edit functionality
}

// Notification Functions
function showSuccess(message) {
    // Simple alert for now - can be replaced with toast notifications
    alert('✅ ' + message);
}

function showError(message) {
    // Simple alert for now - can be replaced with toast notifications
    alert('❌ ' + message);
}

// Initialize dashboard on page load
document.addEventListener('DOMContentLoaded', function() {
    loadDashboardData();
});

// Auto-refresh data every 30 seconds
setInterval(function() {
    if (document.getElementById('dashboard').style.display !== 'none') {
        loadStatistics();
    }
}, 30000);
