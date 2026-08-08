import 'package:flutter/foundation.dart';

import '../models/vault_model.dart';
import '../services/breach_service.dart';
import '../services/local_db_service.dart';
import '../utils/password_utils.dart';

/// The chips above the vault list.
enum VaultFilter { all, safe, weak, compromised, reused }

/// A snapshot of which entries are at risk and why.
///
/// Entries can carry more than one issue — a weak password reused across three
/// sites is both — so the sets overlap by design and only [safeCount] treats
/// them as one bucket.
class VaultHealth {
  final int total;
  final Set<String> weakIds;
  final Set<String> reusedIds;
  final Set<String> compromisedIds;

  const VaultHealth({
    this.total = 0,
    this.weakIds = const {},
    this.reusedIds = const {},
    this.compromisedIds = const {},
  });

  int get weakCount => weakIds.length;
  int get reusedCount => reusedIds.length;
  int get compromisedCount => compromisedIds.length;

  /// Ids with at least one issue.
  Set<String> get atRiskIds => {...weakIds, ...reusedIds, ...compromisedIds};

  int get safeCount => total - atRiskIds.length;

  /// The percentage on the home screen's gauge.
  ///
  /// Compromised entries weigh more than weak ones because a leaked password is
  /// a present fact, while a weak one is a future risk. An empty vault scores
  /// 100 rather than 0 — there is nothing wrong with it yet.
  int get score {
    if (total == 0) return 100;
    final penalty =
        compromisedIds.length * 1.0 +
        reusedIds.length * 0.6 +
        weakIds.length * 0.5;
    final ratio = 1 - (penalty / total);
    return (ratio.clamp(0.0, 1.0) * 100).round();
  }
}

/// Reads and writes vault entries, and derives everything the list, search and
/// health screens display.
///
/// Holds the decrypted entries in memory while unlocked. [clear] drops them,
/// and is called whenever the app locks.
class VaultController extends ChangeNotifier {
  final LocalDbService _db;
  final BreachService _breach;

  VaultController({required LocalDbService db, BreachService? breach})
    : _db = db,
      _breach = breach ?? BreachService();

  List<VaultModel> _all = const [];
  List<VaultModel> get all => _all;

  String _query = '';
  String get query => _query;

  VaultFilter _filter = VaultFilter.all;
  VaultFilter get filter => _filter;

  VaultTag? _tag;
  VaultTag? get tag => _tag;

  VaultHealth _health = const VaultHealth();
  VaultHealth get health => _health;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// Ids confirmed leaked by the online check, kept separately so a later
  /// offline-only recompute doesn't discard results the network already gave us.
  final Set<String> _onlineBreached = {};

  /// Loads from the open database. No-op if already loaded, so it is safe to
  /// call from a provider's update callback on every rebuild.
  void load({bool force = false}) {
    if (_loaded && !force) return;
    if (!_db.isOpen) return;

    _all = _db.readVaults();
    _loaded = true;
    _recomputeHealth();
    notifyListeners();
  }

  /// Drops in-memory entries. Paired with locking — leaving decrypted
  /// passwords in a controller after the box closes would defeat the lock.
  void clear() {
    _all = const [];
    _onlineBreached.clear();
    _health = const VaultHealth();
    _query = '';
    _filter = VaultFilter.all;
    _tag = null;
    _loaded = false;
    notifyListeners();
  }

  // ── Filtering ─────────────────────────────────────────────────────────────

  void search(String value) {
    if (_query == value) return;
    _query = value;
    notifyListeners();
  }

  void setFilter(VaultFilter value) {
    if (_filter == value) return;
    _filter = value;
    notifyListeners();
  }

  /// Passing the currently selected tag clears it, which is how the chips
  /// behave: tapping the active one deselects.
  void toggleTag(VaultTag value) {
    _tag = _tag == value ? null : value;
    notifyListeners();
  }

  /// What the list should show: entries matching the query, the health filter
  /// and the tag, all at once.
  List<VaultModel> get visible {
    final needle = _query.trim().toLowerCase();
    return _all.where((v) {
      if (needle.isNotEmpty && !v.searchHaystack.contains(needle)) return false;
      if (_tag != null && !v.tags.contains(_tag)) return false;
      return switch (_filter) {
        VaultFilter.all => true,
        VaultFilter.safe => !_health.atRiskIds.contains(v.id),
        VaultFilter.weak => _health.weakIds.contains(v.id),
        VaultFilter.reused => _health.reusedIds.contains(v.id),
        VaultFilter.compromised => _health.compromisedIds.contains(v.id),
      };
    }).toList();
  }

  /// The home screen's shortlist: most recently touched first.
  List<VaultModel> topVaults([int count = 5]) => _all.take(count).toList();

  int countByTag(VaultTag tag) =>
      _all.where((v) => v.tags.contains(tag)).length;

  VaultModel? byId(String id) {
    for (final v in _all) {
      if (v.id == id) return v;
    }
    return null;
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  /// Inserts or updates. The id is the key, so an edited entry replaces itself
  /// rather than accumulating copies.
  Future<void> save(VaultModel vault) async {
    await _db.saveVault(vault);
    _all = _db.readVaults();
    _recomputeHealth();
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _db.deleteVault(id);
    _onlineBreached.remove(id);
    _all = _db.readVaults();
    _recomputeHealth();
    notifyListeners();
  }

  /// Bulk insert used by backup restore.
  Future<void> importAll(Iterable<VaultModel> vaults) async {
    await _db.saveVaults(vaults);
    _all = _db.readVaults();
    _recomputeHealth();
    notifyListeners();
  }

  // ── Health ────────────────────────────────────────────────────────────────

  /// Recomputes weak/reused/compromised from what is in memory.
  ///
  /// Entirely offline and synchronous: strength scoring and the common-password
  /// list are local, so the list can re-render immediately after an edit.
  void _recomputeHealth() {
    final weak = <String>{};
    final compromised = <String>{};
    final byPassword = <String, List<String>>{};

    for (final v in _all) {
      final password = v.password;
      if (password.isEmpty) continue;

      if (PasswordUtils.estimate(password).index <
          PasswordStrength.good.index) {
        weak.add(v.id);
      }
      if (_breach.isCommon(password) || _onlineBreached.contains(v.id)) {
        compromised.add(v.id);
      }
      byPassword.putIfAbsent(password, () => []).add(v.id);
    }

    final reused = <String>{
      for (final ids in byPassword.values)
        if (ids.length > 1) ...ids,
    };

    _health = VaultHealth(
      total: _all.length,
      weakIds: weak,
      reusedIds: reused,
      compromisedIds: compromised,
    );
  }

  /// Checks every distinct password against HIBP.
  ///
  /// Only called when the user has turned the online check on. Distinct
  /// passwords are queried once each, so a password reused across five entries
  /// costs one request, not five.
  ///
  /// A failed request leaves that entry's status untouched rather than marking
  /// it safe — absence of evidence isn't evidence of safety.
  Future<void> refreshOnlineBreaches() async {
    final byPassword = <String, List<String>>{};
    for (final v in _all) {
      if (v.password.isEmpty) continue;
      byPassword.putIfAbsent(v.password, () => []).add(v.id);
    }

    var changed = false;
    for (final entry in byPassword.entries) {
      final count = await _breach.breachCount(entry.key);
      if (count == null) continue;

      for (final id in entry.value) {
        final wasBreached = _onlineBreached.contains(id);
        if (count > 0 && !wasBreached) {
          _onlineBreached.add(id);
          changed = true;
        } else if (count == 0 && wasBreached) {
          _onlineBreached.remove(id);
          changed = true;
        }
      }
    }

    if (changed) {
      _recomputeHealth();
      notifyListeners();
    }
  }

  /// How many known leaks affect this entry — the count behind the detail
  /// sheet's warning banner.
  bool isCompromised(String id) => _health.compromisedIds.contains(id);
  bool isWeak(String id) => _health.weakIds.contains(id);
  bool isReused(String id) => _health.reusedIds.contains(id);
}
