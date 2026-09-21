import 'package:flutter/material.dart';

class TopTitle extends StatelessWidget {
  const new({required this.title, this.badge, this.onCalendarTap, super.key});

  final String title;
  final String? badge;
  final VoidCallback? onCalendarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF102B73),
            fontSize: 25,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (badge != null) ...<Widget>[
          const SizedBox(width: 9),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F0FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge!,
              style: const TextStyle(
                color: Color(0xFF1747B5),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (onCalendarTap == null)
          const Icon(Icons.calendar_month_outlined, color: Color(0xFF1747B5))
        else
          IconButton.filledTonal(
            tooltip: 'Chọn ngày',
            onPressed: onCalendarTap,
            style: IconButton.styleFrom(
              foregroundColor: const Color(0xFF1747B5),
              backgroundColor: const Color(0xFFEEF4FF),
            ),
            icon: const Icon(Icons.calendar_month_outlined),
          ),
      ],
    );
  }
}

class MetaLine extends StatelessWidget {
  const new({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 15, color: const Color(0xFF6F7FA2)),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF6F7FA2), fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const new({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 52, color: const Color(0xFFA4B2CE)),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF244584),
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF7A88A7),
                height: 1.45,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhoneSurface extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SizedBox.expand(child: child),
    );
  }
}

class AppMark extends StatelessWidget {
  const new({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .2),
        border: Border.all(color: const Color(0xFF183F9C), width: size * .08),
      ),
      child: Icon(
        Icons.check_rounded,
        size: size * .62,
        color: const Color(0xFF183F9C),
      ),
    );
  }
}

class MicrosoftMark extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 25,
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: <Widget>[
          _MicrosoftTile(Color(0xFFF25022)),
          _MicrosoftTile(Color(0xFF7FBA00)),
          _MicrosoftTile(Color(0xFF00A4EF)),
          _MicrosoftTile(Color(0xFFFFB900)),
        ],
      ),
    );
  }
}

class _MicrosoftTile extends StatelessWidget {
  const new(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(dimension: 11.5, child: ColoredBox(color: color));
  }
}
