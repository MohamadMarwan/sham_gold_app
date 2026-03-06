import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: AppColors.darkGreen,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'سياسة الخصوصية',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.darkGreen, Color(0xFF0D2B22)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                ),
                child: const Center(
                  child: Opacity(
                    opacity: 0.1,
                    child: Icon(Icons.security_rounded,
                        size: 120, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection('مقدمة',
                    'نحن في "غولد شام" نلتزم بحماية خصوصية بياناتك. توضح هذه السياسة كيفية جمعنا واستخدامنا وحماية معلوماتك الشخصية عند استخدامك لتطبيقنا.'),
                _buildSection('المعلومات التي نجمعها',
                    'نقوم بجمع الحد الأدنى من البيانات اللازمة لتشغيل التطبيق، مثل معرف الجهاز لتلقي التنبيهات، وتفضيلاتك (المفضلة) التي تُحفظ محلياً أو لغرض المزامنة.'),
                _buildSection('كيفية استخدام البيانات',
                    'نستخدم البيانات لتحسين تجربة المستخدم، إرسال تنبيهات الأسعار الفورية، وتحليل أداء التطبيق لضمان تقديم أفضل خدمة.'),
                _buildSection('مشاركة البيانات',
                    'نحن لا نبيع أو نشارك معلوماتك الشخصية مع أطراف ثالثة لأغراض تسويقية. يتم استخدام البيانات فقط ضمن إطار خدمات التطبيق.'),
                _buildSection('حماية البيانات',
                    'نستخدم تقنيات تشفير ومعايير أمنية متقدمة لحماية بياناتك من الوصول غير المصرح به.'),
                _buildSection('التغييرات في السياسة',
                    'قد نقوم بتحديث سياسة الخصوصية من وقت لآخر. سيتم إخطارك بأي تغييرات جوهرية عبر التطبيق.'),
                _buildSection('اتصل بنا',
                    'إذا كان لديك أي استفسار حول سياسة الخصوصية، يمكنك التواصل معنا عبر قنوات التواصل الرسمية المتاحة في التطبيق.'),
                const SizedBox(height: 50),
                const Center(
                  child: Text(
                    'آخر تحديث: يناير 2026',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.darkGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.secondaryText,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
