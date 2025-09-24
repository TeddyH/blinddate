import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
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

  final List<Map<String, String>> _notices = [
    {
      'title': '환영합니다! 🎉',
      'description': '매일 낮 12시에 새로운 인연을 만나보세요. 서로에게 관심이 있다면 채팅을 시작할 수 있어요!'
    },
    {
      'title': '서비스 정식 오픈! 🚀',
      'description': 'Hearty가 정식 서비스를 시작했습니다! 더 나은 매칭을 위해 지속적으로 업데이트하고 있어요.'
    },
    {
      'title': '실시간 채팅 오픈! 💬',
      'description': '상호 좋아요 시 실시간 채팅이 가능합니다. 첫 메시지로 인사를 나눠보세요!'
    },
  ];

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
        _currentNoticeIndex = (_currentNoticeIndex + 1) % _notices.length;
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          child: Column(
            children: [
              AppBar(
                title: Text(
                  '💕 Hearty',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.accent,
                elevation: 0,
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _loadData(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildNoticesSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha:0.1), AppColors.accent.withValues(alpha:0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha:0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.campaign_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '새 소식',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: List.generate(_notices.length, (index) {
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentNoticeIndex == index
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha:0.3),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PageView.builder(
              controller: _noticePageController,
              onPageChanged: (index) {
                setState(() {
                  _currentNoticeIndex = index;
                });
              },
              itemCount: _notices.length,
              itemBuilder: (context, index) {
                final notice = _notices[index];
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
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
                                color: AppColors.textPrimary,
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
                            color: AppColors.textSecondary,
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
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.accent.withValues(alpha:0.1), AppColors.primary.withValues(alpha:0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '오늘의 매칭',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
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
    return Column(
      children: [
        Icon(
          Icons.favorite_outline,
          color: AppColors.textSecondary,
          size: 48,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '오늘의 추천을 기다려보세요',
          style: AppTextStyles.body1.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '매일 낮 12시에 새로운 인연이 찾아와요',
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysMatchCard(ScheduledMatch match) {
    final otherUser = match.otherUserProfile;
    final age = Provider.of<ScheduledMatchingService>(context, listen: false)
        .calculateAge(otherUser['birth_date'] ?? '2000-01-01');

    final matchingService = Provider.of<ScheduledMatchingService>(context, listen: false);
    final profileImages = matchingService.getUserImages(otherUser);

    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha:0.2),
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
                  color: AppColors.accent,
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
                '${otherUser['nickname'] ?? '알 수 없음'}, $age세',
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                match.status == 'mutual_like' ? '서로 관심을 표현했어요! 💕' : '새로운 인연이 기다리고 있어요',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Icon(
          match.status == 'mutual_like' ? Icons.favorite : Icons.favorite_border,
          color: match.status == 'mutual_like' ? AppColors.accent : AppColors.textSecondary,
        ),
      ],
    );
  }


  Widget _buildMatchingTipsSection() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF009688).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF009688).withValues(alpha:0.08), const Color(0xFF009688).withValues(alpha:0.18)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: const Color(0xFF009688),
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '매칭 팁',
                  style: AppTextStyles.body1.copyWith(
                    color: const Color(0xFF009688),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _buildTipCard(
                  icon: Icons.photo_camera_outlined,
                  title: '매력적인 프로필 사진',
                  description: '자연스러운 미소와 밝은 조명의 사진을 업로드하세요',
                  color: AppColors.accent,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildTipCard(
                  icon: Icons.favorite_outline,
                  title: '관심사 업데이트',
                  description: '취미와 관심사를 자주 업데이트하면 더 좋은 매칭을 받을 수 있어요',
                  color: AppColors.primary,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildTipCard(
                  icon: Icons.chat_bubble_outline,
                  title: '첫 메시지 작성법',
                  description: '상대방의 프로필을 보고 공통 관심사로 대화를 시작해보세요',
                  color: AppColors.success,
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
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}