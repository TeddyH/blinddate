import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../services/scheduled_matching_service.dart';
import '../widgets/match_history_card.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPastMatches();
    });
  }

  Future<void> _loadPastMatches() async {
    final service = context.read<ScheduledMatchingService>();
    await service.getPastMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Hearty',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                '지난 일주일',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.accent.withValues(alpha: 0.03),
              AppColors.accent.withValues(alpha: 0.08),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Consumer<ScheduledMatchingService>(
          builder: (context, service, child) {
            if (service.isLoading) {
              return _buildLoadingState();
            }

            if (service.errorMessage != null) {
              return _buildErrorState(service.errorMessage!);
            }

            final pastMatches = service.pastMatches;

            if (pastMatches.isEmpty) {
              return _buildEmptyState();
            }

            return _buildMatchesHistory(pastMatches);
          },
        ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '최근 일주일 추천 기록을 불러오고 있어요...',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '기록을 불러오는 중 오류가 발생했습니다',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              error,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _loadPastMatches,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '최근 일주일 추천이 없어요',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              '매일 새로운 인연을 만나보세요!\n최근 7일간의 추천 기록을 여기서 확인할 수 있어요.',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: _loadPastMatches,
              child: const Text('새로고침'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesHistory(List<ScheduledMatch> matches) {
    // Group matches by date
    final Map<String, List<ScheduledMatch>> groupedMatches = {};

    for (final match in matches) {
      final dateKey = _formatDateKey(match.matchDate);
      if (!groupedMatches.containsKey(dateKey)) {
        groupedMatches[dateKey] = [];
      }
      groupedMatches[dateKey]!.add(match);
    }

    final sortedKeys = groupedMatches.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // 최신 날짜 먼저

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final dayMatches = groupedMatches[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.sm,
                bottom: AppSpacing.md,
                top: index == 0 ? 0 : AppSpacing.lg,
              ),
              child: Text(
                _formatDateHeader(dayMatches.first.matchDate),
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Matches for this date
            ...dayMatches.asMap().entries.map((entry) {
              final matchIndex = entry.key;
              final match = entry.value;

              return Padding(
                padding: EdgeInsets.only(
                  bottom: matchIndex < dayMatches.length - 1 ? AppSpacing.md : 0,
                ),
                child: MatchHistoryCard(match: match),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final currentHour = now.hour;

    // Apply same logic: if before noon, consider yesterday as "today"
    final referenceDate = currentHour < 12 ? now.subtract(const Duration(days: 1)) : now;
    final today = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final matchDate = DateTime(date.year, date.month, date.day);

    if (matchDate == yesterday) {
      return '어제';
    } else if (matchDate.isAfter(today.subtract(const Duration(days: 7)))) {
      final daysAgo = today.difference(matchDate).inDays;
      return '${daysAgo}일 전';
    } else {
      return '${date.month}월 ${date.day}일';
    }
  }
}