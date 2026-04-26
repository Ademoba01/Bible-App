import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../data/bible_maps_data.dart';
import '../../state/providers.dart';

// ---------------------------------------------------------------------------
// Bible Maps Screen
// ---------------------------------------------------------------------------

class BibleMapsScreen extends ConsumerStatefulWidget {
  const BibleMapsScreen({super.key});

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
    if (_selectedEra != null) {
      return kBiblicalPlaces
          .where((p) => p.eras.contains(_selectedEra))
          .toList();
    }
    return kBiblicalPlaces;
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

  /// Parse a verse reference like "Genesis 12:1" and navigate.
  void _navigateToVerse(String verseRef) {
    final parts = verseRef.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return;

    final chapterVersePart = parts.last;
    final bookParts = parts.sublist(0, parts.length - 1);

    String book;
    String chapterStr;

    if (chapterVersePart.contains(':') ||
        int.tryParse(chapterVersePart) != null) {
      book = bookParts.join(' ');
      chapterStr = chapterVersePart.split(':').first;
    } else {
      book = verseRef;
      chapterStr = '1';
    }

    final chapter = int.tryParse(chapterStr) ?? 1;

    ref.read(readingLocationProvider.notifier).setBook(book);
    ref.read(readingLocationProvider.notifier).setChapter(chapter);
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
    return AppBar(
      title: Text(
        'Bible Maps',
        style: GoogleFonts.playfairDisplay(
          fontWeight: FontWeight.w700,
          color: _parchment,
          fontSize: 22,
        ),
      ),
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
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            _buildEraChip(null, 'All Eras', '📖'),
            const SizedBox(width: 6),
            ...BiblicalEra.values.map((era) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child:
                      _buildEraChip(era, era.label, era.emoji),
                )),
          ],
        ),
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
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(31.7683, 35.2137),
            initialZoom: 6,
            minZoom: 3,
            maxZoom: 18,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
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
