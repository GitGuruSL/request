import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_page.dart';
import '../services/auth_service.dart';
import '../services/rest_request_service.dart' as rest;
import '../services/rest_support_services.dart';
import '../services/api_client.dart';
import '../models/request_model.dart' as ui;
import '../models/enhanced_user_model.dart' as em;
import 'unified_request_response/unified_request_view_screen.dart';
import 'unified_request_response/unified_request_edit_screen.dart';
import 'unified_request_response/unified_response_view_screen.dart';
import 'unified_request_response/unified_response_edit_screen.dart';

class MyActivitiesScreen extends StatefulWidget {
  const MyActivitiesScreen({super.key});

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _rest = rest.RestRequestService.instance;
  final _api = ApiClient.instance;

  // Data
  List<rest.RequestModel> _myRequests = [];
  // Removed Orders tab; only Requests and Responses are shown
  List<_ResponseSummary> _myResponses = [];
  // New: Accepted and Completed request buckets for quick access
  List<rest.RequestModel> _acceptedRequests = [];
  List<rest.RequestModel> _completedRequests = [];

  // Loading states
  bool _loadingRequests = false;
  // Removed loading flag for Orders
  bool _loadingResponses = false;
  bool _loadingAccepted = false;
  bool _loadingCompleted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassPage(
      title: 'My Activities',
      body: Column(
        children: [
          // Tab bar in a glass card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: GlassTheme.glassCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: GlassTheme.colors.textAccent,
                    width: 2,
                  ),
                ),
                labelColor: GlassTheme.colors.textPrimary,
                unselectedLabelColor: GlassTheme.colors.textTertiary,
                labelStyle: GlassTheme.labelMedium
                    .copyWith(fontWeight: FontWeight.w700),
                unselectedLabelStyle: GlassTheme.labelMedium,
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                tabs: const [
                  Tab(text: 'Requests'),
                  Tab(text: 'Responses'),
                  Tab(text: 'Accepted'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestsTab(),
                _buildResponsesTab(),
                _buildAcceptedTab(),
                _buildCompletedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _loadingRequests ? 3 : _myRequests.length,
        itemBuilder: (context, index) {
          if (_loadingRequests) {
            return _skeletonCard();
          }
          final r = _myRequests[index];
          return _requestCard(r);
        },
      ),
    );
  }

  Widget _buildResponsesTab() {
    return RefreshIndicator(
      onRefresh: _loadResponses,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _loadingResponses ? 3 : _myResponses.length,
        itemBuilder: (context, index) {
          if (_loadingResponses) return _skeletonCard();
          final resp = _myResponses[index];
          return _responseCard(resp);
        },
      ),
    );
  }

  Widget _buildAcceptedTab() {
    return RefreshIndicator(
      onRefresh: _loadAccepted,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _loadingAccepted ? 3 : _acceptedRequests.length,
        itemBuilder: (context, index) {
          if (_loadingAccepted) return _skeletonCard();
          final r = _acceptedRequests[index];
          return _requestCard(r,
              statusLabel: 'Accepted',
              statusColor: GlassTheme.colors.infoColor);
        },
      ),
    );
  }

  Widget _buildCompletedTab() {
    return RefreshIndicator(
      onRefresh: _loadCompleted,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _loadingCompleted ? 3 : _completedRequests.length,
        itemBuilder: (context, index) {
          if (_loadingCompleted) return _skeletonCard();
          final r = _completedRequests[index];
          return _requestCard(r,
              statusLabel: 'Completed',
              statusColor: GlassTheme.colors.textTertiary);
        },
      ),
    );
  }

  // Removed History tab

  Widget _requestCard(rest.RequestModel r,
      {bool isOrder = false, String? statusLabel, Color? statusColor}) {
    // Maintain backwards-compatibility but allow overrides for Accepted/Completed tabs
    final color = statusColor ?? (isOrder ? Colors.blue : Colors.green);
    final label = statusLabel ?? (isOrder ? 'Accepted' : 'Active');
    return _flatGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(isOrder ? Icons.shopping_bag : Icons.receipt_long,
              color: color),
        ),
        title: Text(
          r.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          r.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(label, style: TextStyle(color: color, fontSize: 11)),
            ),
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              tooltip: 'Actions',
              onSelected: (v) async {
                if (v == 'view') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => UnifiedRequestViewScreen(
                              requestId: r.id,
                            )),
                  );
                } else if (v == 'edit') {
                  final full = await _rest.getRequestById(r.id);
                  if (full != null && mounted) {
                    final uiReq = _toUiRequestModel(full);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            UnifiedRequestEditScreen(request: uiReq),
                      ),
                    );
                  }
                } else if (v == 'delete') {
                  final ok = await _confirm('Delete this request?');
                  if (ok) {
                    final done = await _rest.deleteRequest(r.id);
                    if (done) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Request deleted')));
                      _loadRequests();
                    }
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _responseCard(_ResponseSummary s) {
    final statusColor = s.accepted ? Colors.blue : Colors.orange;
    return _flatGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(s.accepted ? Icons.verified : Icons.reply,
              color: statusColor),
        ),
        title: Text(
          s.requestTitle ?? 'Response',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          s.message ?? '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                s.accepted ? 'Accepted' : 'Sent',
                style: TextStyle(color: statusColor, fontSize: 11),
              ),
            ),
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              tooltip: 'Actions',
              onSelected: (v) async {
                if (v == 'view' || v == 'edit') {
                  final req = await _rest.getRequestById(s.requestId);
                  if (req == null) return;
                  final page =
                      await _rest.getResponses(s.requestId, limit: 100);
                  rest.ResponseModel? resp;
                  try {
                    resp = page.responses.firstWhere((e) => e.id == s.id);
                  } catch (_) {
                    resp =
                        page.responses.isNotEmpty ? page.responses.first : null;
                  }
                  if (!mounted || resp == null) return;
                  if (v == 'view') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UnifiedResponseViewScreen(
                          request: _toUiRequestModel(req),
                          response: _toUiResponseModel(resp!, req),
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UnifiedResponseEditScreen(
                          request: _toUiRequestModel(req),
                          response: _toUiResponseModel(resp!, req),
                        ),
                      ),
                    );
                  }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'view', child: Text('View')),
                PopupMenuItem(value: 'edit', child: Text('Edit')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Converters from REST models to UI models
  ui.RequestModel _toUiRequestModel(rest.RequestModel r) {
    return ui.RequestModel(
      id: r.id,
      requesterId: r.userId,
      title: r.title,
      description: r.description,
      type:
          _getRequestTypeFromString(r.metadata?['type']?.toString() ?? 'item'),
      status: _getRequestStatusFromString(r.status),
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
      budget: r.budget,
      currency: r.currency,
      images: r.imageUrls ?? const [],
      tags: const [],
      priority: ui.Priority.medium,
      location: (r.locationAddress != null &&
              r.locationLatitude != null &&
              r.locationLongitude != null)
          ? ui.LocationInfo(
              latitude: r.locationLatitude ?? 0.0,
              longitude: r.locationLongitude ?? 0.0,
              address: r.locationAddress!,
              city: r.cityName ?? r.locationAddress!,
              country: r.countryCode,
            )
          : (r.cityName != null
              ? ui.LocationInfo(
                  latitude: 0.0,
                  longitude: 0.0,
                  address: r.cityName!,
                  city: r.cityName!,
                  country: r.countryCode,
                )
              : null),
      typeSpecificData: r.metadata ?? const {},
      country: r.countryCode,
    );
  }

  ui.RequestStatus _getRequestStatusFromString(String status) {
    final s = status.toLowerCase();
    switch (s) {
      case 'active':
      case 'open':
        return ui.RequestStatus.active;
      case 'inprogress':
      case 'in_progress':
        return ui.RequestStatus.inProgress;
      case 'completed':
        return ui.RequestStatus.completed;
      case 'cancelled':
        return ui.RequestStatus.cancelled;
      case 'expired':
        return ui.RequestStatus.expired;
      default:
        return ui.RequestStatus.draft;
    }
  }

  em.RequestType _getRequestTypeFromString(String type) {
    final t = type.toLowerCase();
    switch (t) {
      case 'item':
        return em.RequestType.item;
      case 'service':
        return em.RequestType.service;
      case 'delivery':
        return em.RequestType.delivery;
      case 'rental':
      case 'rent':
        return em.RequestType.rental;
      case 'ride':
        return em.RequestType.ride;
      case 'price':
        return em.RequestType.price;
      default:
        return em.RequestType.item;
    }
  }

  ui.ResponseModel _toUiResponseModel(
      rest.ResponseModel r, rest.RequestModel req) {
    return ui.ResponseModel(
      id: r.id,
      requestId: r.requestId,
      responderId: r.userId,
      message: r.message,
      price: r.price,
      currency: r.currency,
      availableFrom: null,
      availableUntil: null,
      images: r.imageUrls ?? const [],
      additionalInfo: r.metadata ?? const {},
      createdAt: r.createdAt,
      isAccepted:
          (req.acceptedResponseId != null && req.acceptedResponseId == r.id),
      rejectionReason: null,
      country: r.countryCode,
      countryName: null,
    );
  }

  Widget _skeletonCard() => _flatGlassCard(
        margin: const EdgeInsets.only(bottom: 12),
        child: Container(height: 76, padding: const EdgeInsets.all(16)),
      );

  // Local flat glass card (no border, no shadow) for this screen
  Widget _flatGlassCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double radius = 20,
  }) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: GlassTheme.colors.glassBackground,
        ),
        borderRadius: BorderRadius.circular(radius),
        // No border, no boxShadow to keep it flat
      ),
      child: child,
    );
  }

  // Removed history helper

  Future<void> _loadAll() async {
    await Future.wait([
      _loadRequests(),
      _loadResponses(),
      _loadAccepted(),
      _loadCompleted(),
    ]);
  }

  Future<void> _loadRequests() async {
    setState(() => _loadingRequests = true);
    try {
      final r = await _rest.getUserRequests(limit: 50);
      setState(() => _myRequests = r?.requests ?? []);
    } finally {
      if (mounted) setState(() => _loadingRequests = false);
    }
  }

  // Removed Orders loading function

  Future<void> _loadResponses() async {
    setState(() => _loadingResponses = true);
    try {
      final uid = AuthService.instance.currentUser?.uid;
      final country = CountryService.instance.getCurrentCountryCode();
      final res = await _api.get<dynamic>(
        '/api/responses',
        queryParameters: {'country': country, 'limit': '100'},
      );
      final list = (res.data is List)
          ? res.data as List
          : (res.data is Map && (res.data as Map)['data'] is List
              ? (res.data as Map)['data'] as List
              : []);
      final mine =
          list.where((e) => (e['user_id'] ?? e['userId']) == uid).toList();
      setState(() {
        _myResponses = mine
            .map((e) => _ResponseSummary.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {
      setState(() => _myResponses = []);
    } finally {
      if (mounted) setState(() => _loadingResponses = false);
    }
  }

  Future<void> _loadAccepted() async {
    setState(() => _loadingAccepted = true);
    try {
      final uid = AuthService.instance.currentUser?.uid;
      final r =
          await _rest.getRequests(userId: uid, hasAccepted: true, limit: 50);
      setState(() => _acceptedRequests = r?.requests ?? []);
    } catch (_) {
      setState(() => _acceptedRequests = []);
    } finally {
      if (mounted) setState(() => _loadingAccepted = false);
    }
  }

  Future<void> _loadCompleted() async {
    setState(() => _loadingCompleted = true);
    try {
      final uid = AuthService.instance.currentUser?.uid;
      final r =
          await _rest.getRequests(userId: uid, status: 'completed', limit: 50);
      setState(() => _completedRequests = r?.requests ?? []);
    } catch (_) {
      setState(() => _completedRequests = []);
    } finally {
      if (mounted) setState(() => _loadingCompleted = false);
    }
  }

  Future<bool> _confirm(String message) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK')),
        ],
      ),
    );
    return res == true;
  }
}

class _ResponseSummary {
  final String id;
  final String requestId;
  final String? message;
  final num? price;
  final String? currency;
  final bool accepted;
  final String? requestTitle;
  _ResponseSummary({
    required this.id,
    required this.requestId,
    this.message,
    this.price,
    this.currency,
    this.accepted = false,
    this.requestTitle,
  });
  factory _ResponseSummary.fromJson(Map<String, dynamic> json) {
    return _ResponseSummary(
      id: json['id']?.toString() ?? '',
      requestId:
          json['request_id']?.toString() ?? json['requestId']?.toString() ?? '',
      message: json['message']?.toString(),
      price: json['price'] is num
          ? json['price'] as num
          : num.tryParse('${json['price']}'),
      currency: json['currency']?.toString(),
      accepted: (json['accepted'] == true) ||
          (json['raw_status']?.toString() == 'accepted'),
      requestTitle: json['request_title']?.toString(),
    );
  }
}
