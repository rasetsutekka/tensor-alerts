import 'package:flutter/material.dart';

import '../models/collection_alert.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key, required this.collection});
  final CollectionAlert collection;

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late bool globalMute;
  late bool sales;
  late bool bids;
  late bool floorDrops;
  late double minSale;
  late double dropThreshold;
  late double floorMovePct;
  late double floorMoveSol;
  late int minIntervalMins;
  late int maxAlertsHour;
  late TextEditingController traitController;

  static const _intervalOptions = [15, 30, 45, 60, 120, 180];
  static const _maxPerHourOptions = [2, 4, 6];

  @override
  void initState() {
    super.initState();
    globalMute = !widget.collection.enabled;
    sales = widget.collection.salesAlerts;
    bids = widget.collection.bidAlerts;
    floorDrops = widget.collection.floorDropAlerts;
    minSale = widget.collection.minSalePrice;
    dropThreshold = widget.collection.floorDropThreshold;
    floorMovePct = widget.collection.floorMovePercentThreshold;
    floorMoveSol = widget.collection.floorMoveSolThreshold;
    minIntervalMins = widget.collection.minIntervalMinutes;
    maxAlertsHour = widget.collection.maxAlertsPerHour;
    traitController = TextEditingController(text: widget.collection.traitContains);
  }

  @override
  void dispose() {
    traitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.collection.displayName ?? widget.collection.slug)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _toggle('Mute all alerts', globalMute, (v) => setState(() => globalMute = v)),
          _toggle('Sales alerts', sales, (v) => setState(() => sales = v)),
          _toggle('Bid alerts', bids, (v) => setState(() => bids = v)),
          _toggle('Floor drop alerts', floorDrops, (v) => setState(() => floorDrops = v)),
          const SizedBox(height: 16),
          Text('Minimum sale: ${minSale.toStringAsFixed(2)} SOL', style: const TextStyle(fontWeight: FontWeight.w700)),
          Slider(value: minSale, min: 0, max: 100, divisions: 100, activeColor: const Color(0xFF00F0FF), onChanged: (v) => setState(() => minSale = v)),
          Text('Floor drop threshold: ${dropThreshold.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w700)),
          Slider(value: dropThreshold, min: 0, max: 100, divisions: 100, activeColor: const Color(0xFF8A2BE2), onChanged: (v) => setState(() => dropThreshold = v)),
          const SizedBox(height: 10),
          Text('Floor move trigger: ${floorMovePct.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w700)),
          Slider(value: floorMovePct, min: 0, max: 20, divisions: 80, activeColor: const Color(0xFF00FF9F), onChanged: (v) => setState(() => floorMovePct = v)),
          Text('Floor move trigger: ${floorMoveSol.toStringAsFixed(2)} SOL', style: const TextStyle(fontWeight: FontWeight.w700)),
          Slider(value: floorMoveSol, min: 0, max: 10, divisions: 100, activeColor: const Color(0xFF00F0FF), onChanged: (v) => setState(() => floorMoveSol = v)),
          const SizedBox(height: 12),
          _dropdownCard<int>(
            label: 'Minimum interval between alerts',
            value: minIntervalMins,
            items: _intervalOptions,
            text: (v) => '$v min',
            onChanged: (v) => setState(() => minIntervalMins = v),
          ),
          const SizedBox(height: 10),
          _dropdownCard<int>(
            label: 'Max alerts per hour',
            value: maxAlertsHour,
            items: _maxPerHourOptions,
            text: (v) => '$v / hr',
            onChanged: (v) => setState(() => maxAlertsHour = v),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: traitController,
            decoration: InputDecoration(
              labelText: 'Only alert if trait contains…',
              filled: true,
              fillColor: const Color(0xFF121212),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00FF9F), foregroundColor: Colors.black),
            onPressed: () => Navigator.pop(
              context,
              widget.collection.copyWith(
                enabled: !globalMute,
                salesAlerts: sales,
                bidAlerts: bids,
                floorDropAlerts: floorDrops,
                minSalePrice: minSale,
                floorDropThreshold: dropThreshold,
                floorMovePercentThreshold: floorMovePct,
                floorMoveSolThreshold: floorMoveSol,
                minIntervalMinutes: minIntervalMins,
                maxAlertsPerHour: maxAlertsHour,
                traitContains: traitController.text.trim(),
              ),
            ),
            child: const Padding(padding: EdgeInsets.all(14), child: Text('Save', style: TextStyle(fontWeight: FontWeight.w800))),
          )
        ],
      ),
    );
  }

  Widget _toggle(String title, bool value, ValueChanged<bool> onChanged) => Card(
        color: const Color(0xFF121212),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF00FF9F),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      );

  Widget _dropdownCard<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) text,
    required ValueChanged<T> onChanged,
  }) {
    return Card(
      color: const Color(0xFF121212),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
            DropdownButton<T>(
              value: value,
              underline: const SizedBox.shrink(),
              items: items.map((e) => DropdownMenuItem<T>(value: e, child: Text(text(e)))).toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
