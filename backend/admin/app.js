/* ============================================
   Our Bible Admin Dashboard - Application Logic
   ============================================ */

// --- Configuration ---
let API_BASE = 'http://localhost:3001/api';

// --- State ---
let authToken = localStorage.getItem('ourbible_admin_token');
let currentUser = null;

// --- Initialization ---
document.addEventListener('DOMContentLoaded', () => {
    createToastContainer();
    if (authToken) {
        showDashboard();
    } else {
        showLogin();
    }
});

// ============================================
// Authentication
// ============================================

function showLogin() {
    document.getElementById('login-screen').style.display = 'flex';
    document.getElementById('dashboard').style.display = 'none';
}

function showDashboard() {
    document.getElementById('login-screen').style.display = 'none';
    document.getElementById('dashboard').style.display = 'flex';
    loadDashboard();
}

async function handleLogin(e) {
    e.preventDefault();
    const email = document.getElementById('login-email').value.trim();
    const password = document.getElementById('login-password').value;
    const errorEl = document.getElementById('login-error');
    const btn = document.getElementById('login-btn');

    errorEl.style.display = 'none';
    btn.disabled = true;
    btn.textContent = 'Signing in...';

    try {
        const res = await fetch(`${API_BASE}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });

        const data = await res.json();

        if (!res.ok) {
            throw new Error(data.error || data.message || 'Login failed');
        }

        authToken = data.token;
        currentUser = data.user;
        localStorage.setItem('ourbible_admin_token', authToken);

        showDashboard();
    } catch (err) {
        errorEl.textContent = err.message;
        errorEl.style.display = 'block';
    } finally {
        btn.disabled = false;
        btn.textContent = 'Sign In';
    }
}

function handleLogout() {
    authToken = null;
    currentUser = null;
    localStorage.removeItem('ourbible_admin_token');
    showLogin();
}

// ============================================
// API Helper
// ============================================

async function apiRequest(endpoint, options = {}) {
    const url = `${API_BASE}${endpoint}`;
    const headers = {
        'Content-Type': 'application/json',
        ...(authToken ? { 'Authorization': `Bearer ${authToken}` } : {}),
        ...(options.headers || {})
    };

    try {
        const res = await fetch(url, { ...options, headers });

        if (res.status === 401 || res.status === 403) {
            showToast('Session expired. Please log in again.', 'error');
            handleLogout();
            return null;
        }

        const data = await res.json();

        if (!res.ok) {
            throw new Error(data.error || data.message || `Request failed (${res.status})`);
        }

        return data;
    } catch (err) {
        if (err.name === 'TypeError' && err.message.includes('fetch')) {
            showToast('Cannot connect to server. Is the backend running?', 'error');
        } else {
            showToast(err.message, 'error');
        }
        throw err;
    }
}

// ============================================
// Navigation
// ============================================

function navigate(section, el) {
    if (el) {
        el.preventDefault && el.preventDefault();
    }

    // Update sidebar active state
    document.querySelectorAll('.nav-item').forEach(item => item.classList.remove('active'));
    const navItem = el || document.querySelector(`.nav-item[data-section="${section}"]`);
    if (navItem) navItem.classList.add('active');

    // Update page title
    const titles = {
        overview: 'Dashboard',
        pending: 'Pending Reviews',
        hymns: 'Hymns',
        materials: 'Study Materials',
        users: 'Users',
        settings: 'Settings'
    };
    document.getElementById('page-title').textContent = titles[section] || 'Dashboard';

    // Show/hide sections
    document.querySelectorAll('.section').forEach(s => s.classList.remove('active'));
    const target = document.getElementById(`section-${section}`);
    if (target) target.classList.add('active');

    // Load data for the section
    switch (section) {
        case 'overview': loadStats(); break;
        case 'pending': loadPendingPosts(); break;
        case 'hymns': loadHymns(); break;
        case 'materials': loadMaterials(); break;
        case 'users': loadUsers(); break;
    }

    // Close mobile sidebar
    document.querySelector('.sidebar').classList.remove('open');
}

function toggleSidebar() {
    document.querySelector('.sidebar').classList.toggle('open');
}

// ============================================
// Dashboard Overview
// ============================================

function loadDashboard() {
    if (currentUser) {
        document.getElementById('admin-name').textContent = currentUser.name || currentUser.email || 'Admin';
        const settingsEmail = document.getElementById('settings-email');
        if (settingsEmail) settingsEmail.textContent = currentUser.email || '—';
    }
    loadStats();
}

async function loadStats() {
    const setCount = (id, val) => {
        const el = document.getElementById(id);
        if (el) el.textContent = val !== undefined && val !== null ? val : '—';
    };

    try {
        const data = await apiRequest('/admin/stats');
        if (data) {
            setCount('user-count', data.totalUsers ?? data.users ?? 0);
            setCount('pending-count', data.pendingPosts ?? data.pending ?? 0);
            setCount('approved-count', data.approvedPosts ?? data.approved ?? 0);
            setCount('hymn-count', data.totalHymns ?? data.hymns ?? 0);
            setCount('material-count', data.totalMaterials ?? data.materials ?? 0);
        }
    } catch (err) {
        // Already handled by apiRequest
    }
}

// ============================================
// Content Moderation
// ============================================

async function loadPendingPosts() {
    const container = document.getElementById('pending-list');
    container.innerHTML = '<div class="loading">Loading pending posts...</div>';

    try {
        const data = await apiRequest('/admin/posts?status=pending');
        const posts = data.posts || data || [];

        if (!Array.isArray(posts) || posts.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <div class="empty-icon">&#x2714;</div>
                    <p>No pending posts to review. All caught up!</p>
                </div>`;
            return;
        }

        container.innerHTML = posts.map(post => `
            <div class="review-card" id="post-${post.id}">
                <div class="review-header">
                    <span class="badge badge-pending">Pending</span>
                    <span class="review-category">${escapeHtml(post.category || 'General')}</span>
                </div>
                <h3 class="review-title">${escapeHtml(post.title || 'Untitled')}</h3>
                <p class="review-preview">${escapeHtml(truncate(post.content || post.body || '', 200))}</p>
                <div class="review-meta">By ${escapeHtml(post.author_name || post.author || 'Unknown')} &middot; ${formatDate(post.created_at || post.date)}</div>
                <div class="review-actions">
                    <button class="btn btn-approve" onclick="approvePost('${post.id}')">&#x2713; Approve</button>
                    <button class="btn btn-reject" onclick="rejectPost('${post.id}')">&#x2717; Reject</button>
                    <button class="btn btn-preview" onclick="previewPost(${JSON.stringify(post).replace(/"/g, '&quot;')})">Preview</button>
                </div>
            </div>
        `).join('');
    } catch (err) {
        container.innerHTML = '<div class="empty-state"><p>Failed to load pending posts.</p></div>';
    }
}

async function approvePost(id) {
    try {
        await apiRequest(`/admin/posts/${id}/approve`, { method: 'PUT' });
        showToast('Post approved successfully', 'success');
        const card = document.getElementById(`post-${id}`);
        if (card) card.remove();
        loadStats();
    } catch (err) {
        // Handled by apiRequest
    }
}

async function rejectPost(id) {
    try {
        await apiRequest(`/admin/posts/${id}/reject`, { method: 'PUT' });
        showToast('Post rejected', 'success');
        const card = document.getElementById(`post-${id}`);
        if (card) card.remove();
        loadStats();
    } catch (err) {
        // Handled by apiRequest
    }
}

function previewPost(post) {
    document.getElementById('preview-title').textContent = post.title || 'Untitled';
    document.getElementById('preview-content').textContent = post.content || post.body || '';
    document.getElementById('preview-category').textContent = post.category || '';
    document.getElementById('preview-author').textContent = `By ${post.author_name || post.author || 'Unknown'}`;
    document.getElementById('preview-date').textContent = formatDate(post.created_at || post.date);

    const badge = document.getElementById('preview-badge');
    badge.textContent = post.status || 'Pending';
    badge.className = `badge badge-${(post.status || 'pending').toLowerCase()}`;

    const actions = document.getElementById('preview-actions');
    if (post.status === 'pending') {
        actions.innerHTML = `
            <button class="btn btn-reject" onclick="rejectPost('${post.id}'); closeModal('preview-modal');">&#x2717; Reject</button>
            <button class="btn btn-approve" onclick="approvePost('${post.id}'); closeModal('preview-modal');">&#x2713; Approve</button>
        `;
    } else {
        actions.innerHTML = '';
    }

    showModal('preview-modal');
}

// ============================================
// Hymn Management
// ============================================

async function loadHymns() {
    const container = document.getElementById('hymn-list');
    container.innerHTML = '<div class="loading">Loading hymns...</div>';

    try {
        const data = await apiRequest('/community/hymns');
        const hymns = data.hymns || data || [];

        if (!Array.isArray(hymns) || hymns.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <div class="empty-icon">&#x1F3B5;</div>
                    <p>No hymns yet. Add the first one!</p>
                </div>`;
            return;
        }

        container.innerHTML = `
            <table class="data-table">
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Title</th>
                        <th>Author</th>
                        <th>Category</th>
                        <th>Year</th>
                    </tr>
                </thead>
                <tbody>
                    ${hymns.map(h => `
                        <tr>
                            <td>${h.number || h.hymn_number || '—'}</td>
                            <td><strong>${escapeHtml(h.title || '')}</strong></td>
                            <td>${escapeHtml(h.author || '—')}</td>
                            <td>${escapeHtml(h.category || '—')}</td>
                            <td>${h.year || '—'}</td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>`;
    } catch (err) {
        container.innerHTML = '<div class="empty-state"><p>Failed to load hymns.</p></div>';
    }
}

async function handleAddHymn(e) {
    e.preventDefault();
    const btn = document.getElementById('hymn-submit-btn');
    const errorEl = document.getElementById('hymn-form-error');
    errorEl.style.display = 'none';
    btn.disabled = true;
    btn.textContent = 'Adding...';

    const payload = {
        number: parseInt(document.getElementById('hymn-number').value),
        title: document.getElementById('hymn-title').value.trim(),
        author: document.getElementById('hymn-author').value.trim(),
        year: document.getElementById('hymn-year').value ? parseInt(document.getElementById('hymn-year').value) : null,
        lyrics: document.getElementById('hymn-lyrics').value.trim(),
        category: document.getElementById('hymn-category').value
    };

    try {
        await apiRequest('/admin/hymns', {
            method: 'POST',
            body: JSON.stringify(payload)
        });
        showToast('Hymn added successfully', 'success');
        closeModal('hymn-modal');
        document.getElementById('hymn-form').reset();
        loadHymns();
    } catch (err) {
        errorEl.textContent = err.message;
        errorEl.style.display = 'block';
    } finally {
        btn.disabled = false;
        btn.textContent = 'Add Hymn';
    }
}

// ============================================
// Study Material Management
// ============================================

async function loadMaterials() {
    const container = document.getElementById('material-list');
    container.innerHTML = '<div class="loading">Loading study materials...</div>';

    try {
        const data = await apiRequest('/community/materials');
        const materials = data.materials || data || [];

        if (!Array.isArray(materials) || materials.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <div class="empty-icon">&#x1F4D6;</div>
                    <p>No study materials yet. Add the first one!</p>
                </div>`;
            return;
        }

        const categoryLabels = {
            open_heavens: 'Open Heavens',
            search_the_scriptures: 'Search the Scriptures',
            daily_manna: 'Daily Manna',
            general: 'General'
        };

        container.innerHTML = `
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Title</th>
                        <th>Author</th>
                        <th>Category</th>
                        <th>Date</th>
                        <th>Source</th>
                    </tr>
                </thead>
                <tbody>
                    ${materials.map(m => `
                        <tr>
                            <td><strong>${escapeHtml(m.title || '')}</strong></td>
                            <td>${escapeHtml(m.author || '—')}</td>
                            <td>${escapeHtml(categoryLabels[m.category] || m.category || '—')}</td>
                            <td>${formatDate(m.date || m.created_at)}</td>
                            <td>${escapeHtml(m.source || '—')}</td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>`;
    } catch (err) {
        container.innerHTML = '<div class="empty-state"><p>Failed to load study materials.</p></div>';
    }
}

async function handleAddMaterial(e) {
    e.preventDefault();
    const btn = document.getElementById('material-submit-btn');
    const errorEl = document.getElementById('material-form-error');
    errorEl.style.display = 'none';
    btn.disabled = true;
    btn.textContent = 'Adding...';

    const payload = {
        title: document.getElementById('material-title').value.trim(),
        author: document.getElementById('material-author').value.trim(),
        source: document.getElementById('material-source').value.trim(),
        category: document.getElementById('material-category').value,
        date: document.getElementById('material-date').value,
        bible_reading: document.getElementById('material-bible-reading').value.trim(),
        memory_verse: document.getElementById('material-memory-verse').value.trim(),
        content: document.getElementById('material-content').value.trim()
    };

    try {
        await apiRequest('/admin/materials', {
            method: 'POST',
            body: JSON.stringify(payload)
        });
        showToast('Study material added successfully', 'success');
        closeModal('material-modal');
        document.getElementById('material-form').reset();
        loadMaterials();
    } catch (err) {
        errorEl.textContent = err.message;
        errorEl.style.display = 'block';
    } finally {
        btn.disabled = false;
        btn.textContent = 'Add Material';
    }
}

// ============================================
// User Management
// ============================================

async function loadUsers() {
    const container = document.getElementById('user-list');
    container.innerHTML = '<div class="loading">Loading users...</div>';

    try {
        const data = await apiRequest('/admin/users');
        const users = data.users || data || [];

        if (!Array.isArray(users) || users.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <div class="empty-icon">&#x1F465;</div>
                    <p>No users found.</p>
                </div>`;
            return;
        }

        container.innerHTML = `
            <table class="data-table">
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Email</th>
                        <th>Role</th>
                        <th>Joined</th>
                        <th>Last Login</th>
                    </tr>
                </thead>
                <tbody>
                    ${users.map(u => `
                        <tr>
                            <td><strong>${escapeHtml(u.name || u.display_name || '—')}</strong></td>
                            <td>${escapeHtml(u.email || '—')}</td>
                            <td>
                                <select class="role-select" onchange="changeUserRole('${u.id}', this.value)" data-user-id="${u.id}">
                                    <option value="user" ${(u.role === 'user') ? 'selected' : ''}>User</option>
                                    <option value="moderator" ${(u.role === 'moderator') ? 'selected' : ''}>Moderator</option>
                                    <option value="admin" ${(u.role === 'admin') ? 'selected' : ''}>Admin</option>
                                </select>
                            </td>
                            <td>${formatDate(u.created_at || u.joined)}</td>
                            <td>${u.last_login ? formatDate(u.last_login) : 'Never'}</td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>`;
    } catch (err) {
        container.innerHTML = '<div class="empty-state"><p>Failed to load users.</p></div>';
    }
}

async function changeUserRole(userId, newRole) {
    try {
        await apiRequest(`/admin/users/${userId}/role`, {
            method: 'PUT',
            body: JSON.stringify({ role: newRole })
        });
        showToast(`Role updated to ${newRole}`, 'success');
    } catch (err) {
        showToast('Failed to update role', 'error');
        loadUsers(); // Reload to reset the select
    }
}

// ============================================
// Settings
// ============================================

function updateApiBase(value) {
    if (value && value.trim()) {
        API_BASE = value.trim().replace(/\/+$/, '');
        showToast('API base URL updated', 'success');
    }
}

// ============================================
// Modals
// ============================================

function showModal(id) {
    const modal = document.getElementById(id);
    if (modal) {
        modal.style.display = 'flex';
        document.body.style.overflow = 'hidden';
    }
}

function closeModal(id) {
    const modal = document.getElementById(id);
    if (modal) {
        modal.style.display = 'none';
        document.body.style.overflow = '';
    }
}

// Close modal on Escape key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        document.querySelectorAll('.modal').forEach(m => {
            if (m.style.display !== 'none') {
                m.style.display = 'none';
            }
        });
        document.body.style.overflow = '';
    }
});

// ============================================
// Toast Notifications
// ============================================

function createToastContainer() {
    if (!document.querySelector('.toast-container')) {
        const container = document.createElement('div');
        container.className = 'toast-container';
        document.body.appendChild(container);
    }
}

function showToast(message, type = 'info') {
    const container = document.querySelector('.toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;

    const icon = type === 'success' ? '&#x2714;' : type === 'error' ? '&#x2717;' : '&#x2139;';
    toast.innerHTML = `<span>${icon}</span> ${escapeHtml(message)}`;

    container.appendChild(toast);

    setTimeout(() => {
        toast.style.animation = 'slideOut 0.3s ease forwards';
        setTimeout(() => toast.remove(), 300);
    }, 4000);
}

// ============================================
// Utility Functions
// ============================================

function escapeHtml(str) {
    if (!str) return '';
    const div = document.createElement('div');
    div.textContent = String(str);
    return div.innerHTML;
}

function truncate(str, len) {
    if (!str) return '';
    return str.length > len ? str.substring(0, len) + '...' : str;
}

function formatDate(dateStr) {
    if (!dateStr) return '—';
    try {
        const d = new Date(dateStr);
        if (isNaN(d.getTime())) return dateStr;
        return d.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    } catch {
        return dateStr;
    }
}
