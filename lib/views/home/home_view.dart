import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ramz_save/config/app_colors.dart';
import 'package:ramz_save/views/widgets/safety_score_gauge.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      body: Column(
        children: [
          // 🟣 بخش بالایی (ثابت)
          Container(
            width: double.infinity,
            height: height * 0.49,
            color: AppColors.darkBgSeccondry,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // آیکن کاربر + خوش‌آمدگویی
                      Row(
                        children: [
                          Container(
                            width: 45,
                            height: 45,
                            decoration: BoxDecoration(
                              color: AppColors.darkBgTertiary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: SvgPicture.asset(
                              'assets/svg/circle-user.svg',
                              colorFilter: ColorFilter.mode(
                                AppColors.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome back",
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                "Milad Noroozi",
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // آیکن تنظیمات
                      Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: AppColors.darkBgTertiary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: SvgPicture.asset(
                          'assets/svg/settings.svg',
                          colorFilter: ColorFilter.mode(
                            AppColors.textSecondary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // نمودار امنیت
                const SafetyScoreGauge(percentage: 66, label: 'Safety Score'),

                const SizedBox(height: 15),

                // کارت‌های بالایی
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    TotalPasswordCard(),
                    TotalPasswordCard(),
                    TotalPasswordCard(),
                  ],
                ),
              ],
            ),
          ),

          // 🟩 تیتر "Top Vault" (ثابت، خارج از Scroll)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Top Vault",
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                InkWell(
                  onTap: () {
                    // Handle tap event here
                  },
                  child: Text(
                    "View All",
                    style: TextStyle(color: AppColors.green, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),

          // 🩵 لیست اسکرول
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                children: List.generate(
                  10,
                  (index) => Container(
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.darkBgTertiary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SvgPicture.asset(
                                'assets/svg/site-alt.svg',
                                height: 30,
                                width: 30,
                                colorFilter: ColorFilter.mode(
                                  AppColors.textSecondary,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "webdenj",
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    "www.webdenj.com",
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          // آیکن تنظیمات
                          SizedBox(
                            width: 25,
                            height: 25,
                            child: SvgPicture.asset(
                              'assets/svg/copy-alt.svg',
                              colorFilter: ColorFilter.mode(
                                AppColors.textHint,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TotalPasswordCard extends StatelessWidget {
  const TotalPasswordCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 130,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.darkBgTertiary,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: 1, color: AppColors.textHint),
            ),
            padding: const EdgeInsets.all(10),
            child: SvgPicture.asset(
              'assets/svg/settings.svg',
              colorFilter: ColorFilter.mode(
                AppColors.textSecondary,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Browser",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            "21 Password",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
