import 'package:flutter/material.dart';

import '../models/collection_alert.dart';
import '../services/backend_service.dart';
import '../services/device_identity_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/tensor_api_service.dart';
import 'add_collection_screen.dart';
import 'filters_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = FirestoreService();
  final _tensor = TensorApiService();
  final _backend = BackendService(baseUrl: const String.fromEnvironment('BACKEND_BASE_URL', defaultValue: 'https://your-backend.onrender.com'));
  String? _deviceId;
  String _apiKey = '';
  bool _live = false;

  @override
  void initState() {
    super.initState();
    _setup();
    WidgetsBinding.instance.addPostFrameCallback((_) => _welcome());
  }

  Future<void> _setup() async {
    final id = await DeviceIdentityService.getOrCreateId();
    final token = NotificationService.instance.fcmToken;
    if (token != null) {
      try {
        await _backend.registerDevice(deviceId: id, fcmToken: token, tensorApiKey: _apiKey.isEmpty ? null : _apiKey);
      } catch (_) {
        // Keep app usable even if backend is temporarily unreachable.
      }
    }
    if (mounted) setState(() => _deviceId = id);
  }

  Future<void> _welcome() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Welcome'),
        content: const Text('Instant Tensor NFT sales, bids & floor alerts on Solana'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Continue'))],
      ),
    );
  }

  Future<void> _addCollection() async {
    if (_deviceId == null) return;
    final slug = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const AddCollectionScreen()));
    if (slug == null || slug.isEmpty) return;
    var floor = 0.0;
    if (_apiKey.isNotEmpty) {
      floor = await _tensor.fetchFloorPrice(slug: slug, apiKey: _apiKey);
      _live = true;
    }
    final item = CollectionAlert(slug: slug, displayName: slug, floorPrice: floor);
    await _store.upsertCollection(_deviceId!, item);
    await _backend.upsertCollection(deviceId: _deviceId!, collection: item);
    if (mounted) setState(() {});
  }

  Future<void> _openFilters(CollectionAlert item) async {
    if (_deviceId == null) return;
    final updated = await Navigator.push<CollectionAlert>(context, MaterialPageRoute(builder: (_) => FiltersScreen(collection: item)));
    if (updated != null) {
      await _store.upsertCollection(_deviceId!, updated);
      await _backend.upsertCollection(deviceId: _deviceId!, collection: updated);
    }
  }

  Future<void> _setApiKey() async {
    final c = TextEditingController(text: _apiKey);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        title: const Text('Tensor API key'),
        content: TextField(controller: c, decoration: const InputDecoration(hintText: 'Paste from dev.tensor.trade')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () { setState(() => _apiKey = c.text.trim()); Navigator.pop(context); }, child: const Text('Save')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_deviceId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Tensor Alerts', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [TextButton(onPressed: _setApiKey, child: const Text('API Key'))],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00FF9F),
        foregroundColor: Colors.black,
        onPressed: _addCollection,
        label: const Text('Add', style: TextStyle(fontWeight: FontWeight.w800)),
        icon: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _status(),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<CollectionAlert>>(
              stream: _store.streamCollections(_deviceId!),
              builder: (_, snap) {
                final items = snap.data ?? const [];
                if (items.isEmpty) {
                  return const Center(child: Text('No collections yet', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Card(
                      color: const Color(0xFF121212),
                      child: ListTile(
                        onTap: () => _openFilters(item),
                        title: Text(item.displayName ?? item.slug, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
                        subtitle: Text('Floor ${item.floorPrice.toStringAsFixed(2)} SOL', style: const TextStyle(color: Color(0xFF00F0FF))),
                        trailing: Switch(
                          value: item.enabled,
                          activeColor: const Color(0xFF00FF9F),
                          onChanged: (v) async {
                            final updated = item.copyWith(enabled: v);
                            await _store.upsertCollection(_deviceId!, updated);
                            await _backend.upsertCollection(deviceId: _deviceId!, collection: updated);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _status() {
    final c = _live ? const Color(0xFF00FF9F) : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: const Color(0xFF121212), border: Border.all(color: c)),
      child: Text(_live ? 'Live' : 'Offline', style: TextStyle(color: c, fontWeight: FontWeight.w700)),
    );
  }
}
