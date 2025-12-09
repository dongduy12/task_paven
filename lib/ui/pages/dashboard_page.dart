import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task_paven/models/task.dart';
import 'package:task_paven/ui/theme.dart';

import '../../controllers/task_controller.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.taskController});

  final TaskController taskController;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

enum _StatsRange { week, month }

class _DashboardPageState extends State<DashboardPage> {
  _StatsRange _range = _StatsRange.week;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tasks = widget.taskController.taskList.toList();
      final completed = tasks.where((task) => task.isCompleted == 1).length;
      final pending = tasks.where((task) => task.isCompleted != 1).length;
      final overdue = tasks.where(_isOverdue).length;
      final buckets = _range == _StatsRange.week
          ? _weeklyBuckets(tasks)
          : _monthlyBuckets(tasks);

      return RefreshIndicator(
        onRefresh: widget.taskController.getTasks,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('dashboard_overview'.tr, style: headingStyle),
              const SizedBox(height: 12),
              _SummaryGrid(
                completed: completed,
                pending: pending,
                overdue: overdue,
              ),
              const SizedBox(height: 24),
              _buildRangeSelector(),
              const SizedBox(height: 12),
              _ProgressChart(buckets: buckets),
              if (tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'dashboard_empty'.tr,
                    style: subTitleStyle,
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _range == _StatsRange.week
              ? 'dashboard_performance_week'.tr
              : 'dashboard_performance_month'.tr,
          style: titleStyle,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text('dashboard_week'.tr),
              selected: _range == _StatsRange.week,
              onSelected: (_) => setState(() => _range = _StatsRange.week),
            ),
            ChoiceChip(
              label: Text('dashboard_month'.tr),
              selected: _range == _StatsRange.month,
              onSelected: (_) => setState(() => _range = _StatsRange.month),
            ),
          ],
        )
      ],
    );
  }

  bool _isOverdue(Task task) {
    if (task.isCompleted == 1 || task.date == null) return false;
    try {
      final taskDate = DateFormat.yMd().parse(task.date!);
      final today = _asDate(DateTime.now());
      return taskDate.isBefore(today);
    } catch (_) {
      return false;
    }
  }

  List<_ChartBucket> _weeklyBuckets(List<Task> tasks) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final isVietnamese = (Get.locale?.languageCode ?? 'en') == 'vi';
    final labels = isVietnamese
        ? ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return List.generate(7, (index) {
      final day = _asDate(startOfWeek.add(Duration(days: index)));
      final completed = tasks
          .where((task) => task.isCompleted == 1 && _occursOn(task, day))
          .length;
      final pending = tasks
          .where((task) => task.isCompleted != 1 && _occursOn(task, day))
          .length;
      return _ChartBucket(labels[index], completed, pending);
    });
  }

  List<_ChartBucket> _monthlyBuckets(List<Task> tasks) {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final totalDays = endOfMonth.day;
    final weekLabel = 'dashboard_week'.tr;
    final buckets =
        List.generate(5, (index) => _ChartBucket('$weekLabel ${index + 1}', 0, 0));

    for (int day = 0; day < totalDays; day++) {
      final date = _asDate(startOfMonth.add(Duration(days: day)));
      final bucketIndex = min(day ~/ 7, buckets.length - 1);

      for (final task in tasks) {
        if (_occursOn(task, date)) {
          if (task.isCompleted == 1) {
            buckets[bucketIndex] = buckets[bucketIndex].copyWith(
              completed: buckets[bucketIndex].completed + 1,
            );
          } else {
            buckets[bucketIndex] = buckets[bucketIndex].copyWith(
              pending: buckets[bucketIndex].pending + 1,
            );
          }
        }
      }
    }

    return buckets;
  }

  bool _occursOn(Task task, DateTime day) {
    if (task.date == null) return false;
    final formatted = DateFormat.yMd().format(day);

    if (task.repeat == 'Daily') return true;
    if (task.date == formatted) return true;

    try {
      final taskDate = DateFormat.yMd().parse(task.date!);
      final difference = day.difference(taskDate).inDays;

      if (difference < 0) return false;

      if (task.repeat == 'Weekly' && difference % 7 == 0) {
        return true;
      }

      if (task.repeat == 'Monthly' && taskDate.day == day.day) {
        return true;
      }
    } catch (_) {
      return false;
    }

    return false;
  }

  DateTime _asDate(DateTime dateTime) => DateTime(dateTime.year, dateTime.month, dateTime.day);
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.completed,
    required this.pending,
    required this.overdue,
  });

  final int completed;
  final int pending;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    final cardColor = Get.isDarkMode ? darkHeaderClr : Colors.white;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'summary_completed'.tr,
                value: completed,
                icon: Icons.check_circle_outline,
                color: primaryClr,
                background: cardColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'summary_pending'.tr,
                value: pending,
                icon: Icons.pending_actions_outlined,
                color: Colors.orangeAccent,
                background: cardColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          title: 'summary_overdue'.tr,
          value: overdue,
          icon: Icons.warning_amber_rounded,
          color: Colors.redAccent,
          background: cardColor,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Get.isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: subTitleStyle),
                const SizedBox(height: 4),
                Text(
                  '$value',
                  style: headingStyle.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressChart extends StatelessWidget {
  const _ProgressChart({required this.buckets});

  final List<_ChartBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxValue = buckets.isEmpty
        ? 1
        : buckets.map((b) => b.total).fold<int>(1, (prev, value) => max(prev, value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Get.isDarkMode ? darkHeaderClr : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryClr.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          _buildLegend(),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: buckets
                  .map((bucket) => Expanded(
                        child: _Bar(bucket: bucket, maxValue: maxValue),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: const [
        _LegendDot(color: primaryClr, label: 'Hoàn thành'),
        SizedBox(width: 12),
        _LegendDot(color: Colors.orangeAccent, label: 'Chưa xong'),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.bucket, required this.maxValue});

  final _ChartBucket bucket;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const labelSpacing = 8.0;
          const labelHeight = 38.0; // rough space for top & bottom labels
          final barAreaHeight = max(0.0, constraints.maxHeight - (labelHeight + labelSpacing * 2));

          final completedHeight = (bucket.completed / maxValue) * barAreaHeight;
          final pendingHeight = (bucket.pending / maxValue) * barAreaHeight;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                bucket.label,
                style: subTitleStyle,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: labelSpacing),
              SizedBox(
                height: barAreaHeight,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (pendingHeight > 0)
                        Container(
                          height: pendingHeight,
                          decoration: BoxDecoration(
                            color: Colors.orangeAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      if (pendingHeight > 0 && completedHeight > 0)
                        const SizedBox(height: 4),
                      if (completedHeight > 0)
                        Container(
                          height: completedHeight,
                          decoration: BoxDecoration(
                            color: primaryClr,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: labelSpacing),
              Text(
                bucket.total.toString(),
                style: bodyStyle,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: bodyStyle),
      ],
    );
  }
}

class _ChartBucket {
  const _ChartBucket(this.label, this.completed, this.pending);

  final String label;
  final int completed;
  final int pending;

  int get total => completed + pending;

  _ChartBucket copyWith({int? completed, int? pending}) {
    return _ChartBucket(label, completed ?? this.completed, pending ?? this.pending);
  }
}
