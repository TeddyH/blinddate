import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../services/scheduled_matching_service.dart';
import '../widgets/scheduled_match_card.dart';
import '../widgets/match_success_dialog.dart';

class ScheduledHomeScreen extends StatefulWidget {
  const ScheduledHomeScreen({super.key});

  @override
  State<ScheduledHomeScreen> createState() => _ScheduledHomeScreenState();
}

class _ScheduledHomeScreenState extends State<ScheduledHomeScreen> {
  Timer? _countdownTimer;

  // 이미 표시된 매칭 성공 다이얼로그 ID 저장 (중복 방지)
  final Set<String> _shownMatchDialogs = {};

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

    // Check for mutual matches and show celebration dialog
    _checkAndShowMutualMatchDialog();
  }

  void _checkAndShowMutualMatchDialog() {
    final service = context.read<ScheduledMatchingService>();
    final mutualMatches = service.todaysMatches.where((match) => match.status == 'mutual_like').toList();

    if (mutualMatches.isNotEmpty && mounted) {
      // Show dialog for the first mutual match (always show when entering the page)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showMatchSuccessDialog(mutualMatches.first);
        }
      });
    }
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '💕 Hearty',
              style: AppTextStyles.h1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                l10n.matchingTitle,
                style: AppTextStyles.body2.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(6, 13, 24, 1),
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
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.matchingLoading,
            style: AppTextStyles.body1.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final l10n = AppLocalizations.of(context)!;

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
              l10n.errorLoadingMatch,
              style: AppTextStyles.h3.copyWith(
                color: Colors.white.withOpacity(0.95),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              error,
              style: AppTextStyles.body2.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: _loadTodaysMatches,
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchesState(bool isRevealTime, Duration timeUntilReveal) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Clock icon
            Icon(
              Icons.schedule,
              size: 80,
              color: Colors.pink,
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              l10n.noMatchToday,
              style: AppTextStyles.h2.copyWith(
                color: Colors.white.withOpacity(0.95),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              l10n.noMatchTodayDesc,
              style: AppTextStyles.body1.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Countdown - 항상 표시
            Column(
              children: [
                Text(
                  l10n.untilNextMatch,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCountdown(timeUntilReveal),
                  style: AppTextStyles.h1.copyWith(
                    color: Color(0xFFf093fb),
                    fontWeight: FontWeight.bold,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesView(List<ScheduledMatch> matches, bool isRevealTime, Duration timeUntilReveal) {
    // revealed 또는 mutual_like 상태인 매치들을 표시 가능한 매치로 분류
    final displayableMatches = matches.where((m) => m.isRevealed || m.status == 'mutual_like').toList();
    final pendingMatches = matches.where((m) => m.isPending).toList();

    return Column(
      children: [
        // Status header
        if (!isRevealTime && pendingMatches.isNotEmpty && displayableMatches.isEmpty)
          _buildCountdownHeader(timeUntilReveal),

        // Matches list
        Expanded(
          child: displayableMatches.isNotEmpty
              ? _buildRevealedMatches(displayableMatches)
              : _buildPendingMatches(pendingMatches, isRevealTime),
        ),
      ],
    );
  }

  Widget _buildCountdownHeader(Duration timeUntilReveal) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Color(0xFF252836),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.matchReady,
            style: AppTextStyles.h3.copyWith(
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.revealAtNoon,
            style: AppTextStyles.body1.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _formatCountdown(timeUntilReveal),
            style: AppTextStyles.h1.copyWith(
              color: Color(0xFFf093fb),
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
            onLike: () => _handleMatchAction(match, AppConstants.actionLike),
            onPass: () => _handleMatchAction(match, AppConstants.actionPass),
          ),
        );
      },
    );
  }

  Widget _buildPendingMatches(List<ScheduledMatch> matches, bool isRevealTime) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_clock,
              size: 80,
              color: Colors.pink,
            ),

            const SizedBox(height: AppSpacing.xl),

            Text(
              l10n.matchReadyShort,
              style: AppTextStyles.h2.copyWith(
                color: Colors.white.withOpacity(0.95),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              l10n.matchPendingDesc(matches.length),
              style: AppTextStyles.body1.copyWith(
                color: Colors.white.withOpacity(0.7),
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

      // 액션 전 매치 상태 저장
      final wasNotMutualLike = match.status != 'mutual_like';

      await service.recordMatchInteraction(
        matchId: match.id,
        action: action,
      );

      if (mounted) {
        // 매치 상태를 새로 확인
        await _loadTodaysMatches();

        // 매칭 성공 여부 확인
        final updatedMatches = service.todaysMatches;
        final updatedMatch = updatedMatches.firstWhere(
          (m) => m.id == match.id,
          orElse: () => match,
        );

        // 좋아요를 보냈고, 상호 매칭이 완성된 경우
        if (action == AppConstants.actionLike && wasNotMutualLike && updatedMatch.status == 'mutual_like') {
          _showMatchSuccessDialog(updatedMatch);
        } else {
          // 일반적인 액션 피드백
          final l10n = AppLocalizations.of(context)!;
          final message = action == AppConstants.actionLike ? l10n.likeSent : l10n.passMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: action == AppConstants.actionLike ? AppColors.accent : AppColors.textSecondary,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOccurred(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showMatchSuccessDialog(ScheduledMatch match) {
    // 중복 다이얼로그 방지
    if (_shownMatchDialogs.contains(match.id)) {
      debugPrint('⚠️ 이미 표시된 매칭 성공 다이얼로그: ${match.id}');
      return;
    }

    debugPrint('✅ 매칭 성공 다이얼로그 표시: ${match.id}');
    _shownMatchDialogs.add(match.id);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return MatchSuccessDialog(
          match: match,
          onStartChat: () {
            Navigator.of(context).pop();
            // 채팅 탭으로 이동
            context.go(AppRoutes.chatList);
          },
        );
      },
    );
  }
}