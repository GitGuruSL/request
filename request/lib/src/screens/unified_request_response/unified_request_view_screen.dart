import 'package:flutter/material.dart';
import '../../services/rest_request_service.dart' as rest;
import '../../services/rest_auth_service.dart';
import '../../models/request_model.dart';
import '../../models/enhanced_user_model.dart';
import '../../utils/image_url_helper.dart';
import 'unified_response_create_screen.dart';
import 'unified_request_edit_screen.dart';
import 'unified_response_edit_screen.dart';
import 'view_all_responses_screen.dart';
import '../chat/conversation_screen.dart';
import '../../services/chat_service.dart';
import '../../models/chat_models.dart';

/// UnifiedRequestViewScreen (Minimal REST Migration)
/// Legacy Firebase-based logic removed. Displays core request info only.
class UnifiedRequestViewScreen extends StatefulWidget {
  final String requestId;
  const UnifiedRequestViewScreen({super.key, required this.requestId});
  @override
  State<UnifiedRequestViewScreen> createState() =>
      _UnifiedRequestViewScreenState();
}

class _UnifiedRequestViewScreenState extends State<UnifiedRequestViewScreen> {
  final rest.RestRequestService _service = rest.RestRequestService.instance;
  rest.RequestModel? _request;
  bool _loading = true;
  bool _isOwner = false;
  // Added state
  List<rest.ResponseModel> _responses = [];
  int _responsesPage = 1;
  int _responsesTotalPages = 1;
  bool _responsesLoading = false;
  final Set<String> _updating = {};
  final Set<String> _deleting = {};
  bool _updatingRequest = false;
  bool _deletingRequest = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await _service.getRequestById(widget.requestId);
      final currentUserId = RestAuthService.instance.currentUser?.uid;
      bool owner =
          r != null && currentUserId != null && r.userId == currentUserId;
      List<rest.ResponseModel> responses = [];
      int totalPages = 1;
      if (r != null) {
        final page = await _service.getResponses(r.id, page: 1, limit: 10);
        responses = page.responses;
        totalPages = page.totalPages;
        _responsesPage = 2; // next page
        _responsesTotalPages = totalPages;
      }
      if (mounted) {
        setState(() {
          _request = r;
          _isOwner = owner;
          _responses = responses;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load request: $e')));
      }
    }
  }

  Future<void> _reloadResponses() async {
    if (_request == null) return;
    _responsesPage = 1;
    _responsesTotalPages = 1;
    _responses.clear();
    await _fetchResponses(reset: true);
  }

  Future<void> _fetchResponses({bool reset = false}) async {
    if (_request == null) return;
    if (_responsesLoading) return;
    if (!reset && _responsesPage > _responsesTotalPages) return;
    setState(() => _responsesLoading = true);
    final pageToLoad = reset ? 1 : _responsesPage;
    final page =
        await _service.getResponses(_request!.id, page: pageToLoad, limit: 10);
    if (mounted) {
      setState(() {
        if (reset) {
          _responses = page.responses;
          _responsesPage = 2;
        } else {
          _responses.addAll(page.responses);
          _responsesPage = page.page + 1;
        }
        _responsesTotalPages = page.totalPages;
        _responsesLoading = false;
      });
    }
  }

  bool get _hasUserResponded {
    final uid = RestAuthService.instance.currentUser?.uid;
    if (uid == null) return false;
    return _responses.any((r) => r.userId == uid);
  }

  bool get _canRespond {
    if (_request == null) return false;
    if (_isOwner) return false;
    if (_hasUserResponded) return false;
    if (_request!.status.toLowerCase() != 'active') return false;
    return RestAuthService.instance.currentUser != null;
  }

  void _openCreateResponseSheet() {
    if (_request == null) return;

    // Convert REST model to enhanced model
    final requestModel = _convertToRequestModel(_request!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UnifiedResponseCreateScreen(request: requestModel),
      ),
    ).then((_) => _reloadResponses()); // Refresh responses when returning
  }

  Future<void> _messageRequester(rest.RequestModel r) async {
    final currentUserId = RestAuthService.instance.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to chat')));
      return;
    }
    if (currentUserId == r.userId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('This is your own request. You cannot message yourself.')));
      return;
    }
    try {
      final (convo, messages) = await ChatService.instance.openConversation(
          requestId: r.id, currentUserId: currentUserId, otherUserId: r.userId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ConversationScreen(
              conversation: convo, initialMessages: messages),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to open chat: $e')));
    }
  }

  void _navigateToRequestEdit() {
    if (_request == null) return;

    // Convert REST model to enhanced model
    final requestModel = _convertToRequestModel(_request!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedRequestEditScreen(request: requestModel),
      ),
    ).then((_) => _load()); // Refresh when returning
  }

  void _navigateToViewAllResponses() {
    if (_request == null) return;

    // Convert REST model to enhanced model
    final requestModel = _convertToRequestModel(_request!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewAllResponsesScreen(request: requestModel),
      ),
    ).then((_) => _reloadResponses()); // Refresh responses when returning
  }

  void _navigateToResponseEdit(rest.ResponseModel response) {
    if (_request == null) return;

    // Convert REST models to enhanced models
    final requestModel = _convertToRequestModel(_request!);
    final responseModel = _convertToResponseModel(response);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedResponseEditScreen(
          request: requestModel,
          response: responseModel,
        ),
      ),
    ).then((_) => _reloadResponses()); // Refresh responses when returning
  }

  // Helper method to convert REST RequestModel to enhanced RequestModel
  RequestModel _convertToRequestModel(rest.RequestModel restRequest) {
    return RequestModel(
      id: restRequest.id,
      title: restRequest.title,
      description: restRequest.description,
      requesterId: restRequest.userId,
      type: _getRequestTypeFromString(
          restRequest.metadata?['type']?.toString() ?? 'item'),
      status: _getRequestStatusFromString(restRequest.status),
      createdAt: restRequest.createdAt,
      updatedAt: restRequest.updatedAt,
      budget: restRequest.budget,
      currency: restRequest.currency,
      images: restRequest.imageUrls ?? [],
      tags: [],
      priority: Priority.medium,
      location: restRequest.locationAddress != null &&
              restRequest.locationLatitude != null &&
              restRequest.locationLongitude != null
          ? LocationInfo(
              latitude: restRequest.locationLatitude!,
              longitude: restRequest.locationLongitude!,
              address: restRequest.locationAddress!,
              city: restRequest.cityName ?? restRequest.locationAddress!,
              country: restRequest.countryCode,
            )
          : (restRequest.cityName != null
              ? LocationInfo(
                  latitude: 0.0,
                  longitude: 0.0,
                  address: restRequest.cityName!,
                  city: restRequest.cityName!,
                  country: restRequest.countryCode,
                )
              : null),
      typeSpecificData: restRequest.metadata ?? {},
      country: restRequest.countryCode,
    );
  }

  // Helper method to convert REST ResponseModel to enhanced ResponseModel
  ResponseModel _convertToResponseModel(rest.ResponseModel restResponse) {
    return ResponseModel(
      id: restResponse.id,
      requestId: restResponse.requestId,
      responderId: restResponse.userId,
      message: restResponse.message,
      price: restResponse.price,
      currency: restResponse.currency,
      images: [],
      isAccepted: _request?.acceptedResponseId == restResponse.id,
      createdAt: restResponse.createdAt,
      availableFrom: null,
      availableUntil: null,
      additionalInfo: {},
      rejectionReason: null,
    );
  }

  RequestType _getRequestTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'item':
        return RequestType.item;
      case 'service':
        return RequestType.service;
      case 'delivery':
        return RequestType.delivery;
      case 'rental':
      case 'rent':
        return RequestType.rental;
      case 'ride':
        return RequestType.ride;
      case 'price':
        return RequestType.price;
      default:
        return RequestType.item;
    }
  }

  RequestStatus _getRequestStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return RequestStatus.active;
      case 'open':
        return RequestStatus.open;
      case 'completed':
        return RequestStatus.completed;
      case 'cancelled':
        return RequestStatus.cancelled;
      case 'inprogress':
        return RequestStatus.inProgress;
      case 'expired':
        return RequestStatus.expired;
      default:
        return RequestStatus.active;
    }
  }

  void _openEditResponseSheet(rest.ResponseModel response) {
    final messageController = TextEditingController(text: response.message);
    final priceController = TextEditingController(
        text: response.price != null ? response.price!.toStringAsFixed(0) : '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(builder: (ctx, setSheet) {
          final isBusy = _updating.contains(response.id);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(
                        child: Text('Edit Response',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx))
                  ]),
                  TextField(
                      controller: messageController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                          labelText: 'Message', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(
                      controller: priceController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Price (optional)',
                          prefixIcon: Icon(Icons.attach_money))),
                  const SizedBox(height: 16),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isBusy
                            ? null
                            : () async {
                                final msg = messageController.text.trim();
                                if (msg.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Message required')));
                                  return;
                                }
                                setState(() => _updating.add(response.id));
                                setSheet(() => {});
                                final priceText = priceController.text.trim();
                                final priceVal = priceText.isEmpty
                                    ? null
                                    : double.tryParse(priceText);
                                final updated = await _service
                                    .updateResponse(_request!.id, response.id, {
                                  'message': msg,
                                  'price': priceVal,
                                });
                                if (updated != null) {
                                  final idx = _responses
                                      .indexWhere((r) => r.id == response.id);
                                  if (idx != -1)
                                    setState(() => _responses[idx] = updated);
                                  if (mounted) Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Response updated')));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Failed to update response')));
                                }
                                if (mounted)
                                  setState(() => _updating.remove(response.id));
                              },
                        icon: isBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save),
                        label: Text(isBusy ? 'Saving...' : 'Save Changes'),
                      )),
                  const SizedBox(height: 12),
                ]),
          );
        }),
      ),
    );
  }

  void _confirmDelete(rest.ResponseModel response) async {
    final isBusy = _deleting.contains(response.id);
    if (isBusy) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Response'),
        content: const Text(
            'Are you sure you want to delete this response? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _deleting.add(response.id));
    final success = await _service.deleteResponse(_request!.id, response.id);
    if (success) {
      setState(() => _responses.removeWhere((r) => r.id == response.id));
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Response deleted')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete response')));
    }
    if (mounted) setState(() => _deleting.remove(response.id));
  }

  void _openEditRequestSheet() {
    if (_request == null) return;
    final r = _request!;
    final titleController = TextEditingController(text: r.title);
    final descController = TextEditingController(text: r.description);
    final budgetController =
        TextEditingController(text: r.budget?.toStringAsFixed(0) ?? '');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(builder: (ctx, setSheet) {
          final busy = _updatingRequest;
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(
                        child: Text('Edit Request',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx))
                  ]),
                  TextField(
                      controller: titleController,
                      maxLength: 80,
                      decoration: const InputDecoration(labelText: 'Title')),
                  TextField(
                      controller: descController,
                      maxLines: 4,
                      decoration:
                          const InputDecoration(labelText: 'Description')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: budgetController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Budget')),
                  const SizedBox(height: 16),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: busy
                            ? null
                            : () async {
                                final title = titleController.text.trim();
                                final desc = descController.text.trim();
                                if (title.isEmpty || desc.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Title & description required')));
                                  return;
                                }
                                final budget = double.tryParse(
                                    budgetController.text.trim());
                                setState(() => _updatingRequest = true);
                                setSheet(() => {});

                                final updates = <String, dynamic>{
                                  'title': title,
                                  'description': desc,
                                  if (budget != null) 'budget': budget
                                };
                                final updated =
                                    await _service.updateRequest(r.id, updates);
                                if (updated != null) {
                                  setState(() => _request = updated);
                                  if (mounted) Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Request updated')));
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Failed to update request')));
                                }
                                if (mounted)
                                  setState(() => _updatingRequest = false);
                              },
                        icon: busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save),
                        label: Text(busy ? 'Saving...' : 'Save Changes'),
                      )),
                  const SizedBox(height: 12),
                ]),
          );
        }),
      ),
    );
  }

  Future<void> _toggleStatus() async {
    if (_request == null) return;
    if (_updatingRequest) return;
    final cur = _request!.status.toLowerCase();
    final newStatus = cur == 'active' ? 'closed' : 'active';
    setState(() => _updatingRequest = true);
    final updated =
        await _service.updateRequest(_request!.id, {'status': newStatus});
    if (updated != null) {
      setState(() => _request = updated);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status set to ${updated.status}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')));
    }
    if (mounted) setState(() => _updatingRequest = false);
  }

  Future<void> _confirmDeleteRequest() async {
    if (_request == null) return;
    if (_deletingRequest) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Request'),
        content: const Text(
            'Delete this request permanently? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _deletingRequest = true);
    final success = await _service.deleteRequest(_request!.id);
    if (success) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Request deleted')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete request')));
    }
    if (mounted) setState(() => _deletingRequest = false);
  }

  // (Removed obsolete placeholder _messageRequester definition; real implementation placed earlier.)

  void _showImageFullScreen(String imageUrl) {
    // Ensure we have the full URL
    final fullImageUrl = ImageUrlHelper.getFullImageUrl(imageUrl);
    ImageUrlHelper.debugImageUrl(imageUrl); // Debug output

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  fullImageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.white, size: 50),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fullImageUrl,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Loading image...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
          appBar: AppBar(title: const Text('Loading...')),
          body: const Center(child: CircularProgressIndicator()));
    }
    if (_request == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Request')),
          body: const Center(child: Text('Request not found.')));
    }
    final r = _request!;
    return Scaffold(
      appBar: AppBar(
          title: Text(r.title.isNotEmpty ? r.title : 'Request'),
          actions: [
            IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                tooltip: 'Reload'),
            if (_isOwner)
              PopupMenuButton<String>(
                onSelected: (val) {
                  switch (val) {
                    case 'edit':
                      _openEditRequestSheet();
                      break;
                    case 'edit_full':
                      _navigateToRequestEdit();
                      break;
                    case 'status':
                      _toggleStatus();
                      break;
                    case 'delete':
                      _confirmDeleteRequest();
                      break;
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Quick Edit')),
                  const PopupMenuItem(
                      value: 'edit_full', child: Text('Full Edit Screen')),
                  PopupMenuItem(
                      value: 'status',
                      child: Text(_request!.status.toLowerCase() == 'active'
                          ? 'Close Request'
                          : 'Reopen Request')),
                  const PopupMenuItem(
                      value: 'delete', child: Text('Delete Request')),
                ],
              ),
          ]),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(r.title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(r.description,
                      style: TextStyle(color: Colors.grey[700], height: 1.4)),

                  // Images Section
                  if (r.imageUrls != null && r.imageUrls!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Images',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        // Clean and filter valid image URLs
                        final validImageUrls =
                            ImageUrlHelper.cleanImageUrls(r.imageUrls);

                        if (validImageUrls.isEmpty) {
                          return Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              // Border removed per design update
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported,
                                      color: Colors.grey[400], size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No valid images available',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (r.imageUrls!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${r.imageUrls!.length} invalid URL(s) filtered out',
                                      style: TextStyle(
                                        color: Colors.orange[600],
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: validImageUrls.length,
                            itemBuilder: (context, index) => GestureDetector(
                              onTap: () =>
                                  _showImageFullScreen(validImageUrls[index]),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  // Border removed
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    validImageUrls[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      // Debug the image URL issue
                                      ImageUrlHelper.debugImageUrl(
                                          r.imageUrls![index]);
                                      return Container(
                                        color: Colors.grey[200],
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                                Icons.image_not_supported),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Load Error',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${index + 1}/${validImageUrls.length}',
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[100],
                                        child: Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                value: loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                            .cumulativeBytesLoaded /
                                                        loadingProgress
                                                            .expectedTotalBytes!
                                                    : null,
                                                strokeWidth: 2,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Loading...',
                                                style: TextStyle(
                                                  fontSize: 8,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],

                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip(Icons.category, r.categoryName ?? r.categoryId),
                    if (r.cityName != null)
                      _chip(Icons.location_on, r.cityName!),
                    _chip(Icons.flag, r.countryCode),
                    _chip(Icons.access_time, _relativeTime(r.createdAt)),
                    _chip(Icons.info_outline, r.status.toUpperCase()),
                  ]),

                  // Requester Information Section
                  const SizedBox(height: 20),
                  const Text('Requester Information',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.person, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(r.userName ?? 'Unknown User',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          if (!_isOwner) ...[
                            IconButton(
                              onPressed: () => _messageRequester(r),
                              icon: const Icon(
                                Icons.message,
                                color: Colors.blue,
                                size: 20,
                              ),
                              tooltip: 'Message Requester',
                            ),
                          ],
                        ]),
                        // TODO: Add phone number display when available in the model
                        // if (r.phone != null) ...[
                        //   const SizedBox(height: 4),
                        //   Row(children: [
                        //     Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        //     const SizedBox(width: 8),
                        //     Expanded(
                        //         child: Text(r.phone!,
                        //             style: TextStyle(color: Colors.grey[700]))),
                        //   ]),
                        // ],
                      ],
                    ),
                  ),

                  // Location Information Section
                  if (r.locationAddress != null &&
                      r.locationAddress!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text('Location Information',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.location_on,
                                size: 18, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(r.locationAddress!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ),
                          ]),
                          // Coordinates intentionally hidden per requirement: show only human-readable location
                        ],
                      ),
                    ),
                  ],

                  if (r.metadata != null && r.metadata!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Request Details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Budget first
                          if (r.budget != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    width: 80,
                                    child: Text('Budget:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12)),
                                  ),
                                  Expanded(
                                    child: Text(_formatBudget(r),
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                          // Then metadata entries with proper formatting (excluding IDs)
                          ...r.metadata!.entries
                              .where((e) => !_shouldHideField(e.key))
                              .take(10)
                              .map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 80,
                                            child: Text('${_formatKey(e.key)}:',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12)),
                                          ),
                                          Expanded(
                                            child: Text(_formatValue(e.value),
                                                style: const TextStyle(
                                                    fontSize: 12)),
                                          ),
                                        ]),
                                  )),
                          if (r.metadata!.length > 10)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                  '+${r.metadata!.length - 10} more details',
                                  style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic)),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (_isOwner) ...[
                    const SizedBox(height: 24),
                    Row(children: [
                      if (_updatingRequest)
                        const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      Text('Status: ${r.status}',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 8),
                    Row(children: [
                      TextButton.icon(
                          onPressed: _toggleStatus,
                          icon: Icon(
                              r.status.toLowerCase() == 'active'
                                  ? Icons.lock
                                  : Icons.lock_open,
                              size: 16),
                          label: Text(r.status.toLowerCase() == 'active'
                              ? 'Close'
                              : 'Reopen')),
                      TextButton.icon(
                          onPressed: _navigateToRequestEdit,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Edit')),
                      TextButton.icon(
                          onPressed: _confirmDeleteRequest,
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Delete')),
                    ])
                  ],
                ])),
            const SizedBox(height: 20),
            _responsesSection(),
          ]),
        ),
      ),
      floatingActionButton: _canRespond
          ? FloatingActionButton.extended(
              onPressed: _openCreateResponseSheet,
              icon: const Icon(Icons.reply),
              label: const Text('Respond'))
          : null,
    );
  }

  Widget _sectionCard({required Widget child}) => Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(padding: const EdgeInsets.all(20), child: child),
      );

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Flexible(
            child: Text(label,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      );

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  String _formatBudget(rest.RequestModel r) {
    final cur = r.currency ?? '';
    if (r.budget == null) return 'No budget';
    return '$cur${r.budget!.toStringAsFixed(0)}';
  }

  String _formatKey(String key) {
    // Convert camelCase to readable text
    switch (key.toLowerCase()) {
      case 'itemname':
        return 'Item Name';
      case 'categoryid':
        return 'Category ID';
      case 'subcategoryid':
      case 'subcategory_id':
        return 'Subcategory ID';
      case 'startdate':
        return 'Start Date';
      case 'enddate':
        return 'End Date';
      case 'pickupdropoffpreference':
        return 'Pickup/Dropoff';
      default:
        // Convert camelCase to space-separated words
        return key
            .replaceAllMapped(
              RegExp(r'([A-Z])'),
              (match) => ' ${match.group(1)}',
            )
            .trim()
            .split(' ')
            .map((word) =>
                word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
    }
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';

    // Handle timestamp values (large numbers that look like epoch timestamps)
    if (value is int && value > 1000000000000) {
      try {
        final date = DateTime.fromMillisecondsSinceEpoch(value);
        return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } catch (e) {
        return value.toString();
      }
    }

    // Handle boolean values
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }

    // Handle RequestType enum values
    if (value.toString().startsWith('RequestType.')) {
      return value.toString().split('.').last.toUpperCase();
    }

    return value.toString();
  }

  bool _shouldHideField(String key) {
    final keyLower = key.toLowerCase();

    // Hide internal ID fields that users don't need to see
    final hiddenFields = [
      'categoryId',
      'categoryid',
      'category_id',
      'subCategoryId',
      'subcategoryId',
      'subcategory_id',
      'subcategoryid',
      'sub_category_id',
      'type', // Also hide the type since it's already shown in the header
    ];

    // Also hide any field that ends with "id" or contains "categoryid" or "subcategoryid"
    final shouldHide = hiddenFields.contains(keyLower) ||
        keyLower.endsWith('id') &&
            (keyLower.contains('category') || keyLower.contains('subcategory'));

    return shouldHide;
  }

  Widget _responsesSection() {
    final canLoadMore =
        _responsesPage <= _responsesTotalPages && !_responsesLoading;
    return _sectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Responses',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const Spacer(),
        if (_responses.isNotEmpty)
          TextButton(
            onPressed: _navigateToViewAllResponses,
            child: const Text('View All'),
          ),
        IconButton(
            onPressed: _reloadResponses,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload')
      ]),
      const SizedBox(height: 8),
      if (_responses.isEmpty && !_responsesLoading)
        Text(_canRespond ? 'Be the first to respond.' : 'No responses yet.',
            style: TextStyle(color: Colors.grey[600])),
      ..._responses.map(_responseTile),
      if (_responsesLoading)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator())),
      if (canLoadMore)
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
                onPressed: () => _fetchResponses(),
                icon: const Icon(Icons.more_horiz),
                label: const Text('Load more'))),
    ]));
  }

  Widget _responseTile(rest.ResponseModel r) {
    final myUid = RestAuthService.instance.currentUser?.uid;
    final isMine = myUid != null && r.userId == myUid;
    final isAccepted = _request?.acceptedResponseId == r.id;
    final busy = _updating.contains(r.id) || _deleting.contains(r.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAccepted
            ? Colors.green[50]
            : (isMine ? Colors.blue[50] : Colors.grey[50]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isAccepted
                ? Colors.green
                : (isMine ? Colors.blue[100]! : Colors.grey[200]!)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(isMine ? Icons.person_pin : Icons.person,
              size: 16, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
              child: Text(r.userName ?? 'User ${r.userId}',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isAccepted
                          ? Colors.green[800]
                          : (isMine ? Colors.blue[800] : null)))),
          if (busy)
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
          Text(_relativeTime(r.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          if (!busy)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') {
                  _openEditResponseSheet(r);
                } else if (val == 'edit_full') {
                  _navigateToResponseEdit(r);
                } else if (val == 'delete') {
                  _confirmDelete(r);
                } else if (val == 'accept') {
                  _acceptResponse(r.id);
                } else if (val == 'unaccept') {
                  _clearAccepted();
                }
              },
              itemBuilder: (ctx) {
                final items = <PopupMenuEntry<String>>[];
                if (isMine) {
                  items.add(const PopupMenuItem(
                      value: 'edit', child: Text('Quick Edit')));
                  items.add(const PopupMenuItem(
                      value: 'edit_full', child: Text('Full Edit Screen')));
                  items.add(const PopupMenuItem(
                      value: 'delete', child: Text('Delete')));
                }
                if (_isOwner) {
                  if (isAccepted) {
                    items.add(const PopupMenuItem(
                        value: 'unaccept', child: Text('Unaccept')));
                  } else {
                    items.add(const PopupMenuItem(
                        value: 'accept', child: Text('Accept')));
                  }
                }
                return items;
              },
            ),
        ]),
        const SizedBox(height: 6),
        Text(r.message, style: const TextStyle(fontSize: 14)),
        if (r.price != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.attach_money, size: 16, color: Colors.green),
            Text(
                '${r.currency ?? _request?.currency ?? ''}${r.price!.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w600))
          ])
        ],
        if (isAccepted) ...[
          const SizedBox(height: 8),
          Row(children: const [
            Icon(Icons.verified, size: 16, color: Colors.green),
            SizedBox(width: 4),
            Text('ACCEPTED',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green))
          ])
        ]
      ]),
    );
  }

  Future<void> _acceptResponse(String responseId) async {
    if (_request == null) return;
    try {
      final res = await _service.acceptResponse(_request!.id, responseId);
      if (res != null) {
        setState(() => _request = res);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Response accepted')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to accept response')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _clearAccepted() async {
    if (_request == null) return;
    try {
      final res = await _service.clearAcceptedResponse(_request!.id);
      if (res != null) {
        setState(() => _request = res);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Cleared acceptance')));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Failed to unaccept')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
