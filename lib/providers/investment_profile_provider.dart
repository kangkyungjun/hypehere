import 'package:flutter/foundation.dart';
import '../models/investment_profile.dart';
import '../services/investment_profile_service.dart';

class InvestmentProfileProvider with ChangeNotifier {
  final InvestmentProfileService _service = InvestmentProfileService();

  InvestmentProfile? _profile;
  bool _isLoading = false;
  bool _hasChecked = false;

  InvestmentProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get hasChecked => _hasChecked;

  /// true if we checked and no profile exists on server
  bool get needsOnboarding => _hasChecked && _profile == null;

  /// Fetch profile from server. Sets _profile or leaves null.
  Future<void> fetchProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _service.getProfile();
    } catch (e) {
      debugPrint('[InvestmentProfileProvider] fetchProfile error: $e');
      // Leave _profile as null
    } finally {
      _hasChecked = true;
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save profile to server and update local state.
  Future<bool> saveProfile(InvestmentProfile profile) async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _service.saveProfile(profile);
      return true;
    } catch (e) {
      debugPrint('[InvestmentProfileProvider] saveProfile error: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear local state (on logout).
  void clear() {
    _profile = null;
    _hasChecked = false;
    _isLoading = false;
    notifyListeners();
  }
}
