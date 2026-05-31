import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/app_models.dart';
import '../theme.dart';

class MediaPreviewScreen extends StatelessWidget {
  final MmMedia media;
  const MediaPreviewScreen({super.key, required this.media});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF1E171A),
    appBar: AppBar(foregroundColor: Colors.white, backgroundColor: Colors.transparent, title: Text(media.filename), actions: [
      IconButton(onPressed: () => Share.share(media.url ?? media.filename), icon: const Icon(Icons.share)),
      IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use device print/share menu to print this image.'))), icon: const Icon(Icons.print)),
    ]),
    body: Center(child: media.url == null ? const Icon(Icons.image, color: Colors.white, size: 80) : InteractiveViewer(child: Image.network(media.url!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: MmColors.blush, size: 80)))),
    bottomNavigationBar: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Text(media.caption ?? 'High quality preview', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)))),
  );
}
