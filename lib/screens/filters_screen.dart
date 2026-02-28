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
  late TextEditingController traitController;

  @override
  void initState() {
    super.initState();
    globalMute = !widget.collection.enabled;
    sales = widget.collection.salesAlerts;
    bids = widget.collection.bidAlerts;
    floorDrops = widget.collection.floorDropAlerts;
    minSale = widget.collection.minSalePrice;
    dropThreshold = widget.collection.floorDropThreshold;
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
}
