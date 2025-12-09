import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:setulink_app/services/price_calculator_service.dart';
import 'package:setulink_app/screens/citizen_home.dart';

class JobPostBudgetScreen extends StatefulWidget {
  final String serviceId;
  final Map<String, dynamic> serviceData;
  final String? craftizenId; // optional specific Craftizen
  final String jobTitle;
  final String jobDescription;
  final DateTime scheduledTime;

  const JobPostBudgetScreen({
    super.key,
    required this.serviceId,
    required this.serviceData,
    this.craftizenId,
    required this.jobTitle,
    required this.jobDescription,
    required this.scheduledTime,
  });

  @override
  State<JobPostBudgetScreen> createState() => _JobPostBudgetScreenState();
}

class _JobPostBudgetScreenState extends State<JobPostBudgetScreen> {
  int _selectedUnits = 1;
  double _calculatedPrice = 0;
  bool _isPeakTime = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calculatePrice();
  }

  void _calculatePrice() async {
    double price = await PriceCalculatorService.calculateServicePrice(
      serviceId: widget.serviceId,
      serviceData: widget.serviceData,
      units: _selectedUnits,
      isPeakTime: _isPeakTime,
    );
    setState(() => _calculatedPrice = price);
  }

  Future<void> _confirmBooking() async {
    setState(() => _isLoading = true);

    try {
      final priceData = await FirebaseFunctions.instance.httpsCallable('validateJobPrice').call({
        'serviceId': widget.serviceId,
        'units': _selectedUnits,
        'distanceKm': 10, // Mock distance
      });

      await FirebaseFirestore.instance.collection('jobs').add({
        'title': widget.jobTitle,
        'description': widget.jobDescription,
        'serviceId': widget.serviceId,
        'calculatedPrice': priceData.data['totalPrice'],
        'appCommission': priceData.data['appCommission'],
        'status': 'open',
        'scheduledTime': widget.scheduledTime,
      });

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Job posted successfully!')));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CitizenHome()), 
          (route) => false
        );
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to post job: $e')));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final breakdown = PriceCalculatorService.getPriceBreakdown(
      totalPrice: _calculatedPrice,
      serviceData: widget.serviceData,
    );
    
    return Scaffold(
      appBar: AppBar(title: const Text('Price Summary')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text('₹${_calculatedPrice.toStringAsFixed(0)}', 
                         style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                    const Text('Total Estimated Price'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (widget.serviceData['units'] != 'visit')
              Slider(
                value: _selectedUnits.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '$_selectedUnits ${widget.serviceData['units']}',
                onChanged: (value) {
                  setState(() => _selectedUnits = value.toInt());
                  _calculatePrice();
                },
              ),
            
            ExpansionTile(
              title: const Text('Price Breakdown'),
              children: breakdown.entries.map((e) => ListTile(
                title: Text(e.key.replaceAll('_', ' ').toUpperCase()),
                trailing: Text('₹${e.value.toStringAsFixed(0)}'),
              )).toList(),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 56),
              ),
              onPressed: _isLoading ? null : _confirmBooking,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('Book for ₹${_calculatedPrice.toStringAsFixed(0)}'),
            ),
          ],
        ),
      ),
    );
  }
}
