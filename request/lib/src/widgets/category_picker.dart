import 'package:flutter/material.dart';
import '../services/rest_category_service.dart';

// Simple data holder for module options
class _ModuleOption {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  _ModuleOption(this.key, this.label, this.icon, this.color);
}

class CategoryPicker extends StatefulWidget {
  final String requestType; // 'product'|'service' or convenience module key
  final String?
      module; // optional module filter; if null and requestType is a module, it's inferred
  final ScrollController scrollController;
  const CategoryPicker(
      {super.key,
      required this.requestType,
      this.module,
      required this.scrollController});
  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  bool _isLoading = true;
  String? _selectedMain;
  String?
      _moduleOverride; // chosen module when type=service and module not provided
  final Map<String, List<String>> _categories = {}; // name -> sub names
  final Map<String, String> _categoryNameToId = {}; // name -> id
  final Map<String, Map<String, String>> _subcategoryNameToId =
      {}; // cat name -> (sub name -> id)
  bool _isClosing = false;
  bool _showAll = false; // developer helper to view all backend categories

  // Cache last debug stats
  int _totalBackend = 0;
  int _explicitMatches = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() => _isLoading = true);
      final rest = RestCategoryService.instance;

      // Filter by type and optional module
      String t = widget.requestType.toLowerCase();
      String? m = widget.module?.toLowerCase();
      // If a local override was chosen, prefer it
      if (_moduleOverride != null && _moduleOverride!.isNotEmpty) {
        m = _moduleOverride;
        t = (m == 'item' || m == 'rent') ? 'product' : 'service';
      }
      if (t == 'rental') {
        t = 'product';
        m = 'rent';
      }
      if (t == 'jobs') {
        t = 'service';
        m = 'hiring';
      }
      if (m == 'rental') m = 'rent';
      if (m == 'jobs') m = 'hiring';

      // If service and no module chosen, stop loading and let UI show module chooser
      if (t == 'service' && (m == null || m.isEmpty)) {
        setState(() => _isLoading = false);
        return;
      }

      final all = await rest.getCategoriesWithCache(type: t, module: m);
      _totalBackend = all.length;
      _categoryNameToId.clear();
      _subcategoryNameToId.clear();

      // Categories are already filtered by type from the backend, so use them directly
      final listToUse = all;
      _explicitMatches = all.length;
      _categories.clear();

      for (final cat in listToUse) {
        _categoryNameToId[cat.name] = cat.id;
        final subs = await rest.getSubcategoriesWithCache(categoryId: cat.id);
        if (subs.isEmpty) {
          _categories.putIfAbsent(cat.name, () => []);
        } else {
          _categories[cat.name] = subs.map((s) => s.name).toList();
          for (final s in subs) {
            _subcategoryNameToId.putIfAbsent(cat.name, () => {});
            _subcategoryNameToId[cat.name]![s.name] = s.id;
          }
        }
      }
      if (mounted) setState(() => _isLoading = false);
      debugPrint(
          'CategoryPicker debug: totalBackend=$_totalBackend explicitMatches=$_explicitMatches type=${widget.requestType} module=${widget.module} showing=${_categories.length} (showAll=$_showAll)');
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('CategoryPicker error: $e');
    }
  }

  void _returnSelection({required String category, String? subcategory}) {
    if (_isClosing) return;
    _isClosing = true;
    final map = <String, String>{'category': category};
    final cid = _categoryNameToId[category];
    if (cid != null) map['categoryId'] = cid;
    if (subcategory != null) {
      map['subcategory'] = subcategory;
      final sid = _subcategoryNameToId[category]?[subcategory];
      if (sid != null) map['subcategoryId'] = sid;
    }
    Navigator.of(context).maybePop(map);
  }

  @override
  Widget build(BuildContext context) {
    final String t = widget.requestType.toLowerCase();
    final bool needsModule = (t == 'service') &&
        ((_moduleOverride == null || _moduleOverride!.isEmpty) &&
            (widget.module == null || widget.module!.isEmpty));

    return Material(
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : needsModule
                    ? _buildModuleChooser()
                    : (_categories.isEmpty
                        ? _buildEmpty()
                        : (_selectedMain == null
                            ? _buildMainList()
                            : _buildSubList(_selectedMain!))),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleChooser() {
    // Service modules to pick
    final modules = <_ModuleOption>[
      _ModuleOption('delivery', 'Delivery', Icons.local_shipping,
          const Color(0xFFF97316)),
      _ModuleOption(
          'ride', 'Ride', Icons.directions_car, const Color(0xFF06B6D4)),
      _ModuleOption('tours', 'Tours', Icons.flight, const Color(0xFF9333EA)),
      _ModuleOption(
          'events', 'Events', Icons.celebration, const Color(0xFFF59E0B)),
      _ModuleOption('construction', 'Construction', Icons.construction,
          const Color(0xFF8D6E63)),
      _ModuleOption(
          'education', 'Education', Icons.school, const Color(0xFF10B981)),
      _ModuleOption('hiring', 'Hiring', Icons.work, const Color(0xFF0EA5E9)),
      _ModuleOption(
          'other', 'Other', Icons.more_horiz, const Color(0xFF64748B)),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose a service module',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 3.6,
              children: modules
                  .map((m) => _ModuleChip(
                        label: m.label,
                        color: m.color,
                        icon: m.icon,
                        onTap: () {
                          setState(() {
                            _moduleOverride = m.key;
                          });
                          _load();
                        },
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Small chip-like tile for module selection
  Widget _ModuleChip(
      {required String label,
      required Color color,
      required IconData icon,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // (class moved to top-level)

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_selectedMain != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedMain = null),
            ),
          Expanded(
            child: Text(
              _selectedMain ?? 'Select a Category',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _load,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('No categories for ${widget.requestType}',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            'Backend total: $_totalBackend  Explicit matches: $_explicitMatches',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (!_showAll && _totalBackend > 0 && _explicitMatches == 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton(
                onPressed: () {
                  setState(() => _showAll = true);
                  _load();
                },
                child: const Text('Show All Backend Categories'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMainList() {
    final names = _categories.keys.toList()..sort();
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: names.length,
      itemBuilder: (context, i) {
        final name = names[i];
        final subCount = _categories[name]?.length ?? 0;
        return ListTile(
          leading: const Icon(Icons.folder),
          title: Text(name),
          subtitle: Text('$subCount subcategories'),
          trailing: subCount > 0 ? const Icon(Icons.chevron_right) : null,
          onTap: () {
            if (subCount > 0) {
              setState(() => _selectedMain = name);
            } else {
              _returnSelection(category: name);
            }
          },
        );
      },
    );
  }

  Widget _buildSubList(String main) {
    final subs = _categories[main] ?? [];
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: subs.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return ListTile(
            leading: const Icon(Icons.select_all),
            title: Text('All $main'),
            onTap: () => _returnSelection(category: main),
          );
        }
        final sub = subs[i - 1];
        return ListTile(
          leading: const Icon(Icons.subdirectory_arrow_right),
          title: Text(sub),
          onTap: () => _returnSelection(category: main, subcategory: sub),
        );
      },
    );
  }
}
