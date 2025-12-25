import 'package:cloud_firestore/cloud_firestore.dart';

class PriceCalculatorService {
  // Base commission rate
  static const double _baseCommissionRate = 0.10; // 10%

  // Peak time surcharge (e.g., for bookings made during evenings or weekends)
  static const double _peakTimeSurcharge = 1.20; // 20% surcharge

  /// Fetches the list of predefined problems for a given service from Firestore.
  static Future<List<QueryDocumentSnapshot>> getProblemsForService(String serviceId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('services')
          .doc(serviceId)
          .collection('problems')
          .get();
      return querySnapshot.docs;
    } catch (e) {
      print('Error fetching problems for service $serviceId: $e');
      return [];
    }
  }

  /// Calculates the total price based on a selected problem.
  /// This is a local calculation and does not require a paid Firebase plan.
  static Future<double> calculateServicePrice({
    required Map<String, dynamic> problemData,
    bool isPeakTime = false,
  }) async {
    // Get the price from the selected problem data.
    double basePrice = (problemData['price'] as num?)?.toDouble() ?? 0.0;

    double totalPrice = basePrice;

    // Apply a surcharge for peak time bookings.
    if (isPeakTime) {
      totalPrice *= _peakTimeSurcharge;
    }

    return totalPrice;
  }

  /// Calculates the platform commission from the total price.
  /// This is also a local calculation.
  static double getCommission(double totalPrice) {
    return totalPrice * _baseCommissionRate;
  }

  /// Returns a breakdown of the price components for display to the user.
  static Map<String, double> getPriceBreakdown({
    required double totalPrice,
    required Map<String, dynamic> problemData,
  }) {
    double commission = getCommission(totalPrice);
    double netToCraftizen = totalPrice - commission;

    return {
      'base_price': (problemData['price'] as num?)?.toDouble() ?? 0.0,
      'platform_commission': commission,
      'net_payout_to_craftizen': netToCraftizen,
    };
  }
}
