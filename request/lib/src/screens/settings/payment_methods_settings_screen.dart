import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/payment_methods_service.dart';
import '../../services/rest_support_services.dart';

class PaymentMethodsSettingsScreen extends StatefulWidget {
  const PaymentMethodsSettingsScreen({super.key});

  @override
  State<PaymentMethodsSettingsScreen> createState() =>
      _PaymentMethodsSettingsScreenState();
}

class _PaymentMethodsSettingsScreenState
    extends State<PaymentMethodsSettingsScreen> {
  List<String> _selected = [];
  List<String> _initialSelected = [];
  List<PaymentMethod> _allMethods = [];
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final user = AuthService.instance.currentUser;
      // Load country methods for current country (always)
      final countryCode = CountryService.instance.getCurrentCountryCode();
      _allMethods =
          await PaymentMethodsService.getPaymentMethodsForCountry(countryCode);

      // Load selected only if user available
      if (user != null) {
        _selected =
            await PaymentMethodsService.getSelectedForBusiness(user.uid);
        _initialSelected = List.from(_selected);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final user = AuthService.instance.currentUser;
      if (user == null) return;
      final ok = await PaymentMethodsService.setSelectedForBusiness(
          user.uid, _selected);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Saved payment methods' : 'Failed to save'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ));
      if (ok) {
        _initialSelected = List.from(_selected);
        setState(() {});
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _dirty {
    if (_selected.length != _initialSelected.length) return true;
    final a = Set.of(_selected);
    final b = Set.of(_initialSelected);
    return a.difference(b).isNotEmpty;
  }

  void _remove(String id) {
    setState(() {
      _selected.remove(id);
    });
  }

  Future<void> _openAddSheet() async {
    if (_allMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No payment methods available for your country.')),
      );
      return;
    }
    final notSelected =
        _allMethods.where((m) => !_selected.contains(m.id)).toList();
    if (notSelected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All available methods are already added.')),
      );
      return;
    }
    final added = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final localSelected = <String>{};
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return StatefulBuilder(builder: (context, setLocal) {
              return Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 12),
                  const Text('Add Payment Methods',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      itemCount: notSelected.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final m = notSelected[index];
                        final isPicked = localSelected.contains(m.id);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            backgroundImage: (m.imageUrl.isNotEmpty)
                                ? NetworkImage(m.imageUrl)
                                : null,
                            child: (m.imageUrl.isEmpty)
                                ? const Icon(Icons.payment, color: Colors.grey)
                                : null,
                          ),
                          title: Text(m.name),
                          subtitle: m.category.isNotEmpty
                              ? Text(m.category.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey))
                              : null,
                          trailing: Checkbox(
                            value: isPicked,
                            onChanged: (v) {
                              if (v == true) {
                                localSelected.add(m.id);
                              } else {
                                localSelected.remove(m.id);
                              }
                              setLocal(() {});
                            },
                          ),
                          onTap: () {
                            if (isPicked) {
                              localSelected.remove(m.id);
                            } else {
                              localSelected.add(m.id);
                            }
                            setLocal(() {});
                          },
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: localSelected.isEmpty
                                ? null
                                : () => Navigator.pop(
                                    context, localSelected.toList()),
                            icon: const Icon(Icons.add),
                            label: const Text('Add'),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              );
            });
          },
        );
      },
    );
    if (added != null && added.isNotEmpty) {
      setState(() {
        _selected.addAll(added.where((id) => !_selected.contains(id)));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMethods =
        _allMethods.where((m) => _selected.contains(m.id)).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add',
            onPressed: _loading ? null : _openAddSheet,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add your payment methods',
                      style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  if (selectedMethods.isEmpty) ...[
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.credit_card_off,
                                size: 56, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('No payment methods added',
                                style: TextStyle(color: Colors.grey[600])),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _openAddSheet,
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedMethods.map((m) {
                        return Chip(
                          avatar: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            backgroundImage: (m.imageUrl.isNotEmpty)
                                ? NetworkImage(m.imageUrl)
                                : null,
                            child: (m.imageUrl.isEmpty)
                                ? const Icon(Icons.payment,
                                    size: 16, color: Colors.grey)
                                : null,
                          ),
                          label: Text(m.name),
                          onDeleted: () => _remove(m.id),
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _dirty && !_saving ? _save : null,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10)),
                        child: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Save'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
