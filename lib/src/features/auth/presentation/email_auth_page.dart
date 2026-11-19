import '../../../core/localization/app_strings.dart';
import 'widgets/auth_language_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_form_bloc.dart';
import 'package:flutter/material.dart';

import '../../../core/consts/app_colors.dart';
import '../../../core/widgets/glass_panel.dart';

class EmailAuthPage extends StatelessWidget {
  const EmailAuthPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AuthFormBloc(),
    child: const _EmailAuthView(),
  );
}

class _EmailAuthView extends StatefulWidget {
  const _EmailAuthView();
  @override
  State<_EmailAuthView> createState() => _EmailAuthPageState();
}

class _EmailAuthPageState extends State<_EmailAuthView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  int _resetRevision = 0;
  @override
  void initState() {
    super.initState();
    _resetRevision = context.read<AuthBloc>().state.resetRevision;
  }

  bool get _register => context.read<AuthFormBloc>().state.register;
  bool get _busy => context.read<AuthBloc>().state.busy;
  bool get _hidePassword => context.read<AuthFormBloc>().state.hidePassword;
  String? get _error => context.read<AuthBloc>().state.errorKey;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((value ?? '').trim())) {
      return AppStrings.of(context)('To‘g‘ri email manzilini kiriting.');
    }
    return null;
  }

  void _submit() {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(
      AuthEmailRequested(_email.text, _password.text, register: _register),
    );
  }

  void _resetPassword() {
    if (_busy || _validateEmail(_email.text) != null) {
      _formKey.currentState?.validate();
      return;
    }
    FocusScope.of(context).unfocus();
    context.read<AuthBloc>().add(AuthResetRequested(_email.text));
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: AppColors.primary),
    filled: true,
    fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFDCE5DE)),
    ),
  );

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AuthFormBloc, AuthFormState>(
    builder: (context, form) => BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.user != null) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
        if (state.resetRevision != _resetRevision) {
          _resetRevision = state.resetRevision;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.of(context)('authResetSent'))),
          );
        }
      },
      builder: (context, state) => PopScope(
        canPop: !_busy,
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            actions: const [AuthLanguagePicker()],
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: Text(
              _register
                  ? AppStrings.of(context)('Ro‘yxatdan o‘tish')
                  : AppStrings.of(context)('Email orqali kirish'),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 420),
                  child: GlassPanel(
                    radius: 28,
                    padding: EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.explore_outlined,
                              size: 48,
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 20),
                            Text(
                              _register
                                  ? AppStrings.of(context)('Xush kelibsiz!')
                                  : AppStrings.of(context)(
                                      'Qaytganingizdan xursandmiz.',
                                    ),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              _register
                                  ? AppStrings.of(context)(
                                      'Xaritadan foydalanish uchun akkaunt yarating.',
                                    )
                                  : AppStrings.of(context)(
                                      'Email va parolingiz bilan davom eting.',
                                    ),
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                            SizedBox(height: 26),
                            TextFormField(
                              controller: _email,
                              enabled: !_busy,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email],
                              autocorrect: false,
                              decoration: _decoration(
                                'Email',
                                Icons.mail_outline_rounded,
                              ),
                              validator: _validateEmail,
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _password,
                              enabled: !_busy,
                              obscureText: _hidePassword,
                              autocorrect: false,
                              enableSuggestions: false,
                              autofillHints: [
                                _register
                                    ? AutofillHints.newPassword
                                    : AutofillHints.password,
                              ],
                              textInputAction: _register
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (!_register) _submit();
                              },
                              decoration:
                                  _decoration(
                                    AppStrings.of(context)('Parol'),
                                    Icons.lock_outline_rounded,
                                  ).copyWith(
                                    suffixIcon: IconButton(
                                      onPressed: _busy
                                          ? null
                                          : () => context.read<AuthFormBloc>().add(
                                              const AuthPasswordVisibilityToggled(),
                                            ),
                                      tooltip: _hidePassword
                                          ? AppStrings.of(context)(
                                              'Parolni ko‘rsatish',
                                            )
                                          : AppStrings.of(context)(
                                              'Parolni yashirish',
                                            ),
                                      icon: Icon(
                                        _hidePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppStrings.of(context)(
                                    'Parolni kiriting.',
                                  );
                                }
                                if (_register && value.length < 6) {
                                  return AppStrings.of(context)(
                                    'Parol kamida 6 belgidan iborat bo‘lsin.',
                                  );
                                }
                                return null;
                              },
                            ),
                            if (_register) ...[
                              SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmation,
                                enabled: !_busy,
                                obscureText: _hidePassword,
                                autocorrect: false,
                                enableSuggestions: false,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: _decoration(
                                  AppStrings.of(context)('Parolni takrorlang'),
                                  Icons.lock_outline_rounded,
                                ),
                                validator: (value) => value != _password.text
                                    ? AppStrings.of(context)(
                                        'Parollar bir xil emas.',
                                      )
                                    : null,
                              ),
                            ],
                            if (!_register)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _busy ? null : _resetPassword,
                                  child: Text(
                                    AppStrings.of(context)(
                                      'Parolni unutdingizmi?',
                                    ),
                                  ),
                                ),
                              ),
                            if (_error != null)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  AppStrings.of(context)(_error!),
                                  style: TextStyle(
                                    color: AppColors.error,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            SizedBox(height: 18),
                            FilledButton(
                              onPressed: _busy ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                minimumSize: Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _busy
                                  ? SizedBox.square(
                                      dimension: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _register
                                          ? AppStrings.of(context)(
                                              'Akkaunt yaratish',
                                            )
                                          : AppStrings.of(context)('Kirish'),
                                    ),
                            ),
                            SizedBox(height: 12),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () {
                                      context.read<AuthFormBloc>().add(
                                        const AuthFormModeToggled(),
                                      );
                                      context.read<AuthBloc>().add(
                                        const AuthErrorCleared(),
                                      );
                                      _password.clear();
                                      _confirmation.clear();
                                      _formKey.currentState?.reset();
                                    },
                              child: Text(
                                _register
                                    ? AppStrings.of(context)(
                                        'Akkauntingiz bormi? Kirish',
                                      )
                                    : AppStrings.of(context)(
                                        'Akkauntingiz yo‘qmi? Ro‘yxatdan o‘tish',
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
          ),
        ),
      ),
    ),
  );
}
