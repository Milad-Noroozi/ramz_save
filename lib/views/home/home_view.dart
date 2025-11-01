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
    return Scaffold(
      body: Column(
        children: [
          // 🟪 بخش ثابت بالایی
          Container(
            height: MediaQuery.of(context).size.height * 0.49,
            width: double.infinity,
            color: AppColors.darkBgSeccondry,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // user Icon and welcome
                        Row(
                          children: [
                            Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: AppColors.darkBgTertiary,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SvgPicture.asset(
                                  'assets/svg/circle-user.svg',
                                  width: 15,
                                  height: 15,
                                  colorFilter: ColorFilter.mode(
                                    AppColors.textSecondary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10),
                              child: Column(
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
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // setting
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: AppColors.darkBgTertiary,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              'assets/svg/settings.svg',
                              width: 15,
                              height: 15,
                              colorFilter: ColorFilter.mode(
                                AppColors.textSecondary,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // نمودار امنیت
                  const SafetyScoreGauge(percentage: 66, label: 'Safety Score'),

                  // سه کارت بالایی
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      totalPasswordMainPage(),
                      totalPasswordMainPage(),
                      totalPasswordMainPage(),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ************************************
          // 🟩 بخش پایین — قابل اسکرول
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // نمونه محتوا
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.darkBgTertiary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.darkBgTertiary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.darkBgTertiary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class totalPasswordMainPage extends StatelessWidget {
  const totalPasswordMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 125,
      height: 135,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: AppColors.darkBgTertiary,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(100)),
              border: Border.all(width: 1, color: AppColors.textHint),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: SvgPicture.asset(
                'assets/svg/settings.svg',
                width: 15,
                height: 15,
                colorFilter: ColorFilter.mode(
                  AppColors.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Browser",
            style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
          ),
          const Text("21 Password"),
        ],
      ),
    );
  }
}
