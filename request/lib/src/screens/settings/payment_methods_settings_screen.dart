import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/payment_method_selector.dart';
import '../../services/payment_methods_service.dart';

class PaymentMethodsSettingsScreen extends StatefulWidget {
  const PaymentMethodsSettingsScreen({super.key});

  @override
  State<PaymentMethodsSettingsScreen> createState() =>
      _PaymentMethodsSettingsScreenState();
}

class _PaymentMethodsSettingsScreenState
    extends State<PaymentMethodsSettingsScreen> {
  List<String> _selected = [];
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
      if (user != null) {
        final selected =
            await PaymentMethodsService.getSelectedForBusiness(user.uid);
        _selected = selected;
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
      if (ok) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Methods'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose which payment methods you accept. This is shown on your listings.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: PaymentMethodSelector(
                        selectedPaymentMethods: _selected,
                        onPaymentMethodsChanged: (ids) =>
                            setState(() => _selected = ids),
                        multiSelect: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
