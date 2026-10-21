import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const SPMusicApp());
const gold = Color(0xFFD8B56A);
const bg = Color(0xFF090A0F);
const panel = Color(0xFF171821);

class SPMusicApp extends StatelessWidget {
  const SPMusicApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ساهره پلیر موزیک', debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: gold, brightness: Brightness.dark), useMaterial3: true),
    home: const PlayerHome());
}

class PlayerHome extends StatefulWidget {
  const PlayerHome({super.key});
  @override
  State<PlayerHome> createState() => _PlayerHomeState();
}

class _PlayerHomeState extends State<PlayerHome> {
  final _query = OnAudioQuery();
  final _player = AudioPlayer();
  final _search = TextEditingController();
  List<SongModel> _songs = [], _visible = [];
  final Set<int> _favorites = {};
  int _index = -1;
  bool _loading = true, _permissionDenied = false, _favoritesOnly = false;
  SongModel? get current => _index >= 0 && _index < _songs.length ? _songs[_index] : null;

  @override
  void initState() {
    super.initState();
    _restoreFavorites();
    _scan();
    _player.currentIndexStream.listen((i) {
      if (mounted && i != null && i >= 0 && i < _songs.length) setState(() => _index = i);
    });
  }

  Future<void> _restoreFavorites() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _favorites.addAll(p.getStringList('favorites')?.map(int.parse) ?? []));
  }
  Future<void> _saveFavorites() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList('favorites', _favorites.map((e) => e.toString()).toList());
  }
  Future<void> _scan() async {
    setState(() { _loading = true; _permissionDenied = false; });
    try {
      var ok = await _query.permissionsStatus();
      if (!ok) ok = await _query.permissionsRequest();
      if (!ok) { if (mounted) setState(() { _permissionDenied = true; _loading = false; }); return; }
      final list = await _query.querySongs(sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER, uriType: UriType.EXTERNAL, ignoreCase: true);
      if (!mounted) return;
      setState(() { _songs = list.where((s) => (s.duration ?? 0) > 0 && s.uri != null).toList(); _visible = _songs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _permissionDenied = true; });
    }
  }
  void _filter(String value) {
    final q = value.trim().toLowerCase();
    setState(() => _visible = _songs.where((s) =>
      (s.title.toLowerCase().contains(q) || (s.artist ?? '').toLowerCase().contains(q)) &&
      (!_favoritesOnly || _favorites.contains(s.id))).toList());
  }
  Future<void> _playSong(SongModel song) async {
    try {
      final idx = _songs.indexWhere((s) => s.id == song.id);
      if (idx < 0 || song.uri == null) return;
      await _player.setAudioSource(ConcatenatingAudioSource(
        children: _songs.map((s) => AudioSource.uri(Uri.parse(s.uri!), tag: s)).toList()), initialIndex: idx);
      await _player.play();
      if (mounted) setState(() => _index = idx);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('پخش این فایل ممکن نیست؛ فایل را بررسی کنید.')));
    }
  }
  Future<void> _toggleFavorite(SongModel s) async {
    setState(() { if (!_favorites.add(s.id)) _favorites.remove(s.id); });
    await _saveFavorites();
  }
  String _time(Duration? d) => d == null ? '--:--' :
    '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  void dispose() { _search.dispose(); _player.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final active = current;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 18, 20, 12), child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(colors: [Color(0xFFF4DEA5), gold, Color(0xFF795521)]),
            boxShadow: [BoxShadow(color: gold.withOpacity(.2), blurRadius: 18)]),
            child: const Icon(Icons.graphic_eq_rounded, color: Colors.black, size: 29)),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ساهره پلیر موزیک', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            SizedBox(height: 3), Text('SPMUSIC • LOCAL PLAYER', style: TextStyle(color: gold, fontSize: 10, letterSpacing: 1.4))])),
          IconButton(onPressed: _scan, icon: const Icon(Icons.refresh_rounded, color: gold), tooltip: 'اسکن مجدد')
        ])),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: TextField(controller: _search,
          onChanged: _filter, decoration: InputDecoration(hintText: 'جست‌وجوی آهنگ یا خواننده...',
            prefixIcon: const Icon(Icons.search_rounded, color: gold), filled: true, fillColor: panel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none)))),
        const SizedBox(height: 14),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
          const Expanded(child: Text('کتابخانه موسیقی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          Text('${_songs.length} آهنگ', style: const TextStyle(color: gold)),
          IconButton(onPressed: () { setState(() => _favoritesOnly = !_favoritesOnly); _filter(_search.text); },
            icon: Icon(_favoritesOnly ? Icons.favorite : Icons.favorite_border, color: _favoritesOnly ? gold : Colors.white70),
            tooltip: 'علاقه‌مندی‌ها')
        ])),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator(color: gold)) :
          _permissionDenied ? Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.folder_off_outlined, size: 54, color: gold), const SizedBox(height: 12),
            const Text('برای نمایش آهنگ‌ها، مجوز دسترسی به موسیقی را فعال کنید.', textAlign: TextAlign.center),
            const SizedBox(height: 12), FilledButton(onPressed: _scan, child: const Text('درخواست مجوز دوباره'))
          ]))) : _visible.isEmpty ? const Center(child: Text('آهنگی پیدا نشد. فایل‌های صوتی گوشی را بررسی کنید.', textAlign: TextAlign.center)) :
          ListView.builder(padding: const EdgeInsets.fromLTRB(14, 0, 14, 12), itemCount: _visible.length, itemBuilder: (context, i) {
            final s = _visible[i]; final playing = active?.id == s.id;
            return Container(margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(
              color: playing ? const Color(0xFF252116) : panel, borderRadius: BorderRadius.circular(17),
              border: Border.all(color: playing ? gold.withOpacity(.55) : Colors.white.withOpacity(.035))),
              child: ListTile(onTap: () => _playSong(s),
                leading: ClipRRect(borderRadius: BorderRadius.circular(12), child: QueryArtworkWidget(id: s.id,
                  type: ArtworkType.AUDIO, artworkWidth: 52, artworkHeight: 52,
                  nullArtworkWidget: Container(width: 52, height: 52,
                    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF42331B), Color(0xFF171821)])),
                    child: const Icon(Icons.album_rounded, color: gold, size: 29)))),
                title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w700, color: playing ? gold : Colors.white)),
                subtitle: Text('${s.artist ?? 'خواننده نامشخص'} • ${_time(Duration(milliseconds: s.duration ?? 0))}',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: IconButton(onPressed: () => _toggleFavorite(s),
                  icon: Icon(_favorites.contains(s.id) ? Icons.favorite : Icons.favorite_border,
                    color: _favorites.contains(s.id) ? gold : Colors.white38))));
          })),
        if (active != null) _nowPlaying(active),
        Container(padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: const BoxDecoration(color: Color(0xFF101117), border: Border(top: BorderSide(color: Colors.white10))),
          child: const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _NavItem(icon: Icons.home_rounded, label: 'خانه', selected: true),
            _NavItem(icon: Icons.library_music_rounded, label: 'کتابخانه'),
            _NavItem(icon: Icons.search_rounded, label: 'جست‌وجو'),
            _NavItem(icon: Icons.favorite_rounded, label: 'علاقه‌مندی'),
            _NavItem(icon: Icons.settings_rounded, label: 'تنظیمات')]))
      ]))));
  }

  Widget _nowPlaying(SongModel s) => Container(margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(colors: [Color(0xFF2D2518), Color(0xFF15151D)]),
      border: Border.all(color: gold.withOpacity(.35))),
    child: Column(children: [
      Row(children: [
        const Icon(Icons.multitrack_audio_rounded, color: gold, size: 27), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(s.artist ?? 'خواننده نامشخص', style: const TextStyle(color: Colors.white54, fontSize: 12))])),
        IconButton(onPressed: () => _player.seekToPrevious(), icon: const Icon(Icons.skip_previous_rounded, color: gold)),
        StreamBuilder<PlayerState>(stream: _player.playerStateStream, builder: (context, snap) {
          final playing = snap.data?.playing ?? false;
          return IconButton(iconSize: 36, onPressed: () => playing ? _player.pause() : _player.play(),
            icon: Icon(playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: gold));}),
        IconButton(onPressed: () => _player.seekToNext(), icon: const Icon(Icons.skip_next_rounded, color: gold))]),
      StreamBuilder<Duration?>(stream: _player.durationStream, builder: (context, ds) {
        final duration = ds.data ?? Duration.zero;
        return StreamBuilder<Duration>(stream: _player.positionStream, builder: (context, ps) {
          final position = ps.data ?? Duration.zero;
          final max = duration.inMilliseconds.toDouble().clamp(1.0, double.infinity).toDouble();
          final value = position.inMilliseconds.toDouble().clamp(0.0, max).toDouble();
          return Column(children: [
            Slider(value: value, max: max, activeColor: gold, inactiveColor: Colors.white12,
              onChanged: (v) => _player.seek(Duration(milliseconds: v.round()))),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_time(position), style: const TextStyle(fontSize: 10, color: Colors.white54)),
              Text(_time(duration), style: const TextStyle(fontSize: 10, color: Colors.white54))])]);
        });
      })
    ]));
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final bool selected;
  const _NavItem({required this.icon, required this.label, this.selected = false});
  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: selected ? gold : Colors.white38, size: 22), const SizedBox(height: 4),
    Text(label, style: TextStyle(fontSize: 10, color: selected ? gold : Colors.white38))]);
}
