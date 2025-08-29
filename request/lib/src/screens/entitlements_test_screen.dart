import 'package:flutter/material.dart';
import '../services/entitlements_se                        color: entitlements.isSubscribed 
                            ? Colors.amber 
                            : Colors.grey,ce.dart';

class EntitlementsTestScreen extends StatefulWidget {
  const EntitlementsTestScreen({super.key});

  @override
  State<EntitlementsTestScreen> createState() => _EntitlementsTestScreenState();
}

class _EntitlementsTestScreenState extends State<EntitlementsTestScreen> {
  EntitlementsSummary? _entitlements;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEntitlements();
  }

  Future<void> _loadEntitlements() async {
    setState(() => _loading = true);

    try {
      final summary = await EntitlementsService.getEntitlementsSummary();
      setState(() {
        _entitlements = summary;
        _loading = false;
      });
    } catch (e) {
      print('Error loading entitlements: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEntitlements,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entitlements == null
              ? const Center(child: Text('Failed to load entitlements'))
              : _buildEntitlementsInfo(),
    );
  }

  Widget _buildEntitlementsInfo() {
    final entitlements = _entitlements!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        entitlements.isSubscribed
                            ? Icons.star
                            : Icons.star_border,
                        color: entitlements.isSubscribed
                            ? Colors.gold
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entitlements.statusText,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Response Count Info
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline),
                      const SizedBox(width: 8),
                      Text(
                          'Responses this month: ${entitlements.responseCount}'),
                    ],
                  ),

                  if (!entitlements.hasUnlimitedResponses) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time),
                        const SizedBox(width: 8),
                        Text('Remaining: ${entitlements.remainingResponses}'),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Capabilities Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Capabilities',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildCapabilityRow(
                    'See Contact Details',
                    entitlements.canSeeContactDetails,
                    Icons.contact_phone,
                  ),
                  _buildCapabilityRow(
                    'Send Messages',
                    entitlements.canSendMessages,
                    Icons.message,
                  ),
                  _buildCapabilityRow(
                    'Respond to Requests',
                    entitlements.canRespond,
                    Icons.reply,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Upgrade Button (if free user)
          if (!entitlements.isSubscribed) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/membership');
                },
                icon: const Icon(Icons.upgrade),
                label: const Text('Upgrade Subscription'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],

          // Warning if capabilities limited
          if (!entitlements.canSeeContactDetails ||
              !entitlements.canSendMessages) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entitlements.isSubscribed
                            ? 'Some features may be limited by your plan'
                            : 'You\'ve used your free responses. Upgrade to continue accessing contact details and messaging.',
                        style: TextStyle(color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCapabilityRow(String title, bool enabled, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: enabled ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }
}
