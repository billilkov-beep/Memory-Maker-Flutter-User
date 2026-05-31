import 'package:flutter/material.dart';
import '../theme.dart';

class MmGradientBackground extends StatelessWidget {
  final Widget child;
  const MmGradientBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [MmColors.ivory, Color(0xFFFFEFEA), Color(0xFFFFFAF5)]),
      ),
      child: child,
    );
  }
}

class MmCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const MmCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.onTap});
  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: MmColors.blush.withOpacity(.9)),
        boxShadow: [BoxShadow(color: MmColors.roseDark.withOpacity(.08), blurRadius: 24, offset: const Offset(0, 12))],
      ),
      child: child,
    );
    return onTap == null ? card : InkWell(borderRadius: BorderRadius.circular(28), onTap: onTap, child: card);
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionTitle(this.title, {super.key, this.subtitle, this.trailing});
  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: MmColors.ink)),
              if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(subtitle!, style: const TextStyle(color: MmColors.muted))),
            ]),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const EmptyState({super.key, required this.icon, required this.title, required this.body});
  @override
  Widget build(BuildContext context) => MmCard(
        child: Column(children: [
          CircleAvatar(radius: 28, backgroundColor: MmColors.blush, child: Icon(icon, color: MmColors.roseDark)),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center, style: const TextStyle(color: MmColors.muted)),
        ]),
      );
}

void showMmSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    backgroundColor: error ? const Color(0xFF9E2F3B) : MmColors.roseDark,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ));
}
