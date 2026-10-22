import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Never leave Android on Flutter's native splash screen if audio-service
  // initialization fails or stalls on a device. The UI must still start.
  try {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.sahareh.spmusic.audio',
      androidNotificationChannelName: 'SPMusic Playback',
      androidNotificationOngoing: true,
    ).timeout(const Duration(seconds: 5));
  } catch (error, stackTrace) {
    debugPrint('SPMusic background audio initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const SPMusicApp());
}
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
    home: const CinematicSplash());
}


class CinematicSplash extends StatefulWidget {
 const CinematicSplash({super.key});
 @override State<CinematicSplash> createState()=>_CinematicSplashState();
}
class _CinematicSplashState extends State<CinematicSplash> with TickerProviderStateMixin {
 late final AnimationController scene=AnimationController(vsync:this,duration:const Duration(seconds:10))..forward();
 late final AnimationController ambient=AnimationController(vsync:this,duration:const Duration(seconds:7))..repeat();
 final AudioPlayer intro=AudioPlayer(); bool music=true, opened=false;
 @override void initState(){super.initState(); _playMusic(); scene.addStatusListener((s){if(s==AnimationStatus.completed)_enter();});}
 Future<void> _playMusic() async {
  try { await intro.setAsset('assets/audio/splash.wav'); if(!music||!mounted)return;
   await intro.setLoopMode(LoopMode.one);
   await intro.setVolume(0); await intro.play();
   for(var i=1;i<=12&&mounted&&music;i++){await Future<void>.delayed(const Duration(milliseconds:100));await intro.setVolume(i/12*.42);}
   await Future<void>.delayed(const Duration(seconds:7));
   for(var i=11;i>=0&&mounted&&music;i--){await intro.setVolume(i/12*.42);await Future<void>.delayed(const Duration(milliseconds:100));}
   await intro.stop();
  } catch(e){debugPrint('Intro audio unavailable: $e');}
 }
 void _enter(){if(opened||!mounted)return;opened=true;intro.stop();Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
 transitionDuration:const Duration(milliseconds:700),pageBuilder:(_,a,__)=>const PlayerHome(),
 transitionsBuilder:(_,a,__,child)=>FadeTransition(opacity:CurvedAnimation(parent:a,curve:Curves.easeInOut),child:child)));}
 @override void dispose(){scene.dispose();ambient.dispose();intro.dispose();super.dispose();}
 @override Widget build(BuildContext context)=>Scaffold(backgroundColor:const Color(0xFF050609),
 body:AnimatedBuilder(animation:Listenable.merge([scene,ambient]),builder:(context,_){
 final t=scene.value; final reveal=Curves.easeOutCubic.transform(((t-.12)/.36).clamp(0.0,1.0));
 return Stack(fit:StackFit.expand,children:[
 const DecoratedBox(decoration:BoxDecoration(gradient:RadialGradient(center:Alignment(0,-.12),radius:1.05,colors:[Color(0xFF211B12),Color(0xFF0B0C11),Color(0xFF030406)]))),
 CustomPaint(painter:_GoldParticles(ambient.value,reveal)),
 Center(child:Opacity(opacity:reveal,child:Transform.translate(offset:Offset(0,22*(1-reveal)),child:Transform.scale(scale:.82+.18*reveal+.012*ambient.value,
 child:Column(mainAxisSize:MainAxisSize.min,children:[
 Container(width:206,height:206,decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:gold.withValues(alpha:.62),width:1.2),
 gradient:const RadialGradient(colors:[Color(0xFF292117),Color(0xFF08090D)]),boxShadow:[BoxShadow(color:gold.withValues(alpha:.20),blurRadius:48,spreadRadius:5)]),
 child:Stack(alignment:Alignment.center,children:[const Icon(Icons.headphones_rounded,size:118,color:Color(0xFFF1D99A)),
 Positioned(bottom:37,child:Container(width:100,height:1.5,decoration:const BoxDecoration(gradient:LinearGradient(colors:[Colors.transparent,Color(0xFFF4DEA5),Colors.transparent])))),
 Positioned(bottom:17,child:Text('SP',style:TextStyle(fontSize:25,letterSpacing:7,fontWeight:FontWeight.w300,color:gold.withValues(alpha:.92))))])),
 const SizedBox(height:34),
 ShaderMask(shaderCallback:(b)=>const LinearGradient(colors:[Color(0xFFFAE9B9),Color(0xFFC69A45),Color(0xFFF8E4A7)]).createShader(b),
 child:const Text('SAHAREH',style:TextStyle(color:Colors.white,fontSize:27,letterSpacing:6,fontWeight:FontWeight.w300))),
 const SizedBox(height:7),const Text('M U S I C   P L A Y E R',style:TextStyle(color:Color(0xFFC7C4BD),fontSize:10,letterSpacing:2.3)),
 const SizedBox(height:27),Opacity(opacity:.45+.45*ambient.value,child:Container(width:100,height:1,decoration:const BoxDecoration(gradient:LinearGradient(colors:[Colors.transparent,Color(0xFFD8B56A),Colors.transparent])))),
 const SizedBox(height:24),const Text('تجربه‌ای متفاوت از شنیدن موسیقی',style:TextStyle(color:Color(0xFFB9B1A1),fontSize:12))
 ]))))),
 Positioned(left:16,top:24,child:SafeArea(child:IconButton(tooltip:music?'خاموش کردن موسیقی شروع':'روشن کردن موسیقی شروع',
 onPressed:()async{setState(()=>music=!music);if(!music){await intro.stop();}else{await _playMusic();}},
 icon:Icon(music?Icons.music_note_rounded:Icons.music_off_rounded,color:gold.withValues(alpha:.8),size:21)))),
 Positioned(bottom:27,left:0,right:0,child:Column(children:[SizedBox(width:112,child:ClipRRect(borderRadius:BorderRadius.circular(8),
 child:LinearProgressIndicator(value:t,minHeight:2,backgroundColor:Colors.white10,color:gold))),const SizedBox(height:10),
 const Text('SPMUSIC  •  EST. FOR YOUR MOMENTS',style:TextStyle(color:Colors.white30,fontSize:8,letterSpacing:1.7))]))
 ]);
 }));
}
class _GoldParticles extends CustomPainter {
 final double phase,reveal; _GoldParticles(this.phase,this.reveal);
 @override void paint(Canvas canvas,Size size){
 final p=Paint()..style=PaintingStyle.fill;
 for(int i=0;i<42;i++){final x=((i*73.7)%997)/997*size.width;final baseY=((i*137.1)%991)/991*size.height;
 final y=(baseY-phase*(18+(i%6)*9)+size.height)%size.height;
 p.color=(i%3==0?const Color(0xFFF4DEA5):gold).withValues(alpha:(.08+.28*((i%5)/5))*reveal);
 canvas.drawCircle(Offset(x,y),.6+(i%4)*.38,p);}
 final light=Paint()..shader=RadialGradient(colors:[gold.withValues(alpha:.07*reveal),Colors.transparent])
 .createShader(Rect.fromCircle(center:Offset(size.width*(.2+phase*.6),size.height*.48),radius:size.width*.55));
 canvas.drawRect(Offset.zero&size,light);
 }
 @override bool shouldRepaint(covariant _GoldParticles old)=>old.phase!=phase||old.reveal!=reveal;
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
      if (!ok) {
        if (mounted) {
          setState(() { _permissionDenied = true; _loading = false; });
        }
        return;
      }
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
        children: _songs.map((s) => AudioSource.uri(Uri.parse(s.uri!), tag: MediaItem(id: s.id.toString(), album: s.album ?? 'موسیقی محلی', title: s.title, artist: s.artist ?? 'خواننده نامشخص'))).toList()), initialIndex: idx);
      await _player.play();
      if (mounted) setState(() => _index = idx);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('پخش این فایل ممکن نیست؛ فایل را بررسی کنید.')),
        );
      }
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
            boxShadow: [BoxShadow(color: gold.withValues(alpha: .2), blurRadius: 18)]),
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
              border: Border.all(color: playing ? gold.withValues(alpha: .55) : Colors.white.withValues(alpha: .035))),
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
      border: Border.all(color: gold.withValues(alpha: .35))),
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
