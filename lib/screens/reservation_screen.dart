import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/reservation_provider.dart';
import '../providers/auth_provider.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({super.key});
  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    Provider.of<ReservationProvider>(context, listen: false).loadReservationsForDate(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReservationProvider>(context);
    return Stack(children: [
      Column(children: [
        Container(padding: const EdgeInsets.all(16), color: Colors.blue.shade50, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () { setState(() { _selectedDate = _selectedDate.subtract(const Duration(days: 1)); provider.loadReservationsForDate(_selectedDate); }); }),
          GestureDetector(onTap: () async { final d = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2024), lastDate: DateTime(2030)); if (d != null) { setState(() { _selectedDate = d; provider.loadReservationsForDate(_selectedDate); }); } }, child: Text(DateFormat('EEEE, MMMM d').format(_selectedDate), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () { setState(() { _selectedDate = _selectedDate.add(const Duration(days: 1)); provider.loadReservationsForDate(_selectedDate); }); }),
        ])),
        Padding(padding: const EdgeInsets.all(8.0), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _l(Colors.green, 'Available'), _l(Colors.amber, 'Reserved'), _l(Colors.red, 'Past'), _l(Colors.blue, 'Prep'),
        ])),
        Expanded(child: ListView.builder(itemCount: 20, itemBuilder: (context, index) {
          final hour = 16 + (index ~/ 2); final minute = (index % 2) * 30;
          final displayHour = hour > 23 ? hour - 24 : hour;
          final period = hour >= 12 && hour < 24 ? 'PM' : 'AM';
          final time = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour, minute);
          final color = provider.getTimeSlotColor(time);
          final reservation = provider.getReservationAtTime(time);
          return GestureDetector(onTap: () {
            if (reservation != null) { _showDetails(reservation); }
            else if (color == Colors.green.withOpacity(0.3)) { _openAdd(time); }
          }, child: Container(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)), child: Row(children: [
            Text('${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Expanded(child: reservation != null ? Text(reservation['customerName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)) : Text(color == Colors.blue.withOpacity(0.5) ? 'Prep Time' : 'Available', style: TextStyle(color: Colors.grey.shade600))),
          ]))));
        })),
      ]),
      Positioned(bottom: 20, right: 20, child: FloatingActionButton(onPressed: () => _openAdd(null), backgroundColor: Colors.blue.shade700, child: const Icon(Icons.add, color: Colors.white, size: 30))),
    ]);
  }

  Widget _l(Color c, String t) => Row(children: [Container(width: 14, height: 14, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))), const SizedBox(width: 4), Text(t, style: const TextStyle(fontSize: 12))]);

  void _openAdd(DateTime? preset) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddReservationPage(selectedDate: _selectedDate, presetTime: preset))).then((_) {
      Provider.of<ReservationProvider>(context, listen: false).loadReservationsForDate(_selectedDate);
    });
  }

  void _showDetails(Map<String, dynamic> r) {
    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Reservation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade800)), const Divider(),
      Text('👤 ${r['customerName']}'), Text('🕐 ${DateFormat('hh:mm a').format(r['startTime'])} - ${DateFormat('hh:mm a').format(r['endTime'])}'),
      if (r['hasDrinks'] == true) Text('🥤 ${r['drinksDetails'] ?? 'Drinks'}'),
      if (r['hasFood'] == true) Text('🍽️ ${r['foodDetails'] ?? 'Food'}'),
      if (r['hasSpecialDecorations'] == true) Text('🎉 ${r['decoDetails'] ?? 'Decorations'}'),
      if (r['hasBirthdayCake'] == true) Text('🎂 ${r['cakeDetails'] ?? 'Cake'}'),
      if (r['specialNotes'] != null && r['specialNotes'].toString().isNotEmpty) Text('📝 ${r['specialNotes']}'),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: () { Provider.of<ReservationProvider>(context, listen: false).deleteReservation(r['id']); Navigator.pop(ctx); }, icon: const Icon(Icons.delete), label: const Text('Delete'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white)),
    ])));
  }
}

class AddReservationPage extends StatefulWidget {
  final DateTime selectedDate;
  final DateTime? presetTime;
  const AddReservationPage({super.key, required this.selectedDate, this.presetTime});
  @override
  State<AddReservationPage> createState() => _AddReservationPageState();
}

class _AddReservationPageState extends State<AddReservationPage> {
  final _name = TextEditingController(), _drinks = TextEditingController(), _food = TextEditingController(), _deco = TextEditingController(), _cake = TextEditingController(), _notes = TextEditingController();
  late DateTime _date;
  late TimeOfDay _time;
  int _dur = 2;
  bool _hasDrinks = false, _hasFood = false, _hasDeco = false, _hasCake = false;

  @override
  void initState() {
    super.initState();
    _date = widget.selectedDate;
    _time = widget.presetTime != null ? TimeOfDay(hour: widget.presetTime!.hour, minute: widget.presetTime!.minute) : const TimeOfDay(hour: 16, minute: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Reservation'), backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Customer Name *', border: OutlineInputBorder()), autofocus: true),
        const SizedBox(height: 16),
        ListTile(leading: const Icon(Icons.calendar_today), title: Text(DateFormat('dd/MM/yyyy').format(_date)), onTap: () async { final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime(2030)); if (d != null) setState(() => _date = d); }, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), tileColor: Colors.grey.shade100),
        ListTile(leading: const Icon(Icons.access_time), title: Text(_time.format(context)), onTap: () async { final t = await showTimePicker(context: context, initialTime: _time); if (t != null) setState(() => _time = t); }, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), tileColor: Colors.grey.shade100),
        ListTile(leading: const Icon(Icons.timer), title: Text('${(_dur * 0.5).toStringAsFixed(1)} hours'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: () => setState(() { if (_dur > 1) _dur--; }), icon: const Icon(Icons.remove_circle)), Text('$_dur'), IconButton(onPressed: () => setState(() { if (_dur < 20) _dur++; }), icon: const Icon(Icons.add_circle))]), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), tileColor: Colors.grey.shade100),
        const SizedBox(height: 16),
        const Text('Requirements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        SwitchListTile(title: const Text('🥤 Drinks'), value: _hasDrinks, onChanged: (v) => setState(() => _hasDrinks = v)), if (_hasDrinks) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(controller: _drinks, decoration: const InputDecoration(hintText: 'Drinks details...', border: OutlineInputBorder()))),
        SwitchListTile(title: const Text('🍽️ Food'), value: _hasFood, onChanged: (v) => setState(() => _hasFood = v)), if (_hasFood) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(controller: _food, decoration: const InputDecoration(hintText: 'Food details...', border: OutlineInputBorder()))),
        SwitchListTile(title: const Text('🎉 Decorations'), value: _hasDeco, onChanged: (v) => setState(() => _hasDeco = v)), if (_hasDeco) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(controller: _deco, decoration: const InputDecoration(hintText: 'Decoration details...', border: OutlineInputBorder()))),
        SwitchListTile(title: const Text('🎂 Cake'), value: _hasCake, onChanged: (v) => setState(() => _hasCake = v)), if (_hasCake) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(controller: _cake, decoration: const InputDecoration(hintText: 'Cake details...', border: OutlineInputBorder()))),
        const SizedBox(height: 16),
        TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Special Notes', border: OutlineInputBorder()), maxLines: 3),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () {
          if (_name.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter customer name'))); return; }
          final start = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
          Provider.of<ReservationProvider>(context, listen: false).addReservation({
            'customerName': _name.text, 'employeeName': Provider.of<AuthProvider>(context, listen: false).employeeName ?? 'Staff',
            'startTime': start, 'endTime': start.add(Duration(minutes: 30 * _dur)),
            'hasDrinks': _hasDrinks, 'drinksDetails': _drinks.text,
            'hasFood': _hasFood, 'foodDetails': _food.text,
            'hasSpecialDecorations': _hasDeco, 'decoDetails': _deco.text,
            'hasBirthdayCake': _hasCake, 'cakeDetails': _cake.text,
            'specialNotes': _notes.text,
          });
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Added!'), backgroundColor: Colors.green));
        }, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Save Reservation', style: TextStyle(fontSize: 18)))),
      ])),
    );
  }
}
