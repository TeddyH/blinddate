import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../services/scheduled_matching_service.dart';
import '../widgets/scheduled_match_card.dart';

class ScheduledHomeScreen extends StatefulWidget {
  const ScheduledHomeScreen({super.key});

  @override
  State<ScheduledHomeScreen> createState() => _ScheduledHomeScreenState();
}

class _ScheduledHomeScreenState extends State<ScheduledHomeScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
    // Defer the loading to after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodaysMatches();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTodaysMatches() async {
    final service = context.read<ScheduledMatchingService>();
    await service.getTodaysMatches();

    // Check for newly revealed matches
    await service.checkForRevealedMatches();
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Update countdown display
        });
      }
    });
  }


  String _formatCountdown(Duration duration) {
    if (duration.isNegative) return "00:00:00";

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
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
              '💕 Hearty',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                '오늘의 추천',
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
        foregroundColor: AppColors.accent,
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

            final matches = service.todaysMatches;
            final isRevealTime = service.isRevealTime();
            final timeUntilReveal = service.getTimeUntilNextReveal();

            if (matches.isEmpty) {
              return _buildNoMatchesState(isRevealTime, timeUntilReveal);
            }

            return _buildMatchesView(matches, isRevealTime, timeUntilReveal);
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
            '오늘의 특별한 인연을 확인하고 있어요...',
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
              '매칭 정보를 불러오는 중 오류가 발생했습니다',
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
              onPressed: _loadTodaysMatches,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchesState(bool isRevealTime, Duration timeUntilReveal) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Clock icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.pink.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRevealTime ? Icons.favorite_border : Icons.schedule,
                size: 60,
                color: Colors.pink,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              isRevealTime ? '오늘은 새로운 인연이 없어요' : '곧 새로운 인연을 만날 수 있어요!',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),


            const SizedBox(height: AppSpacing.md),

            if (!isRevealTime) ...[
              Text(
                '매일 낮 12시에 새로운 매칭이 공개됩니다',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.lg),

              // Countdown
              Column(
                children: [
                  Text(
                    '다음 매칭까지',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCountdown(timeUntilReveal),
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                '내일 새로운 분을 소개해드릴게요!',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],

          ],
        ),
      ),
    );
  }

  Widget _buildMatchesView(List<ScheduledMatch> matches, bool isRevealTime, Duration timeUntilReveal) {
    final revealedMatches = matches.where((m) => m.isRevealed).toList();
    final pendingMatches = matches.where((m) => m.isPending).toList();

    return Column(
      children: [
        // Status header
        if (!isRevealTime && pendingMatches.isNotEmpty)
          _buildCountdownHeader(timeUntilReveal),

        // Matches list
        Expanded(
          child: revealedMatches.isNotEmpty
              ? _buildRevealedMatches(revealedMatches)
              : _buildPendingMatches(pendingMatches, isRevealTime),
        ),
      ],
    );
  }

  Widget _buildCountdownHeader(Duration timeUntilReveal) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '🎉 오늘의 매칭이 준비되었어요!',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '낮 12시에 공개됩니다',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _formatCountdown(timeUntilReveal),
            style: AppTextStyles.h1.copyWith(
              color: Colors.pink,
              fontWeight: FontWeight.bold,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealedMatches(List<ScheduledMatch> matches) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < matches.length - 1 ? AppSpacing.lg : 0,
          ),
          child: ScheduledMatchCard(
            match: match,
            onLike: () => _handleMatchAction(match, 'liked'),
            onPass: () => _handleMatchAction(match, 'passed'),
          ),
        );
      },
    );
  }

  Widget _buildPendingMatches(List<ScheduledMatch> matches, bool isRevealTime) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.pink.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_clock,
                size: 60,
                color: Colors.pink,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              '오늘의 매칭이 준비되었어요!',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              '${matches.length}명의 특별한 인연이 기다리고 있어요.\n낮 12시에 공개됩니다.',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMatchAction(ScheduledMatch match, String action) async {
    try {
      final service = context.read<ScheduledMatchingService>();
      await service.recordMatchInteraction(
        matchId: match.id,
        action: action,
      );

      if (mounted) {
        final message = action == 'liked' ? '💖 좋아요를 보냈습니다!' : '다음 기회에 만나요';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: action == 'liked' ? AppColors.accent : AppColors.textSecondary,
            duration: const Duration(seconds: 1),
          ),
        );

        // Refresh matches to get updated status
        await _loadTodaysMatches();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}