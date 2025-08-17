import 'package:flutter/material.dart';
import '../../services/rest_auth_service.dart';
import '../../services/rest_request_service.dart' as rest;
import '../../screens/unified_request_response/unified_request_view_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final rest.RestRequestService _service = rest.RestRequestService.instance;
  bool _initialLoading = true;
  bool _fetching = false;
  int _page = 1;
  int _totalPages = 1;
  final List<rest.RequestModel> _requests = [];
  String _countryCode = 'LK';
  final ScrollController _scrollController = ScrollController();
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => _initialLoading = true);
    _page = 1;
    _totalPages = 1;
    _requests.clear();
    await _fetch();
    setState(() => _initialLoading = false);
  }

  Future<void> _fetch() async {
    if (_fetching) return;
    if (_page > _totalPages) return;
    setState(() => _fetching = true);
    try {
      final res = await _service.getRequests(
          countryCode: _countryCode, page: _page, limit: 20);
      if (res != null) {
        setState(() {
          _requests.addAll(res.requests);
          _totalPages = res.pagination.totalPages;
          _page++; // next page
        });
      }
    } catch (e) {
      debugPrint('Home fetch error: $e');
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  String _greetingName() {
    return RestAuthService.instance.currentUser?.displayName ?? 'Welcome';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_greetingName())),
      body: RefreshIndicator(
        onRefresh: _loadInitial,
        child: _initialLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: _requests.length + 1 + (_fetching ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i < _requests.length) return _requestTile(_requests[i]);
                  if (i == _requests.length) {
                    if (_page <= _totalPages) {
                      _fetch();
                      return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()));
                    }
                    return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                            child: Text(
                          _requests.isEmpty
                              ? 'No requests yet.'
                              : 'End of list',
                          style: TextStyle(color: Colors.grey[600]),
                        )));
                  }
                  return const SizedBox.shrink();
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: _creating ? null : _openCreateRequestSheet,
          icon: _creating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.add),
          label: Text(_creating ? 'Creating...' : 'New Request')),
    );
  }

  Widget _requestTile(rest.RequestModel r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => UnifiedRequestViewScreen(
                        requestId: r.id,
                      )));
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              r.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 4, children: [
              _chip(Icons.person, r.userName ?? 'User'),
              _chip(Icons.category, r.categoryName ?? r.categoryId),
              if (r.cityName != null) _chip(Icons.location_on, r.cityName!),
              _chip(Icons.access_time, _relativeTime(r.createdAt)),
              if (r.budgetMin != null || r.budgetMax != null)
                _chip(Icons.account_balance_wallet, _budgetLabel(r)),
            ])
          ]),
        ),
      ),
    );
  }

  String _budgetLabel(rest.RequestModel r) {
    final cur = r.currency ?? '';
    if (r.budgetMin != null && r.budgetMax != null) {
      if (r.budgetMin == r.budgetMax)
        return '$cur${r.budgetMin!.toStringAsFixed(0)}';
      return '$cur${r.budgetMin!.toStringAsFixed(0)}-${r.budgetMax!.toStringAsFixed(0)}';
    }
    if (r.budgetMin != null)
      return 'From $cur${r.budgetMin!.toStringAsFixed(0)}';
    if (r.budgetMax != null)
      return 'Up to $cur${r.budgetMax!.toStringAsFixed(0)}';
    return '—';
  }

  Widget _chip(IconData icon, String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12))
      ]));

  String _relativeTime(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  void _openCreateRequestSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final minController = TextEditingController();
    final maxController = TextEditingController();
    final currencyController = TextEditingController(text: 'LKR');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16),
        child: StatefulBuilder(builder: (ctx, setSheet) {
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10))),
            const Text('Create Request',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: TextField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Budget Min'),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: TextField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Budget Max'),
              )),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: currencyController,
              decoration: const InputDecoration(labelText: 'Currency'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                  onPressed: _creating
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final desc = descController.text.trim();
                          if (title.isEmpty || desc.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Title and description required')));
                            return;
                          }
                          final min = double.tryParse(
                              minController.text.trim().isEmpty
                                  ? ''
                                  : minController.text.trim());
                          final max = double.tryParse(
                              maxController.text.trim().isEmpty
                                  ? ''
                                  : maxController.text.trim());
                          setState(() => _creating = true);
                          setSheet(() {});
                          final created = await _service.createRequest(
                            rest.CreateRequestData(
                              title: title,
                              description: desc,
                              categoryId: 'general', // placeholder
                              countryCode: _countryCode,
                              budgetMin: min,
                              budgetMax: max,
                              currency: currencyController.text.trim(),
                            ),
                          );
                          if (created != null) {
                            if (mounted) {
                              Navigator.pop(ctx);
                              setState(() {
                                _requests.insert(0, created);
                              });
                              _scrollController.animateTo(0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Request created')));
                            }
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Failed to create')));
                            }
                          }
                          if (mounted) setState(() => _creating = false);
                        },
                  icon: _creating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_creating ? 'Creating...' : 'Create Request')),
            ),
            const SizedBox(height: 8),
            TextButton(
                onPressed: _creating ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            const SizedBox(height: 8),
          ]);
        }),
      ),
    );
  }
}
