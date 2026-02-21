import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_opensig/core/storage/misc_box.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageData> _onboardingPages = [
    OnboardingPageData(
      icon: Icons.security_rounded,
      title: 'Secure Your Assets',
      description:
          'Safe OpenSig is your second factor verification app for Safe transactions. '
          'Keep your digital assets secure with easy-to-use verification/simulation.',
    ),
    OnboardingPageData(
      icon: Icons.account_balance_wallet_rounded,
      title: 'Manage Multiple Accounts',
      description:
          'Easily switch between multiple Safe accounts from a single interface. '
    ),
    OnboardingPageData(
      icon: Icons.rocket_launch_rounded,
      title: 'Get Started',
      description:
          'Connect your Safe account and start using Safe OpenSig to add an extra layer of security '
          'to your transactions with a simple second-factor verification.',
    ),
    OnboardingPageData(
      icon: Icons.lock_outline_rounded,
      title: 'Your Privacy',
      description:
          'Your Safe accounts are saved locally on this device. '
          'No data is ever collected or shared.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _onboardingPages.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_onboardingPages[index]);
                },
              ),
            ),
            _buildPageIndicator(),
            const SizedBox(height: 20),
            _buildNavigationButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPageData pageData) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            pageData.icon,
            size: 100,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 40),
          Text(
            pageData.title,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            pageData.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _onboardingPages.length,
        (index) => AnimatedContainer(
          duration: Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 12 : 8,
          height: _currentPage == index ? 12 : 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Theme.of(context).primaryColor
                : Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage < _onboardingPages.length - 1)
            TextButton(
              onPressed: _completeOnboarding,
              child: const Text('Skip'),
            )
          else
            const SizedBox.shrink(),
          Row(
            children: [
              if (_currentPage != 0)
                IconButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
              IconButton(
                onPressed: () {
                  if (_currentPage == _onboardingPages.length - 1) {
                    _completeOnboarding();
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                icon: Icon(
                  _currentPage == _onboardingPages.length - 1
                      ? Icons.check
                      : Icons.arrow_forward,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _completeOnboarding() async {
    await MiscBox.markOnboardingAsCompleted();
    if (mounted) {
      GoRouter.of(context).go('/accounts');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPageData {
  final IconData icon;
  final String title;
  final String description;

  OnboardingPageData({
    required this.icon,
    required this.title,
    required this.description,
  });
}