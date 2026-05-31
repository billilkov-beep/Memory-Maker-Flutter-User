import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../config/app_config.dart';
import '../models/app_models.dart';
import '../services/image_service.dart';
import '../services/repository_provider.dart';
import '../theme.dart';
import '../widgets/mm_widgets.dart';
import '../utils_app.dart';
import 'media_preview_screen.dart';

class EventDetailScreen extends StatefulWidget {
  final MmEvent event;
  const EventDetailScreen({super.key, required this.event});
  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late Future<List<MmMedia>> _future;
  final _caption = TextEditingController();
  Uint8List? _lastPreview;
  final _imageService = ImageService();

  String get _shareUrl => widget.event.galleryUrl(AppConfig.appUrl);

  @override
  void initState() { super.initState(); _future = RepositoryProvider.instance.loadMedia(widget.event.id); }
  Future<void> _refresh() async => setState(() => _future = RepositoryProvider.instance.loadMedia(widget.event.id));

  Future<void> _upload({bool camera = false}) async {
    try {
      final img = await _imageService.pickAndCompress(camera: camera);
      if (img == null) return;
      setState(() => _lastPreview = img.previewBytes);
      await RepositoryProvider.instance.uploadPhoto(eventId: widget.event.id, image: img, caption: _caption.text.trim());
      _caption.clear();
      showMmSnack(context, 'Photo uploaded. It will appear after approval.');
      _refresh();
    } catch (e) {
      showMmSnack(context, friendlyError(e), error: true);
    }
  }

  Future<void> _chooseUploadSource() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: MmColors.roseDark.withOpacity(.18), blurRadius: 30, offset: const Offset(0, 16))]),
        child: SafeArea(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('Add a memory', subtitle: 'Choose from your gallery or open the Memory Maker camera.'),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () { Navigator.pop(context); _upload(camera: false); }, icon: const Icon(Icons.photo_library_outlined), label: const Text('Choose from Gallery')),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(onPressed: () { Navigator.pop(context); _upload(camera: true); }, icon: const Icon(Icons.camera_alt_outlined), label: const Text('Open Memory Maker Camera')),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close), label: const Text('Cancel')),
        ])),
      ),
    );
  }

  Future<void> _shareQr() async {
    await Share.share('Join my Memory Maker gallery: $_shareUrl');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.event.title, style: const TextStyle(fontWeight: FontWeight.w900)), actions: [IconButton(onPressed: _shareQr, icon: const Icon(Icons.ios_share_rounded))]),
    body: MmGradientBackground(child: RefreshIndicator(onRefresh: () async => _refresh(), child: ListView(padding: const EdgeInsets.all(18), children: [
      MmCard(child: Column(children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.event.title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 21)),
            Text('${widget.event.kind} • Beta gallery', style: const TextStyle(color: MmColors.muted)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: MmColors.blush, borderRadius: BorderRadius.circular(99)), child: const Text('ACTIVE', style: TextStyle(fontWeight: FontWeight.w900, color: MmColors.roseDark))),
        ]),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: MmColors.ivory, borderRadius: BorderRadius.circular(24)), child: QrImageView(data: _shareUrl, size: 180, backgroundColor: Colors.white)),
        const SizedBox(height: 10),
        Text(_shareUrl, textAlign: TextAlign.center, style: const TextStyle(color: MmColors.muted, fontSize: 12)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _shareQr, icon: const Icon(Icons.share), label: const Text('Share QR'))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(onPressed: () => showMmSnack(context, 'Print QR from your phone share/print menu.'), icon: const Icon(Icons.print), label: const Text('Print'))),
        ]),
      ])),
      const SizedBox(height: 18),
      MmCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionTitle('Upload memory', subtitle: 'Use gallery or Memory Maker camera. Photos are compressed before upload to reduce storage.'),
        const SizedBox(height: 14),
        TextField(controller: _caption, decoration: const InputDecoration(labelText: 'Caption or memory note', prefixIcon: Icon(Icons.notes_outlined))),
        const SizedBox(height: 12),
        if (_lastPreview != null) ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.memory(_lastPreview!, height: 150, fit: BoxFit.cover)),
        if (_lastPreview != null) const SizedBox(height: 12),
        FilledButton.icon(onPressed: _chooseUploadSource, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Add Photo or Open Camera')),
      ])),
      const SizedBox(height: 18),
      const SectionTitle('Gallery', subtitle: 'Pending and approved memories from this event.'),
      const SizedBox(height: 12),
      FutureBuilder<List<MmMedia>>(future: _future, builder: (context, snap) {
        final media = snap.data ?? [];
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()));
        if (media.isEmpty) return const EmptyState(icon: Icons.photo_outlined, title: 'No uploads yet', body: 'Upload from camera or gallery to test the flow.');
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: media.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MediaPreviewScreen(media: media[i]))),
            child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: [BoxShadow(color: MmColors.roseDark.withOpacity(.08), blurRadius: 16, offset: const Offset(0, 8))]), child: ClipRRect(borderRadius: BorderRadius.circular(22), child: Stack(fit: StackFit.expand, children: [
              if (imageProviderFromValue(media[i].url) != null) Image(image: imageProviderFromValue(media[i].url)!, fit: BoxFit.cover) else const Icon(Icons.image, size: 48, color: MmColors.roseDark),
              Positioned(left: 8, bottom: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(99)), child: Text(media[i].status, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)))),
            ]))),
          ),
        );
      }),
    ]))),
  );
}
