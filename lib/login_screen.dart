import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'app_settings.dart';
import 'event_dm.dart';
import 'firebase_options.dart';

Future<void>? googleInitialization;

Future<void> initializeGoogleSignIn() {
  return googleInitialization ??= GoogleSignIn.instance.initialize(
    serverClientId: eventlyGoogleClientId,
  );
}

Future<void> signOut() async {
  var auth = FirebaseAuth.instance;
  try {
    if (auth.currentUser?.providerData.any(
          (provider) => provider.providerId == 'google.com',
        ) ==
        true) {
      await initializeGoogleSignIn();
      await GoogleSignIn.instance.signOut();
    }
  } finally {
    await auth.signOut();
  }
}

enum LoginMode { login, signup, reset }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  var nameController = TextEditingController();
  var emailController = TextEditingController();
  var passwordController = TextEditingController();
  var formKey = GlobalKey<FormState>();
  LoginMode mode = LoginMode.login;
  bool signingIn = false;
  bool hidePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void changeMode(LoginMode nextMode) {
    setState(() {
      mode = nextMode;
      passwordController.clear();
      hidePassword = true;
    });
  }

  Future<void> submit({bool google = false}) async {
    if (signingIn || (!google && !formKey.currentState!.validate())) return;
    var messages = ScaffoldMessenger.of(context);
    var auth = FirebaseAuth.instance;
    var email = emailController.text.trim();
    var password = passwordController.text;
    var name = nameController.text.trim();
    var signingUp = !google && mode == LoginMode.signup;
    var failure = label(
      context,
      'Could not complete sign-in. Check your details and try again.',
      'تعذر تسجيل الدخول. تحقق من البيانات وحاول مرة أخرى.',
    );
    setState(() => signingIn = true);
    User? signedInUser;
    try {
      if (!google && mode == LoginMode.reset) {
        await auth.sendPasswordResetEmail(email: email);
        if (!mounted) return;
        messages.showSnackBar(
          SnackBar(
            content: Text(
              label(
                context,
                'Password reset email sent',
                'تم إرسال رسالة إعادة تعيين كلمة المرور',
              ),
            ),
          ),
        );
        changeMode(LoginMode.login);
        return;
      }

      UserCredential result;
      if (google) {
        await initializeGoogleSignIn();
        var account = await GoogleSignIn.instance.authenticate();
        var credential = GoogleAuthProvider.credential(
          idToken: account.authentication.idToken,
        );
        result = await auth.signInWithCredential(credential);
      } else if (signingUp) {
        result = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        result = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }

      signedInUser = result.user!;
      if (signingUp) {
        await signedInUser.updateDisplayName(name);
        signedInUser = auth.currentUser!;
      }
      await saveUser(signedInUser);
    } on GoogleSignInException catch (error) {
      if (error.code != GoogleSignInExceptionCode.canceled &&
          messages.mounted) {
        messages.showSnackBar(SnackBar(content: Text(failure)));
      }
    } on FirebaseException {
      if (signedInUser != null) await auth.signOut();
      if (messages.mounted) {
        messages.showSnackBar(SnackBar(content: Text(failure)));
      }
    } finally {
      if (mounted) setState(() => signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var blue = Theme.of(context).colorScheme.primary;
    var title = switch (mode) {
      LoginMode.login => label(
        context,
        'Login to your account',
        'سجل الدخول إلى حسابك',
      ),
      LoginMode.signup => label(context, 'Create an account', 'أنشئ حسابًا'),
      LoginMode.reset => label(
        context,
        'Reset password',
        'إعادة تعيين كلمة المرور',
      ),
    };
    var button = switch (mode) {
      LoginMode.login => label(context, 'Login', 'تسجيل الدخول'),
      LoginMode.signup => label(context, 'Sign up', 'إنشاء حساب'),
      LoginMode.reset => label(
        context,
        'Send reset email',
        'إرسال رسالة إعادة التعيين',
      ),
    };
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 40),
              Center(
                child: Image.asset(
                  'assets/images/evently_logo.png',
                  width: 152,
                  color: blue,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: blue, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (mode == LoginMode.signup) ...[
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: label(context, 'Name', 'الاسم'),
                  ),
                  validator: (value) => value!.trim().isEmpty
                      ? label(context, 'Enter your name', 'أدخل اسمك')
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: label(context, 'Email', 'البريد الإلكتروني'),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                validator: (value) => !value!.contains('@')
                    ? label(
                        context,
                        'Enter your email address',
                        'أدخل بريدك الإلكتروني',
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              if (mode != LoginMode.reset)
                TextFormField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: label(context, 'Password', 'كلمة المرور'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: hidePassword
                          ? label(context, 'Show password', 'إظهار كلمة المرور')
                          : label(
                              context,
                              'Hide password',
                              'إخفاء كلمة المرور',
                            ),
                      onPressed: () =>
                          setState(() => hidePassword = !hidePassword),
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => value!.isEmpty
                      ? label(
                          context,
                          'Enter your password',
                          'أدخل كلمة المرور',
                        )
                      : null,
                ),
              if (mode == LoginMode.login)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: signingIn
                        ? null
                        : () => changeMode(LoginMode.reset),
                    child: Text(
                      label(context, 'Forgot password?', 'نسيت كلمة المرور؟'),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: signingIn ? null : submit,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                child: Text(button),
              ),
              if (mode == LoginMode.login) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label(
                        context,
                        "Don't have an account?",
                        'ليس لديك حساب؟',
                      ),
                    ),
                    TextButton(
                      onPressed: signingIn
                          ? null
                          : () => changeMode(LoginMode.signup),
                      child: Text(label(context, 'Sign up', 'إنشاء حساب')),
                    ),
                  ],
                ),
                Center(child: Text(label(context, 'Or', 'أو'))),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: signingIn ? null : () => submit(google: true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: blue,
                    minimumSize: const Size(0, 44),
                  ),
                  icon: Image.asset('assets/images/google_icon.png', width: 20),
                  label: Text(
                    label(
                      context,
                      'Login with Google',
                      'تسجيل الدخول باستخدام Google',
                    ),
                  ),
                ),
              ] else
                TextButton(
                  onPressed: signingIn
                      ? null
                      : () => changeMode(LoginMode.login),
                  child: Text(
                    label(context, 'Back to login', 'العودة إلى تسجيل الدخول'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
