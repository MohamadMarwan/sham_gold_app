import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
                'اتفاقية الاستخدام',
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
                    child: Icon(Icons.description_rounded,
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
                _buildSection('قبول الشروط',
                    'باستخدامك لتطبيق "غولد شام"، فإنك تقر وتوافق على الالتزام بشروط وأحكام هذه الاتفاقية. إذا كنت لا توافق على هذه الشروط، يرجى عدم استخدام التطبيق.'),
                _buildSection('طبيعة الخدمة',
                    'التطبيق يقدم أسعار الذهب والعملات للأغراض المعلوماتية فقط. نحن نسعى لتقديم أدق البيانات، ولكن لا نتحمل مسؤولية أي قرارات مالية تُتخذ بناءً على هذه الأسعار.'),
                _buildSection('مسؤولية المستخدم',
                    'يتحمل المستخدم المسؤولية الكاملة عن استخدامه للتطبيق والبيانات الواردة فيه. يجب التأكد من الأسعار من المصادر الرسمية قبل إجراء أي عمليات بيع أو شراء حقيقية.'),
                _buildSection('حقوق الملكية',
                    'جميع المحتويات والشعارات والبرمجيات الخاصة بالتطبيق هي ملك "غولد شام" ومحمية بموجب قوانين الملكية الفكرية.'),
                _buildSection('توافر الخدمة',
                    'نحن نسعى لضمان توفر التطبيق على مدار الساعة، ولكن لا نضمن عدم حدوث انقطاعات تقنية خارجة عن إرادتنا.'),
                _buildSection('التعديلات',
                    'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. استمرارك في استخدام التطبيق بعد هذه التعديلات يُعتبر قبولاً للشروط الجديدة.'),
                _buildSection('إخلاء المسؤولية',
                    'يتم توفير الخدمة "كما هي" دون أي ضمانات صريحة أو ضمنية. نحن لا نتحمل مسؤولية أي خسائر ناتجة عن استخدام أو عدم القدرة على استخدام التطبيق.'),
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
