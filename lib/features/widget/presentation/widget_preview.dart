import 'package:better_phenikaa_schedule/core/utils/date_time_formatters.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:flutter/material.dart';

class WidgetPreview extends StatelessWidget {
  const new({required this.item, super.key});

  final ScheduleRecord item;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Widget 1×4',
          style: TextStyle(
            color: Color(0xFF18336F),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF173A8E), Color(0xFF315AB5)],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.subjectName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white70,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item.room,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.access_time_rounded,
                    color: Colors.white70,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${formatTime(item.startAt)} - ${formatTime(item.endAt)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
