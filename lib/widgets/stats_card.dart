import 'package:flutter/material.dart';

class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.smsSentCount,
    required this.totalRequests,
    required this.failedRequests,
  });

  final int smsSentCount;
  final int totalRequests;
  final int failedRequests;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'STATISTICS',
            style: TextStyle(
              color: Color(0xFF808080),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem('Delivered', smsSentCount.toString()),
              ),
              Container(width: 1, height: 40, color: const Color(0xFF404040)),
              Expanded(
                child: _StatItem('Total', totalRequests.toString()),
              ),
              Container(width: 1, height: 40, color: const Color(0xFF404040)),
              Expanded(
                child: _StatItem('Failed', failedRequests.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF808080),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
