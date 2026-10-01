import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      const Scaffold(body: Center(child: AnniversaryMark(size: 230)));
}

class AnniversaryMark extends StatelessWidget {
  const AnniversaryMark({super.key, this.size = 170});
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    'assets/images/sdu_30_logo.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
    filterQuality: FilterQuality.high,
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
              const Center(child: AnniversaryMark(size: 205)),
              const SizedBox(height: 20),
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
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Find rooms, services, and the best way to get there.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 15),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: busy ? null : () => context.push('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text(
                    'Log in',
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
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : () => context.push('/register'),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text(
                    'Create account',
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
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          await ref
                              .read(appProvider.notifier)
                              .continueAsGuest();
                          if (context.mounted) context.go('/home');
                        },
                  icon: const Icon(Icons.person_outline, size: 19),
                  label: const Text('Continue as Guest'),
                ),
              ),
              const Center(
                child: Text(
                  'Guest mode includes maps, search, and campus services.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
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
  final _id = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _submitted = false;
  String? _serverError;

  bool get _validId => RegExp(r'^\d{9}$').hasMatch(_id.text.trim());
  String? get _idError {
    if (!_submitted && _id.text.isEmpty) return null;
    return _validId ? null : 'Enter your 9-digit SDU ID';
  }

  @override
  void initState() {
    super.initState();
    _id.addListener(_refresh);
  }

  void _refresh() => setState(() => _serverError = null);

  @override
  void dispose() {
    _id.removeListener(_refresh);
    _id.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    if (!_validId) return;
    if (_password.text.isEmpty) {
      setState(() => _serverError = 'Enter your password');
      return;
    }
    final error = await ref
        .read(appProvider.notifier)
        .login(_id.text, _password.text);
    if (!mounted) return;
    setState(() => _serverError = error);
    if (error == null) context.go('/home');
  }

  void _demoAccess() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demo access',
              style: TextStyle(
                fontSize: 23,
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'All demo accounts use password Campus123!',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            _DemoAccountTile(
              role: 'Student',
              id: '240103049',
              onTap: _fillDemo,
            ),
            _DemoAccountTile(
              role: 'Teacher',
              id: '240000001',
              onTap: _fillDemo,
            ),
            _DemoAccountTile(
              role: 'Administrator',
              id: '240000002',
              onTap: _fillDemo,
            ),
          ],
        ),
      ),
    );
  }

  void _fillDemo(String id) {
    Navigator.pop(context);
    _id.text = id;
    _password.text = 'Campus123!';
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(appProvider.select((s) => s.busy));
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
        children: [
          const Center(child: AnniversaryMark(size: 118)),
          const SizedBox(height: 12),
          const Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 30,
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Log in with your SDU ID. Your role is assigned automatically.',
            style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _id,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            decoration: InputDecoration(
              labelText: 'SDU ID',
              hintText: '240103049',
              prefixIcon: const Icon(Icons.badge_outlined),
              suffixIcon: _validId
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              errorText: _idError,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              errorText: _serverError,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Contact a campus administrator to reset your password.',
                  ),
                ),
              ),
              child: const Text('Forgot password?'),
            ),
          ),
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
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Signing in…'),
                      ],
                    )
                  : const Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('New to the app?'),
              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text('Create account'),
              ),
            ],
          ),
          Center(
            child: TextButton.icon(
              onPressed: _demoAccess,
              icon: const Icon(Icons.science_outlined, size: 17),
              label: const Text('Demo access'),
              style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _id = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _submitted = false;
  String? _error;

  bool get _validId => RegExp(r'^\d{9}$').hasMatch(_id.text.trim());

  @override
  void initState() {
    super.initState();
    _id.addListener(_refresh);
  }

  void _refresh() => setState(() => _error = null);

  @override
  void dispose() {
    _id.removeListener(_refresh);
    _id.dispose();
    _name.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_validId) return;
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Enter your full name');
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }
    if (_password.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    final error = await ref
        .read(appProvider.notifier)
        .register(_id.text, _name.text, _password.text);
    if (!mounted) return;
    setState(() => _error = error);
    if (error == null) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(appProvider.select((s) => s.busy));
    final idError = (!_submitted && _id.text.isEmpty) || _validId
        ? null
        : 'Enter your 9-digit SDU ID';
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
        children: [
          const Center(child: AnniversaryMark(size: 104)),
          const SizedBox(height: 8),
          const Text(
            'Create your account',
            style: TextStyle(
              fontSize: 28,
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'New accounts are assigned the Student role automatically.',
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: _id,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(9),
            ],
            decoration: InputDecoration(
              labelText: 'SDU ID',
              hintText: '240103049',
              prefixIcon: const Icon(Icons.badge_outlined),
              suffixIcon: _validId
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              errorText: idError,
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            controller: _password,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Password',
              helperText: 'Use at least 8 characters',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          TextField(
            controller: _confirm,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Confirm password',
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              errorText: _error,
            ),
          ),
          const SizedBox(height: 20),
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
                  ? const Text('Creating account…')
                  : const Text(
                      'Create account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Already registered?'),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Log in'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DemoAccountTile extends StatelessWidget {
  const _DemoAccountTile({
    required this.role,
    required this.id,
    required this.onTap,
  });
  final String role;
  final String id;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const CircleAvatar(
      backgroundColor: Color(0xFFE4EEFF),
      child: Icon(Icons.badge_outlined, color: AppColors.blue),
    ),
    title: Text(role, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(id),
    trailing: const Icon(Icons.arrow_forward),
    onTap: () => onTap(id),
  );
}
