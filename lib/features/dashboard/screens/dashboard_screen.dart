import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../app/routes.dart';
import '../../../l10n/app_localizations.dart';
import '../../matching/services/scheduled_matching_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late PageController _noticePageController;
  late Timer _noticeTimer;
  int _currentNoticeIndex = 0;

  List<Map<String, String>> _getNotices(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      {
        'title': l10n.noticeEarlyAdopterTitle,
        'description': l10n.noticeEarlyAdopterDesc
      },
      {
        'title': l10n.noticeWelcomeTitle,
        'description': l10n.noticeWelcomeDesc
      },
      {
        'title': l10n.noticeServiceLaunchTitle,
        'description': l10n.noticeServiceLaunchDesc
      },
      {
        'title': l10n.noticeRealtimeChatTitle,
        'description': l10n.noticeRealtimeChatDesc
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _noticePageController = PageController();
    _startNoticeTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _noticeTimer.cancel();
    _noticePageController.dispose();
    super.dispose();
  }

  void _startNoticeTimer() {
    _noticeTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        final noticesLength = _getNotices(context).length;
        _currentNoticeIndex = (_currentNoticeIndex + 1) % noticesLength;
        _noticePageController.animateToPage(
          _currentNoticeIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _loadData() {
    final matchingService = Provider.of<ScheduledMatchingService>(context, listen: false);
    matchingService.getTodaysMatches();
    matchingService.getPastMatches();

    // 매칭 알림은 이제 Edge Function에서 자동으로 처리됨
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(6, 13, 24, 1),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                title: Text(
                  '💕 Hearty',
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNoticesSection(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildMatchingSummarySection(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildMatchingTipsSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildNoticesSection() {
    final l10n = AppLocalizations.of(context)!;
    final notices = _getNotices(context);

    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.campaign_outlined,
                  color: Colors.grey[400],
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.news,
                  style: AppTextStyles.body1.copyWith(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Row(
                  children: List.generate(notices.length, (index) {
                    return Container(
                      margin: const EdgeInsets.only(left: 4),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentNoticeIndex == index
                            ? Colors.grey[400]
                            : Colors.grey[600]?.withOpacity(0.4),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: SizedBox(
              height: 90,
              child: PageView.builder(
                controller: _noticePageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentNoticeIndex = index;
                  });
                },
                itemCount: notices.length,
                itemBuilder: (context, index) {
                  final notice = notices[index];
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'NEW',
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                notice['title']!,
                                style: AppTextStyles.body1.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.95),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            notice['description']!,
                            style: AppTextStyles.body2.copyWith(
                              color: Colors.white.withOpacity(0.7),
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingSummarySection() {
    return Consumer<ScheduledMatchingService>(
      builder: (context, matchingService, child) {
        final todaysMatches = matchingService.todaysMatches;
        final isLoading = matchingService.isLoading;

        return Container(
          width: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      AppLocalizations.of(context)!.matchingTitle,
                      style: AppTextStyles.body1.copyWith(
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : todaysMatches.isEmpty
                        ? _buildNoMatchesCard()
                        : _buildTodaysMatchCard(todaysMatches.first),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoMatchesCard() {
    final l10n = AppLocalizations.of(context)!;

    return IntrinsicHeight(
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
            child: Icon(
              Icons.favorite_outline,
              color: Colors.white.withOpacity(0.6),
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.waitForRecommendation,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.newMatchAtNoon,
                  style: AppTextStyles.body2.copyWith(
                    color: Colors.white.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodaysMatchCard(ScheduledMatch match) {
    final l10n = AppLocalizations.of(context)!;
    final otherUser = match.otherUserProfile;
    final age = Provider.of<ScheduledMatchingService>(context, listen: false)
        .calculateAge(otherUser['birth_date'] ?? '2000-01-01');

    final matchingService = Provider.of<ScheduledMatchingService>(context, listen: false);
    final profileImages = matchingService.getUserImages(otherUser);

    return GestureDetector(
      onTap: () {
        // 추천 탭으로 이동
        context.go(AppRoutes.recommendations);
      },
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.transparent,
        ),
        child: Row(
          children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              image: profileImages.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(profileImages.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profileImages.isEmpty
                ? Icon(
                    Icons.person,
                    color: Colors.white.withOpacity(0.6),
                    size: 30,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.userAgeYears(otherUser['nickname'] ?? l10n.unknown, age),
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  match.status == 'mutual_like'
                    ? l10n.mutualInterest
                    : match.receivedLike
                      ? l10n.receivedInterest
                      : match.sentLike
                        ? l10n.sentInterest
                        : l10n.newMatchWaiting,
                  style: AppTextStyles.body2.copyWith(
                    color: (match.receivedLike || match.sentLike)
                        ? Color(0xFFf093fb)
                        : Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // 화살표 아이콘 추가
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.white.withOpacity(0.5),
          ),
          ],
        ),
      ),
    );
  }


  Widget _buildMatchingTipsSection() {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.grey[400],
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.matchingTips,
                  style: AppTextStyles.body1.copyWith(
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              children: [
                _buildTipCard(
                  icon: Icons.photo_camera_outlined,
                  title: l10n.tipProfilePhotoTitle,
                  description: l10n.tipProfilePhotoDesc,
                  color: Color(0xFFf093fb),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildTipCard(
                  icon: Icons.favorite_outline,
                  title: l10n.tipInterestsTitle,
                  description: l10n.tipInterestsDesc,
                  color: Color(0xFF667eea),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildTipCard(
                  icon: Icons.chat_bubble_outline,
                  title: l10n.tipFirstMessageTitle,
                  description: l10n.tipFirstMessageDesc,
                  color: Color(0xFF43e97b),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 22,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.95),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: AppTextStyles.body2.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}