import 'package:flutter/material.dart';
import '../../services/rest_auth_service.dart';
import '../../services/rest_request_service.dart' as rest;
import '../../services/rest_category_service.dart';
import '../../services/rest_city_service.dart';
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
  final RestCategoryService _categoryService = RestCategoryService.instance;
  final RestCityService _cityService = RestCityService.instance;
  List<Category> _categories = [];
  List<Subcategory> _subcategories = [];
  List<City> _cities = [];
  String? _selectedCategoryId;
  String? _selectedSubcategoryId;
  String? _selectedCityId;
  // Search & filter state
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;
  int _searchPage = 1;
  int _searchTotalPages = 1;
  bool get _inSearchMode => _searchController.text.trim().isNotEmpty;
  bool _filterAcceptedOnly = false;
  DateTime? _lastSearchKeystroke;
  final Duration _debounceDuration = const Duration(milliseconds: 450);

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    setState(() => _initialLoading = true);
    // Preload categories & cities (fire and forget for speed)
    _preloadMeta();
    _page = 1;
    _totalPages = 1;
    _requests.clear();
    await _fetch();
    setState(() => _initialLoading = false);
  }

  Future<void> _preloadMeta() async {
    final cats = await _categoryService.getCategoriesWithCache(
        countryCode: _countryCode);
    final cities = await _cityService.getCities(countryCode: _countryCode);
    if (mounted)
      setState(() {
        _categories = cats;
        _cities = cities;
      });
  }

  Future<void> _fetch() async {
    if (_fetching) return;
    if (_inSearchMode) {
      if (_searching) return;
      if (_searchPage > _searchTotalPages) return;
    } else {
      if (_page > _totalPages) return;
    }
    setState(() => _fetching = true);
    try {
      if (_inSearchMode) {
        _searching = true;
        final res = await _service.searchRequests(
            query: _searchController.text.trim(),
            countryCode: _countryCode,
            page: _searchPage,
            limit: 20,
            categoryId: _selectedCategoryId,
            cityId: _selectedCityId,
            hasAccepted: _filterAcceptedOnly ? true : null);
        if (res != null) {
          setState(() {
            if (_searchPage == 1) _requests.clear();
            _requests.addAll(res.requests);
            _searchTotalPages = res.pagination.totalPages;
            _searchPage++;
          });
        }
      } else {
        final res = await _service.getRequests(
            countryCode: _countryCode,
            page: _page,
            limit: 20,
            categoryId: _selectedCategoryId,
            subcategoryId: _selectedSubcategoryId,
            cityId: _selectedCityId,
            hasAccepted: _filterAcceptedOnly ? true : null);
        if (res != null) {
          setState(() {
            _requests.addAll(res.requests);
            _totalPages = res.pagination.totalPages;
            _page++; // next page
          });
        }
      }
    } catch (e) {
      debugPrint('Home fetch error: $e');
    } finally {
      if (mounted) setState(() => _fetching = false);
      _searching = false;
    }
  }

  String _greetingName() {
    return RestAuthService.instance.currentUser?.displayName ?? 'Welcome';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_greetingName()),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildSearchBar(),
          ),
        ),
        actions: [
          if (_inSearchMode)
            IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  _resetPagination(keepFilters: true);
                  _fetch();
                  setState(() {});
                },
                icon: const Icon(Icons.close))
        ],
      ),
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

  Widget _buildSearchBar() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (_) => _debouncedSearch(),
              onSubmitted: (_) => _triggerSearch(),
              decoration: InputDecoration(
                  hintText: 'Search requests...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none)),
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            tooltip: 'Filters',
            icon: const Icon(Icons.filter_alt),
            onSelected: (val) {},
            itemBuilder: (ctx) => [
              PopupMenuItem(
                  enabled: false,
                  child: SizedBox(
                      width: 240,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Filters',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          _quickFilterChips(),
                          const Divider(height: 20),
                          _filterDropdowns(),
                          const SizedBox(height: 12),
                          Row(children: [
                            Checkbox(
                                value: _filterAcceptedOnly,
                                onChanged: (v) {
                                  setState(
                                      () => _filterAcceptedOnly = v ?? false);
                                }),
                            const Expanded(
                                child: Text(
                                    'Show only requests with accepted response',
                                    style: TextStyle(fontSize: 12)))
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _clearFilters();
                                },
                                child: const Text('Clear')),
                            const Spacer(),
                            FilledButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _applyFilters();
                                },
                                child: const Text('Apply'))
                          ])
                        ],
                      )))
            ],
          )
        ]),
        if (_selectedCategoryId != null ||
            _selectedCityId != null ||
            _selectedSubcategoryId != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(spacing: 6, children: [
              if (_selectedCategoryId != null)
                _activeFilterChip(
                    label: _categories
                        .firstWhere((c) => c.id == _selectedCategoryId,
                            orElse: () => Category(
                                id: '',
                                name: 'Category',
                                countryCode: _countryCode,
                                isActive: true,
                                displayOrder: 0,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now()))
                        .name,
                    onRemove: () {
                      setState(() => _selectedCategoryId = null);
                      _applyFilters();
                    }),
              if (_selectedSubcategoryId != null)
                _activeFilterChip(
                    label: _subcategories
                        .firstWhere((s) => s.id == _selectedSubcategoryId,
                            orElse: () => Subcategory(
                                id: '',
                                name: 'Sub',
                                categoryId: _selectedCategoryId ?? '',
                                isActive: true,
                                displayOrder: 0,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now()))
                        .name,
                    onRemove: () {
                      setState(() => _selectedSubcategoryId = null);
                      _applyFilters();
                    }),
              if (_selectedCityId != null)
                _activeFilterChip(
                    label: _cities
                        .firstWhere((c) => c.id == _selectedCityId,
                            orElse: () => City(
                                id: '',
                                name: 'City',
                                countryCode: _countryCode,
                                isActive: true,
                                createdAt: DateTime.now(),
                                updatedAt: DateTime.now()))
                        .name,
                    onRemove: () {
                      setState(() => _selectedCityId = null);
                      _applyFilters();
                    }),
            ]),
          )
      ],
    );
  }

  Widget _activeFilterChip(
      {required String label, required VoidCallback onRemove}) {
    return Chip(
      label: Text(label, overflow: TextOverflow.ellipsis),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onRemove,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _quickFilterChips() {
    return Wrap(runSpacing: 6, spacing: 6, children: [
      if (_selectedCategoryId != null)
        ActionChip(
            label: const Text('Clear Category'),
            onPressed: () => setState(() => _selectedCategoryId = null)),
      if (_selectedCityId != null)
        ActionChip(
            label: const Text('Clear City'),
            onPressed: () => setState(() => _selectedCityId = null)),
      if (_selectedSubcategoryId != null)
        ActionChip(
            label: const Text('Clear Sub'),
            onPressed: () => setState(() => _selectedSubcategoryId = null)),
    ]);
  }

  Widget _filterDropdowns() {
    return Column(children: [
      DropdownButtonFormField<String>(
        isDense: true,
        value: _selectedCategoryId,
        items: _categories
            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
            .toList(),
        onChanged: (v) async {
          setState(() {
            _selectedCategoryId = v;
            _selectedSubcategoryId = null;
            _subcategories = [];
          });
          if (v != null) {
            final subs =
                await _categoryService.getSubcategoriesWithCache(categoryId: v);
            if (mounted) setState(() => _subcategories = subs);
          }
        },
        decoration: const InputDecoration(labelText: 'Category'),
      ),
      if (_subcategories.isNotEmpty)
        DropdownButtonFormField<String>(
          isDense: true,
          value: _selectedSubcategoryId,
          items: _subcategories
              .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
              .toList(),
          onChanged: (v) => setState(() => _selectedSubcategoryId = v),
          decoration: const InputDecoration(labelText: 'Subcategory'),
        ),
      DropdownButtonFormField<String>(
        isDense: true,
        value: _selectedCityId,
        items: _cities
            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
            .toList(),
        onChanged: (v) => setState(() => _selectedCityId = v),
        decoration: const InputDecoration(labelText: 'City'),
      ),
    ]);
  }

  void _triggerSearch() {
    _resetSearchPagination();
    _fetch();
  }

  void _applyFilters() {
    _resetPagination(keepFilters: true);
    _fetch();
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedSubcategoryId = null;
      _selectedCityId = null;
    });
    _applyFilters();
  }

  void _resetPagination({bool keepFilters = false}) {
    _page = 1;
    _totalPages = 1;
    _requests.clear();
    if (!_inSearchMode) {
      _searchPage = 1;
      _searchTotalPages = 1;
    }
  }

  void _resetSearchPagination() {
    _searchPage = 1;
    _searchTotalPages = 1;
    _requests.clear();
  }

  void _debouncedSearch() {
    _lastSearchKeystroke = DateTime.now();
    Future.delayed(_debounceDuration, () {
      if (!mounted) return;
      if (_lastSearchKeystroke != null &&
          DateTime.now().difference(_lastSearchKeystroke!) >=
              _debounceDuration) {
        _triggerSearch();
      }
    });
  }

  Widget _requestTile(rest.RequestModel r) {
    final isAccepted = r.acceptedResponseId != null;
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
            Row(children: [
              Expanded(
                  child: Text(r.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600))),
              if (isAccepted)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.verified, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Accepted',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold))
                    ]))
            ]),
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
    // Ensure meta loaded
    if (_categories.isEmpty) {
      _preloadMeta();
    }
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
            _categoryDropdown(setSheet),
            if (_subcategories.isNotEmpty) const SizedBox(height: 12),
            if (_subcategories.isNotEmpty) _subcategoryDropdown(setSheet),
            const SizedBox(height: 12),
            _cityDropdown(setSheet),
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
                          if (_selectedCategoryId == null ||
                              _selectedCityId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Select category & city')));
                            setState(() => _creating = false);
                            setSheet(() {});
                            return;
                          }
                          final created = await _service
                              .createRequest(rest.CreateRequestData(
                            title: title,
                            description: desc,
                            categoryId: _selectedCategoryId!,
                            subcategoryId: _selectedSubcategoryId,
                            locationCityId: _selectedCityId,
                            countryCode: _countryCode,
                            budgetMin: min,
                            budgetMax: max,
                            currency: currencyController.text.trim(),
                          ));
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

  Widget _categoryDropdown(StateSetter setSheet) {
    return DropdownButtonFormField<String>(
      value: _selectedCategoryId,
      items: _categories
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: (val) async {
        setState(() {
          _selectedCategoryId = val;
          _selectedSubcategoryId = null;
          _subcategories = [];
        });
        setSheet(() {});
        if (val != null) {
          final subs =
              await _categoryService.getSubcategoriesWithCache(categoryId: val);
          if (mounted) {
            setState(() {
              _subcategories = subs;
            });
            setSheet(() {});
          }
        }
      },
      decoration: const InputDecoration(labelText: 'Category'),
    );
  }

  Widget _subcategoryDropdown(StateSetter setSheet) {
    return DropdownButtonFormField<String>(
      value: _selectedSubcategoryId,
      items: _subcategories
          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedSubcategoryId = val;
        });
        setSheet(() {});
      },
      decoration: const InputDecoration(labelText: 'Subcategory (optional)'),
    );
  }

  Widget _cityDropdown(StateSetter setSheet) {
    return DropdownButtonFormField<String>(
      value: _selectedCityId,
      items: _cities
          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
          .toList(),
      onChanged: (val) {
        setState(() {
          _selectedCityId = val;
        });
        setSheet(() {});
      },
      decoration: const InputDecoration(labelText: 'City'),
    );
  }
}
