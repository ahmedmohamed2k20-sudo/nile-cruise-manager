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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReservationProvider>(context, listen: false).loadReservationsForDate(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ReservationProvider>(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                    provider.loadReservationsForDate(_selectedDate);
                  });
                },
              ),
              Text(DateFormat('EEEE, MMMM d').format(_selectedDate),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(const Duration(days: 1));
                    provider.loadReservationsForDate(_selectedDate);
                  });
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _legend(Colors.green, 'Available'),
              _legend(Colors.amber, 'Reserved'),
              _legend(Colors.red, 'Past'),
              _legend(Colors.blue, 'Prep'),
            ],
          ),
        ),
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: 20,
                  itemBuilder: (context, index) {
                    final hour = 16 + (index ~/ 2);
                    final minute = (index % 2) * 30;
                    final displayHour = hour > 23 ? hour - 24 : hour;
                    final period = hour >= 12 && hour < 24 ? 'PM' : 'AM';
                    final time = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, hour, minute);
                    final color = provider.getTimeSlotColor(time);
                    final reservation = provider.getReservationAtTime(time);
                    
                    return GestureDetector(
                      onTap: () {
                        if (reservation != null) {
                          _showDetails(reservation);
                        } else if (color == Colors.green.withOpacity(0.3)) {
                          _showAdd(time);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: color.withOpacity(0.8)),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: reservation != null
                                  ? Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(reservation['customerName'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                        if (reservation['specialNotes'] != null)
                                          Text(reservation['specialNotes'],
                                              style: const TextStyle(fontSize: 12),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis),
                                      ],
                                    )
                                  : Text(
                                      color == Colors.blue.withOpacity(0.5) ? 'Preparation' : 'Tap to Reserve',
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                            ),
                            if (reservation != null) const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _legend(Color c, String t) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 4),
        Text(t, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  void _showDetails(Map<String, dynamic> r) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Reservation Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
              const Divider(),
              Text('Customer: ${r['customerName']}'),
              Text('Employee: ${r['employeeName']}'),
              Text('Time: ${DateFormat('hh:mm a').format(r['startTime'])} - ${DateFormat('hh:mm a').format(r['endTime'])}'),
              if (r['hasDrinks'] == true) const Text('Drinks: Yes'),
              if (r['hasFood'] == true) const Text('Food: Yes'),
              if (r['hasSpecialDecorations'] == true) const Text('Decorations: Yes'),
              if (r['hasBirthdayCake'] == true) const Text('Cake: Yes'),
              if (r['specialNotes'] != null) Text('Notes: ${r['specialNotes']}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showEdit(r);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Provider.of<ReservationProvider>(context, listen: false).deleteReservation(r['id']);
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAdd(DateTime startTime) {
    final nameCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool drinks = false, food = false, deco = false, cake = false;
    int dur = 1;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              title: const Text('New Reservation'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name')),
                    Row(
                      children: [
                        const Text('Duration: '),
                        IconButton(
                            onPressed: () => setSt(() => dur = dur > 1 ? dur - 1 : 1),
                            icon: const Icon(Icons.remove)),
                        Text('${(dur * 0.5).toStringAsFixed(1)} hrs'),
                        IconButton(
                            onPressed: () => setSt(() => dur < 10 ? dur + 1 : 10),
                            icon: const Icon(Icons.add)),
                      ],
                    ),
                    CheckboxListTile(
                        title: const Text('Drinks'), value: drinks, onChanged: (v) => setSt(() => drinks = v ?? false)),
                    CheckboxListTile(
                        title: const Text('Food'), value: food, onChanged: (v) => setSt(() => food = v ?? false)),
                    CheckboxListTile(
                        title: const Text('Decorations'), value: deco, onChanged: (v) => setSt(() => deco = v ?? false)),
                    CheckboxListTile(
                        title: const Text('Birthday Cake'), value: cake, onChanged: (v) => setSt(() => cake = v ?? false)),
                    TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.isEmpty) return;
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    Provider.of<ReservationProvider>(context, listen: false).addReservation({
                      'customerName': nameCtrl.text,
                      'employeeName': auth.employeeName ?? 'Unknown',
                      'startTime': startTime,
                      'endTime': startTime.add(Duration(minutes: 30 * dur)),
                      'hasDrinks': drinks,
                      'hasFood': food,
                      'hasSpecialDecorations': deco,
                      'hasBirthdayCake': cake,
                      'specialNotes': notesCtrl.text,
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEdit(Map<String, dynamic> r) {
    final nameCtrl = TextEditingController(text: r['customerName']);
    final notesCtrl = TextEditingController(text: r['specialNotes'] ?? '');
    bool drinks = r['hasDrinks'] ?? false;
    bool food = r['hasFood'] ?? false;
    bool deco = r['hasSpecialDecorations'] ?? false;
    bool cake = r['hasBirthdayCake'] ?? false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            return AlertDialog(
              title: const Text('Edit Reservation'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name')),
                    CheckboxListTile(title: const Text('Drinks'), value: drinks, onChanged: (v) => setSt(() => drinks = v ?? false)),
                    CheckboxListTile(title: const Text('Food'), value: food, onChanged: (v) => setSt(() => food = v ?? false)),
                    CheckboxListTile(title: const Text('Decorations'), value: deco, onChanged: (v) => setSt(() => deco = v ?? false)),
                    CheckboxListTile(title: const Text('Cake'), value: cake, onChanged: (v) => setSt(() => cake = v ?? false)),
                    TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes'), maxLines: 2),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    Provider.of<ReservationProvider>(context, listen: false).updateReservation(r['id'], {
                      'customerName': nameCtrl.text,
                      'hasDrinks': drinks,
                      'hasFood': food,
                      'hasSpecialDecorations': deco,
                      'hasBirthdayCake': cake,
                      'specialNotes': notesCtrl.text,
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
