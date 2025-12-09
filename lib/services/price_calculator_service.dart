import 'dart:math';

class PriceCalculatorService {
  // Calculate final price with app profit guaranteed
  static Future<double> calculateServicePrice({
    required String serviceId,
    required Map<String, dynamic> serviceData,
    double? customMultiplier,
    int units = 1,
    bool isPeakTime = false,
    double distanceKm = 0,
  }) async {
    double basePrice = (serviceData['basePrice'] ?? 0).toDouble();
    double pricePerUnit = (serviceData['pricePerUnit'] ?? 0).toDouble();
    double minPrice = (serviceData['minPrice'] ?? 0).toDouble();
    double craftMultiplier = customMultiplier ?? 1.0;
    
    // Step 1: Base calculation
    double totalPrice = basePrice + (pricePerUnit * units);
    
    // Step 2: Apply Craftizen premium
    totalPrice *= craftMultiplier;
    
    // Step 3: Distance/travel charges (e.g., ₹10/km)
    totalPrice += (distanceKm * 10); 
    
    // Step 4: Peak time surge
    if (isPeakTime) {
      double surgeMultiplier = (serviceData['surgeMultiplier'] ?? 1.5).toDouble();
      totalPrice *= surgeMultiplier;
    }
    
    // Step 5: Ensure minimum price is met
    totalPrice = max(totalPrice, minPrice);

    // Step 6: Clamp to max price if it exists
    if (serviceData['maxPrice'] != null) {
      double maxPrice = (serviceData['maxPrice'] ?? double.infinity).toDouble();
      totalPrice = totalPrice.clamp(minPrice, maxPrice);
    }
    
    // Step 7: Round up to nearest 10 for customer psychology
    totalPrice = (totalPrice / 10).ceil() * 10;
    
    return totalPrice;
  }
  
  // Breakdown for transparency
  static Map<String, double> getPriceBreakdown({
    required double totalPrice,
    required Map<String, dynamic> serviceData,
  }) {
    double appCommissionRate = (serviceData['appCommission'] ?? 0.12).toDouble();
    double appCommission = totalPrice * appCommissionRate;
    double craftizenEarns = totalPrice - appCommission;
    
    return {
      'totalPrice': totalPrice,
      'appCommission': appCommission,
      'craftizenEarnings': craftizenEarns,
    };
  }
}
