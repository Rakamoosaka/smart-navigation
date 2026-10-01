import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_state.dart';
import '../theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final restored = await ref.read(appProvider.notifier).restoreSession();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) context.go(restored ? '/home' : '/welcome');
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: AnniversaryMark(size: 210)));
}

class AnniversaryMark extends StatelessWidget {
  const AnniversaryMark({super.key, this.size = 170});
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'SDU',
          style: TextStyle(
            fontSize: size * .30,
            letterSpacing: size * .04,
            color: AppColors.gold,
            fontWeight: FontWeight.w300,
            height: .9,
          ),
        ),
        Text(
          '1996  •  ANNIVERSARY',
          style: TextStyle(
            fontSize: size * .065,
            letterSpacing: 2,
            color: AppColors.gold,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '30',
          style: TextStyle(
            fontSize: size * .38,
            color: AppColors.gold,
            fontWeight: FontWeight.w200,
            height: 1,
          ),
        ),
      ],
    ),
  );
}

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(appProvider.select((s) => s.busy));
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SDU CAMPUS',
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              const Center(child: AnniversaryMark(size: 190)),
              const SizedBox(height: 34),
              const Center(
                child: Text(
                  'Your campus, at your\nfingertips.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 30,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Find rooms, services, and the best way to get there.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton.icon(
                  onPressed: busy ? null : () => context.push('/login'),
                  icon: const Icon(Icons.school_outlined),
                  label: const Text(
                    'Continue with SDU Email',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          await ref
                              .read(appProvider.notifier)
                              .continueAsGuest();
                          if (context.mounted) context.go('/home');
                        },
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_outline),
                  label: const Text(
                    'Continue as Guest',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: Color(0xFFCBD4E8)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
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
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController(text: '240103049@sdu.edu.kz');
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final error = await ref.read(appProvider.notifier).login(_email.text);
    if (!mounted) return;
    setState(() => _error = error);
    if (error == null) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(appProvider.select((s) => s.busy));
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
        children: [
          const AnniversaryMark(size: 125),
          const SizedBox(height: 28),
          const Text(
            'Welcome to SDU',
            style: TextStyle(
              fontSize: 30,
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your university email. Your role is assigned automatically.',
            style: TextStyle(color: AppColors.muted, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'SDU email',
              prefixIcon: const Icon(Icons.alternate_email),
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: busy ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              child: busy
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          const _DemoAccounts(),
        ],
      ),
    );
  }
}

class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Demo accounts',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: 10),
          Text('Student  ·  240103049@sdu.edu.kz'),
          Text('Teacher  ·  240000001@sdu.edu.kz'),
          Text('Admin     ·  240000002@sdu.edu.kz'),
        ],
      ),
    ),
  );
}
