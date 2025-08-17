import 'package:flutter/material.dart';
import '../../services/rest_request_service.dart' as rest;
import '../../services/rest_auth_service.dart';

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
  bool _responsesLoading = false;
  bool _creating = false;
  final Set<String> _updating = {};
  final Set<String> _deleting = {};

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
      if (r != null) responses = await _service.getResponses(r.id);
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
    setState(() => _responsesLoading = true);
    try {
      final list = await _service.getResponses(_request!.id);
      if (mounted) setState(() => _responses = list);
    } finally {
      if (mounted) setState(() => _responsesLoading = false);
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
    final messageController = TextEditingController();
    final priceController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(builder: (ctx, setSheet) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Expanded(
                          child: Text('New Response',
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
                            labelText: 'Message',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                            labelText: 'Price (optional)',
                            prefixIcon: Icon(Icons.attach_money))),
                    const SizedBox(height: 16),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _creating
                              ? null
                              : () async {
                                  final msg = messageController.text.trim();
                                  if (msg.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Message required')));
                                    return;
                                  }
                                  setState(() => _creating = true);
                                  setSheet(() => {});
                                  final price = double.tryParse(
                                      priceController.text.trim());
                                  final created = await _service.createResponse(
                                      _request!.id,
                                      rest.CreateResponseData(
                                          message: msg,
                                          price: price,
                                          currency: _request!.currency));
                                  if (created != null) {
                                    if (mounted) {
                                      Navigator.pop(ctx);
                                      await _reloadResponses();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content:
                                                  Text('Response submitted')));
                                    }
                                  } else {
                                    if (mounted)
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Failed to submit response')));
                                  }
                                  if (mounted)
                                    setState(() => _creating = false);
                                },
                          icon: _creating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.send),
                          label: Text(
                              _creating ? 'Submitting...' : 'Submit Response'),
                        )),
                    const SizedBox(height: 12),
                  ]),
            );
          })),
    );
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
                tooltip: 'Reload')
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
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _chip(Icons.person, r.userName ?? 'User'),
                    _chip(Icons.category, r.categoryName ?? r.categoryId),
                    if (r.cityName != null)
                      _chip(Icons.location_on, r.cityName!),
                    _chip(Icons.flag, r.countryCode),
                    _chip(Icons.access_time, _relativeTime(r.createdAt)),
                    _chip(Icons.info_outline, r.status.toUpperCase()),
                  ]),
                  if (r.budgetMin != null || r.budgetMax != null) ...[
                    const SizedBox(height: 20),
                    Row(children: [
                      const Icon(Icons.account_balance_wallet,
                          size: 18, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(_formatBudget(r),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ])
                  ],
                  if (r.metadata != null && r.metadata!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text('Extra Details',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...r.metadata!.entries.take(8).map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${e.key}: ',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500)),
                                Expanded(child: Text(e.value.toString())),
                              ]),
                        )),
                    if (r.metadata!.length > 8)
                      Text('+${r.metadata!.length - 8} more entries',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                  if (_isOwner) ...[
                    const SizedBox(height: 24),
                    const Text('Owner features (edit / responses) coming soon',
                        style: TextStyle(
                            fontSize: 12, fontStyle: FontStyle.italic)),
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
          Text(label, style: const TextStyle(fontSize: 12)),
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
    if (r.budgetMin == null && r.budgetMax == null) return 'No budget';
    if (r.budgetMin != null && r.budgetMax != null) {
      if (r.budgetMin == r.budgetMax)
        return '$cur${r.budgetMin!.toStringAsFixed(0)}';
      return '$cur${r.budgetMin!.toStringAsFixed(0)}-${r.budgetMax!.toStringAsFixed(0)}';
    }
    if (r.budgetMin != null)
      return 'From $cur${r.budgetMin!.toStringAsFixed(0)}';
    return 'Up to $cur${r.budgetMax!.toStringAsFixed(0)}';
  }

  Widget _responsesSection() {
    if (_responsesLoading)
      return _sectionCard(
          child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator())));
    return _sectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('Responses',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        if (_responses.isNotEmpty)
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12)),
              child: Text(_responses.length.toString(),
                  style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500))),
        const Spacer(),
        IconButton(
            onPressed: _reloadResponses,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh responses')
      ]),
      const SizedBox(height: 8),
      if (_responses.isEmpty)
        Text(_canRespond ? 'Be the first to respond.' : 'No responses yet.',
            style: TextStyle(color: Colors.grey[600]))
      else
        ..._responses.take(5).map(_responseTile),
      if (_responses.length > 5)
        Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('+${_responses.length - 5} more (pagination coming)',
                style: TextStyle(color: Colors.grey[600], fontSize: 12)))
    ]));
  }

  Widget _responseTile(rest.ResponseModel r) {
    final myUid = RestAuthService.instance.currentUser?.uid;
    final isMine = myUid != null && r.userId == myUid;
    final busy = _updating.contains(r.id) || _deleting.contains(r.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMine ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: (isMine ? Colors.blue[100] : Colors.grey[200])!),
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
                      color: isMine ? Colors.blue[800] : null))),
          if (busy)
            const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2)),
          Text(_relativeTime(r.createdAt),
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          if (isMine && !busy)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit')
                  _openEditResponseSheet(r);
                else if (val == 'delete') _confirmDelete(r);
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
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
        ]
      ]),
    );
  }
}
