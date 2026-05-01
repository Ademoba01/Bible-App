import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../data/bible_maps_data.dart';
import '../../state/providers.dart';
import '../../widgets/rhema_title.dart';

// ---------------------------------------------------------------------------
// Bible Maps Screen
// ---------------------------------------------------------------------------

class BibleMapsScreen extends ConsumerStatefulWidget {
  const BibleMapsScreen({super.key, this.initialEra});

  /// Pre-selected era when arriving from Chronology. Filters the map to
  /// places for this era and centers the camera on its representative
  /// location. Null → default "All Places" mode.
  final BiblicalEra? initialEra;

  @override
  ConsumerState<BibleMapsScreen> createState() => _BibleMapsScreenState();
}

class _BibleMapsScreenState extends ConsumerState<BibleMapsScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  /// null => "All Places" mode; otherwise the selected journey.
  BiblicalJourney? _selectedJourney;

  /// null => show all eras; otherwise filter to selected era.
  BiblicalEra? _selectedEra;

  /// The place currently shown in the info-card sheet (null when closed).
  /// Captured so navigating to a verse can persist "return to this place"
  /// so the floating "Back to Maps" chip can re-open the same info card.
  BiblicalPlace? _currentInfoPlace;

  /// Testament filter: null => Both, true => OT only, false => NT only.
  /// Cuts horizontally across all eras for a coarser/clearer first cut.
  bool? _onlyOldTestament;

  /// OT eras: any era from creation through the prophetic books.
  /// NT eras: Jesus + early church + Revelation.
  static const _otEras = {
    BiblicalEra.patriarchs,
    BiblicalEra.exodus,
    BiblicalEra.conquest,
    BiblicalEra.kingdom,
    BiblicalEra.exile,
    BiblicalEra.prophets,
  };
  static const _ntEras = {
    BiblicalEra.jesus,
    BiblicalEra.earlyChurch,
    BiblicalEra.revelation,
  };

  bool _satelliteView = false;

  // ── Journey playback ──────────────────────────────────────────
  AnimationController? _playbackController;
  bool _isPlaying = false;
  double _playbackProgress = 0.0;

  // ── Pulsing marker animation ──────────────────────────────────
  late final AnimationController _pulseController;

  // ── tile URLs ──────────────────────────────────────────────────────
  static const _osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _satelliteTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  // ── warm ancient-map palette ───────────────────────────────────────
  static const _parchment = Color(0xFFF5ECD7);
  static const _warmBrown = Color(0xFF5D4037);
  static const _darkBrown = Color(0xFF3E2723);
  static const _goldAccent = Color(0xFFD4A843);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Era pre-selection from Chronology (E4 review): if `initialEra` is
    // passed, filter the map to that era's places on first paint. Lets
    // users follow Chronology → "Open in Maps" → see only e.g. Exodus
    // places without manually re-applying the era filter.
    if (widget.initialEra != null) {
      _selectedEra = widget.initialEra;
    }

    // If the user came back from a verse via the "Back to Map" chip,
    // re-open the same info card on the next frame so they pick up
    // exactly where they left off.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final returnPlace = ref.read(mapReturnPlaceProvider);
      if (returnPlace != null) {
        ref.read(mapReturnPlaceProvider.notifier).state = null;
        final place = kBiblicalPlaces.firstWhere(
          (p) => p.name == returnPlace,
          orElse: () => kBiblicalPlaces.first,
        );
        if (place.name == returnPlace) {
          _showPlaceInfo(place);
        }
      }
    });
  }

  @override
  void dispose() {
    _playbackController?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────

  List<BiblicalPlace> get _visiblePlaces {
    if (_selectedJourney != null) return _selectedJourney!.stops;
    Iterable<BiblicalPlace> base = kBiblicalPlaces;
    // Era filter (more specific) takes precedence over the testament
    // toggle when both are set — selecting a specific era implies you
    // already chose its testament.
    if (_selectedEra != null) {
      base = base.where((p) => p.eras.contains(_selectedEra));
    } else if (_onlyOldTestament != null) {
      // Testament filter: include a place if ANY of its eras belongs to
      // the chosen testament. Locations like Jerusalem (which span both)
      // appear under both filters — no false exclusions.
      final filterSet = _onlyOldTestament! ? _otEras : _ntEras;
      base = base.where((p) => p.eras.any(filterSet.contains));
    }
    return base.toList();
  }

  void _selectJourney(BiblicalJourney? journey) {
    _stopPlayback();
    setState(() {
      _selectedJourney = journey;
      _selectedEra = null;
    });
    if (journey != null && journey.route.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(journey.route),
          padding: const EdgeInsets.all(50),
        ),
      );
    } else {
      _mapController.move(LatLng(31.7683, 35.2137), 6);
    }
  }

  void _selectEra(BiblicalEra? era) {
    _stopPlayback();
    setState(() {
      _selectedEra = era;
      _selectedJourney = null;
    });
    if (era != null) {
      final places = kBiblicalPlaces
          .where((p) => p.eras.contains(era))
          .toList();
      if (places.isNotEmpty) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(
                places.map((p) => p.position).toList()),
            padding: const EdgeInsets.all(50),
          ),
        );
      }
    } else {
      _mapController.move(LatLng(31.7683, 35.2137), 6);
    }
  }

  // ── Journey playback ──────────────────────────────────────────

  void _togglePlayback() {
    if (_selectedJourney == null) return;
    if (_isPlaying) {
      _pausePlayback();
    } else {
      _startPlayback();
    }
  }

  void _startPlayback() {
    if (_selectedJourney == null) return;
    final route = _selectedJourney!.route;
    if (route.length < 2) return;

    _playbackController?.dispose();
    _playbackController = AnimationController(
      vsync: this,
      duration: Duration(seconds: route.length * 2),
    );

    _playbackController!.addListener(() {
      setState(() => _playbackProgress = _playbackController!.value);
    });

    _playbackController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isPlaying = false);
      }
    });

    // Start from current progress or beginning
    if (_playbackProgress >= 1.0) _playbackProgress = 0.0;
    _playbackController!.forward(from: _playbackProgress);
    setState(() => _isPlaying = true);
  }

  void _pausePlayback() {
    _playbackController?.stop();
    setState(() => _isPlaying = false);
  }

  void _stopPlayback() {
    _playbackController?.stop();
    _playbackController?.dispose();
    _playbackController = null;
    setState(() {
      _isPlaying = false;
      _playbackProgress = 0.0;
    });
  }

  /// Get the current position of the animated dot along the route.
  LatLng? get _playbackPosition {
    if (_selectedJourney == null || _playbackProgress == 0.0) return null;
    final route = _selectedJourney!.route;
    if (route.length < 2) return null;

    final totalSegments = route.length - 1;
    final progressInSegments = _playbackProgress * totalSegments;
    final segmentIndex = progressInSegments.floor().clamp(0, totalSegments - 1);
    final segmentProgress = progressInSegments - segmentIndex;

    final start = route[segmentIndex];
    final end = route[min(segmentIndex + 1, route.length - 1)];

    return LatLng(
      start.latitude + (end.latitude - start.latitude) * segmentProgress,
      start.longitude + (end.longitude - start.longitude) * segmentProgress,
    );
  }

  /// Get the portion of the route that has been "traveled" so far.
  List<LatLng> get _traveledRoute {
    if (_selectedJourney == null || _playbackProgress == 0.0) return [];
    final route = _selectedJourney!.route;
    if (route.length < 2) return [];

    final totalSegments = route.length - 1;
    final progressInSegments = _playbackProgress * totalSegments;
    final segmentIndex = progressInSegments.floor().clamp(0, totalSegments - 1);
    final segmentProgress = progressInSegments - segmentIndex;

    final traveled = route.sublist(0, segmentIndex + 1).toList();
    final start = route[segmentIndex];
    final end = route[min(segmentIndex + 1, route.length - 1)];
    traveled.add(LatLng(
      start.latitude + (end.latitude - start.latitude) * segmentProgress,
      start.longitude + (end.longitude - start.longitude) * segmentProgress,
    ));

    return traveled;
  }

  void _showPlaceInfo(BiblicalPlace place) {
    _currentInfoPlace = place; // capture for return-to-Maps from reading
    final parentJourneys = kBiblicalJourneys.where((j) {
      return j.stops.any((s) => s.name == place.name);
    }).toList();

    String? nextStopName;
    BiblicalPlace? nextStopPlace;
    for (final j in parentJourneys) {
      final idx = j.stops.indexWhere((s) => s.name == place.name);
      if (idx >= 0 && idx < j.stops.length - 1) {
        nextStopPlace = j.stops[idx + 1];
        nextStopName = nextStopPlace.name;
        break;
      }
    }

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Center(
        child: Container(
          width: 380,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.55,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF5ECD7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD4A843).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            child: _PlaceInfoSheet(
              place: place,
              journeys: parentJourneys,
              nextStopName: nextStopName,
              onVerseTapped: (verse) {
                Navigator.of(ctx).pop();
                _navigateToVerse(verse);
              },
              onNextStop: nextStopPlace != null
                  ? () {
                      Navigator.of(ctx).pop();
                      _mapController.move(nextStopPlace!.position, 8);
                      Future.delayed(const Duration(milliseconds: 500), () {
                        _showPlaceInfo(nextStopPlace!);
                      });
                    }
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  /// Parse a verse reference like "Acts 9:3" and navigate to the Read tab,
  /// highlighting the specific verse AND marking the return context so the
  /// reading screen can show "← Back to Maps" and re-select the current
  /// place when tapped.
  void _navigateToVerse(String verseRef) {
    final parts = verseRef.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return;

    final chapterVersePart = parts.last;
    final bookParts = parts.sublist(0, parts.length - 1);

    String book;
    String chapterStr;
    int? verseNum;

    if (chapterVersePart.contains(':')) {
      // "Acts 9:3" — split chapter:verse
      book = bookParts.join(' ');
      final cv = chapterVersePart.split(':');
      chapterStr = cv[0];
      // Verse may include a range "3-5" — take the first number
      final vRaw = cv.length > 1 ? cv[1].split(RegExp(r'[-,]')).first : '';
      verseNum = int.tryParse(vRaw);
    } else if (int.tryParse(chapterVersePart) != null) {
      book = bookParts.join(' ');
      chapterStr = chapterVersePart;
    } else {
      book = verseRef;
      chapterStr = '1';
    }

    final chapter = int.tryParse(chapterStr) ?? 1;

    ref.read(readingLocationProvider.notifier).setBook(book);
    ref.read(readingLocationProvider.notifier).setChapter(chapter);
    if (verseNum != null) {
      ref.read(highlightVerseProvider.notifier).state = verseNum;
    }
    // Mark return context so the reading screen can show "Back to Maps".
    ref.read(returnContextProvider.notifier).state = 'map';
    if (_currentInfoPlace != null) {
      ref.read(mapReturnPlaceProvider.notifier).state =
          _currentInfoPlace!.name;
    }
    ref.read(tabIndexProvider.notifier).set(1);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ──────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _parchment,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildEraSelector(),
          _buildJourneySelector(),
          Expanded(child: _buildMap()),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    // Centered RhemaTitle (logo + wordmark) is the consistent brand mark
    // across all sub-screens AND a tap-to-home affordance — same pattern
    // as Prayer Wall, Reading screen, etc. Screen identity is preserved
    // by the era chips below + the Quick Action tile that opened this.
    return AppBar(
      centerTitle: true,
      title: const RhemaTitle(),
      backgroundColor: _darkBrown,
      foregroundColor: _parchment,
      elevation: 0,
      actions: [
        IconButton(
          tooltip: _satelliteView ? 'Map view' : 'Satellite view',
          icon: Icon(
            _satelliteView ? Icons.map_outlined : Icons.satellite_alt,
            color: _goldAccent,
          ),
          onPressed: () => setState(() => _satelliteView = !_satelliteView),
        ),
      ],
    );
  }

  // ── Era filter chips ──────────────────────────────────────────────
  Widget _buildEraSelector() {
    return Container(
      width: double.infinity,
      color: _darkBrown,
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Testament toggle — coarser cut above the per-era chips. Choosing
          // OT or NT auto-clears any selected era. Picking a specific era
          // below takes precedence (era filter is more specific).
          _buildTestamentToggle(),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _buildEraChip(null, 'All Eras', '📖'),
                const SizedBox(width: 6),
                ...BiblicalEra.values.map((era) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _buildEraChip(era, era.label, era.emoji),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Three-way toggle: Both | Old Testament | New Testament.
  /// Filters places horizontally (any place whose era set intersects
  /// the chosen testament shows up). Tapping any segment clears the
  /// selectedEra so the testament filter is what's actually active.
  Widget _buildTestamentToggle() {
    Widget seg(String label, bool? value, String emoji) {
      final selected = _onlyOldTestament == value;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() {
              _onlyOldTestament = value;
              _selectedEra = null;
              _selectedJourney = null;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: selected
                  ? _goldAccent.withValues(alpha: 0.85)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? _goldAccent
                    : _goldAccent.withValues(alpha: 0.25),
                width: selected ? 1.4 : 0.6,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? _darkBrown : _parchment,
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          seg('Both', null, '📚'),
          seg('Old Testament', true, '📜'),
          seg('New Testament', false, '✝️'),
        ],
      ),
    );
  }

  Widget _buildEraChip(BiblicalEra? era, String label, String emoji) {
    final isSelected =
        (_selectedEra == era && _selectedJourney == null) ||
            (era == null && _selectedEra == null && _selectedJourney == null);
    final chipColor =
        era != null ? Color(era.color) : _goldAccent;

    return GestureDetector(
      onTap: () => _selectEra(era),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withValues(alpha: 0.85)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? chipColor
                : _goldAccent.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.lora(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Journey selector chips ─────────────────────────────────────────
  Widget _buildJourneySelector() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _darkBrown,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _buildChip(
              label: 'All Places',
              emoji: '\uD83D\uDDFA\uFE0F',
              isSelected: _selectedJourney == null,
              selectedColor: _goldAccent,
              onTap: () => _selectJourney(null),
            ),
            const SizedBox(width: 8),
            ...kBiblicalJourneys.map((journey) {
              final isSelected = _selectedJourney?.id == journey.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildChip(
                  label: journey.name,
                  emoji: journey.emoji,
                  isSelected: isSelected,
                  selectedColor: Color(journey.color),
                  onTap: () => _selectJourney(journey),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required String emoji,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.9)
              : _warmBrown.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? selectedColor
                : _goldAccent.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.lora(
                color: Colors.white,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Map ────────────────────────────────────────────────────────────
  Widget _buildMap() {
    final playbackPos = _playbackPosition;
    final traveled = _traveledRoute;

    return Stack(
      // Tight constraints so FlutterMap fills the parent's bounds —
      // without this, default StackFit.loose passes unbounded
      // constraints which can starve the map of a usable canvas
      // (the same Stack-bug class that broke home scroll in 10e8c51).
      fit: StackFit.expand,
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(31.7683, 35.2137),
            initialZoom: 6,
            minZoom: 2,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              // Disable rotation entirely. Bible maps don't benefit from
              // rotated geography, and rotation gestures fight pinch
              // even with `enableMultiFingerGestureRace`. With rotate
              // off, pinch wins every two-finger gesture cleanly.
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              enableMultiFingerGestureRace: true,
              // Very low threshold = recognize pinch as soon as the
              // user pinches even a few percent. Default is 0.5 which
              // is too high for users with non-touchscreen sims.
              pinchZoomThreshold: 0.1,
            ),
          ),
          children: [
            // Tile layer
            TileLayer(
              urlTemplate: _satelliteView ? _satelliteTileUrl : _osmTileUrl,
              userAgentPackageName: 'com.ademoba.bible_app',
              maxZoom: 18,
            ),

            // Full route (dimmed when playing back)
            if (_selectedJourney != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _selectedJourney!.route,
                    strokeWidth: _isPlaying || _playbackProgress > 0 ? 2 : 4,
                    color: _isPlaying || _playbackProgress > 0
                        ? Color(_selectedJourney!.color).withValues(alpha: 0.25)
                        : Color(_selectedJourney!.color),
                    borderStrokeWidth: 1,
                    borderColor:
                        Color(_selectedJourney!.color).withValues(alpha: 0.15),
                  ),
                ],
              ),

            // Traveled portion of route (bright)
            if (_selectedJourney != null && traveled.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: traveled,
                    strokeWidth: 5,
                    color: Color(_selectedJourney!.color),
                    borderStrokeWidth: 1,
                    borderColor: Colors.white.withValues(alpha: 0.5),
                  ),
                ],
              ),

            // Marker layer
            MarkerLayer(
              markers: _visiblePlaces.map((place) {
                final isStop = _selectedJourney != null;
                return Marker(
                  point: place.position,
                  width: 44,
                  height: 44,
                  child: GestureDetector(
                    onTap: () => _showPlaceInfo(place),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: isStop
                              ? Color(_selectedJourney!.color)
                              : _selectedEra != null
                                  ? Color(_selectedEra!.color)
                                  : _warmBrown,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 6,
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          place.emoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            // Animated pulsing dot at playback position
            if (playbackPos != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: playbackPos,
                    width: 28,
                    height: 28,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (_, __) {
                        final scale = 1.0 + _pulseController.value * 0.3;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(_selectedJourney!.color),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(_selectedJourney!.color)
                                      .withValues(alpha: 0.6),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.navigation,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Journey playback controls
        if (_selectedJourney != null)
          Positioned(
            left: 16,
            right: 80,
            bottom: 24,
            child: _buildPlaybackControls(),
          ),

        // Place count badge
        Positioned(
          left: 16,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _darkBrown.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${_visiblePlaces.length} places',
              style: GoogleFonts.lora(
                color: _goldAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Zoom controls overlay — positioned above playback bar when visible
        Positioned(
          right: 16,
          bottom: _selectedJourney != null ? 100 : 24,
          child: Column(
            children: [
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                backgroundColor: Colors.white,
                foregroundColor: _darkBrown,
                onPressed: () {
                  final zoom = _mapController.camera.zoom;
                  final newZoom = (zoom + 1).clamp(3.0, 18.0);
                  _mapController.move(
                      _mapController.camera.center, newZoom);
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                backgroundColor: Colors.white,
                foregroundColor: _darkBrown,
                onPressed: () {
                  final zoom = _mapController.camera.zoom;
                  final newZoom = (zoom - 1).clamp(3.0, 18.0);
                  _mapController.move(
                      _mapController.camera.center, newZoom);
                },
                child: const Icon(Icons.remove),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'reset_view',
                backgroundColor: _warmBrown,
                foregroundColor: Colors.white,
                onPressed: () {
                  _selectJourney(null);
                  _selectEra(null);
                },
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Playback controls bar ─────────────────────────────────────────
  Widget _buildPlaybackControls() {
    final journey = _selectedJourney!;
    final stopsReached = _playbackProgress > 0
        ? (_playbackProgress * (journey.stops.length - 1)).floor() + 1
        : 0;
    final currentStopName = stopsReached > 0 && stopsReached <= journey.stops.length
        ? journey.stops[min(stopsReached - 1, journey.stops.length - 1)].name
        : '';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _darkBrown.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _togglePlayback,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(journey.color),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPlaying || _playbackProgress > 0
                          ? currentStopName
                          : 'Play journey',
                      style: GoogleFonts.lora(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _playbackProgress,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Color(journey.color)),
                      ),
                    ),
                  ],
                ),
              ),
              if (_playbackProgress > 0) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _stopPlayback,
                  child: Icon(Icons.stop,
                      color: Colors.white.withValues(alpha: 0.7), size: 22),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Place Info Bottom Sheet
// ---------------------------------------------------------------------------

class _PlaceInfoSheet extends StatelessWidget {
  const _PlaceInfoSheet({
    required this.place,
    required this.journeys,
    required this.onVerseTapped,
    this.onNextStop,
    this.nextStopName,
  });

  final BiblicalPlace place;
  final List<BiblicalJourney> journeys;
  final ValueChanged<String> onVerseTapped;
  final VoidCallback? onNextStop;
  final String? nextStopName;

  static const _parchment = Color(0xFFF5ECD7);
  static const _warmBrown = Color(0xFF5D4037);
  static const _darkBrown = Color(0xFF3E2723);
  static const _goldAccent = Color(0xFFD4A843);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      decoration: BoxDecoration(
        color: _parchment,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _darkBrown,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 6,
                              color: Colors.black.withValues(alpha: 0.2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            place.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place.name,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _darkBrown,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              place.modernName,
                              style: GoogleFonts.lora(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Era badges
                  if (place.eras.isNotEmpty) ...[
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: place.eras.map((era) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Color(era.color).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Color(era.color).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            '${era.emoji} ${era.label}',
                            style: GoogleFonts.lora(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(era.color),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Description
                  Text(
                    place.description,
                    style: GoogleFonts.lora(
                      fontSize: 15,
                      height: 1.5,
                      color: _darkBrown.withValues(alpha: 0.85),
                    ),
                  ),

                  // Journey badges
                  if (journeys.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: journeys.map((j) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Color(j.color).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(j.color).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '${j.emoji} ${j.name}',
                            style: GoogleFonts.lora(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(j.color),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Related verses
                  if (place.relatedVerses.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Related Verses',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _darkBrown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...place.relatedVerses.map((verse) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () => onVerseTapped(verse),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _warmBrown.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _goldAccent.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 18,
                                  color: _goldAccent,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    verse,
                                    style: GoogleFonts.lora(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _warmBrown,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 14,
                                  color: _warmBrown.withValues(alpha: 0.4),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],

                  // Continue journey section
                  if (onNextStop != null && nextStopName != null) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_forward),
                        label: Text('Next: $nextStopName'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _warmBrown,
                          side: BorderSide(
                            color: _goldAccent.withValues(alpha: 0.6),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onNextStop,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
