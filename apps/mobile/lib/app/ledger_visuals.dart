import 'package:flutter/material.dart';
import 'package:smart_ledger/app/ledger_theme.dart';

IconData categoryIcon(String name) => switch (name) {
  '餐饮' => Icons.restaurant_rounded,
  '交通' => Icons.directions_bus_rounded,
  '购物' => Icons.shopping_bag_rounded,
  '住房' => Icons.home_rounded,
  '日用' => Icons.local_mall_rounded,
  '娱乐' => Icons.movie_rounded,
  '医疗' => Icons.medical_services_rounded,
  '教育' => Icons.school_rounded,
  '通讯' => Icons.phone_rounded,
  '水电燃气' => Icons.bolt_rounded,
  '人情礼物' || '红包礼金' => Icons.card_giftcard_rounded,
  '旅行' => Icons.luggage_rounded,
  '宠物' => Icons.pets_rounded,
  '工资' => Icons.work_rounded,
  '奖金' => Icons.workspace_premium_rounded,
  '兼职' => Icons.schedule_rounded,
  '理财收益' => Icons.trending_up_rounded,
  '报销' => Icons.receipt_long_rounded,
  '退款' => Icons.replay_circle_filled_rounded,
  _ => Icons.category_rounded,
};

Color categoryTint(String name) {
  final palette = [
    LedgerPalette.coralSoft,
    LedgerPalette.mintSoft,
    LedgerPalette.honeySoft,
    LedgerPalette.skySoft,
  ];
  return palette[name.runes.fold(0, (sum, rune) => sum + rune) %
      palette.length];
}

class LedgerBuddy extends StatelessWidget {
  const LedgerBuddy({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: LedgerPalette.mintSoft,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A6A5145),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.sentiment_satisfied_alt_rounded,
              color: LedgerPalette.mint,
              size: size * .58,
            ),
          ),
        ),
        Positioned(
          right: -2,
          bottom: 0,
          child: Container(
            width: size * .34,
            height: size * .34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: LedgerPalette.honey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              '¥',
              style: TextStyle(
                color: LedgerPalette.ink,
                fontSize: size * .18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
