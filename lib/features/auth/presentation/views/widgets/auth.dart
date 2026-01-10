import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
// import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sooq_merchant/constants.dart';
import 'package:sooq_merchant/core/cubits/shared_preferences_cubit/shared_preferences_cubit.dart';
import 'package:sooq_merchant/core/utils/app_router.dart';
import 'package:sooq_merchant/core/utils/service_locator.dart';
import 'package:sooq_merchant/features/auth/presentation/manager/auth_cubit/auth_cubit.dart';
import 'package:sooq_merchant/features/auth/presentation/manager/create_user_cubit/create_user_cubit.dart';
import 'package:sooq_merchant/features/auth/presentation/manager/index_address_year_cubit/index_address_year_cubit.dart';
import 'package:sooq_merchant/features/auth/presentation/manager/verify_user_cubit/verify_user_cubit.dart';
// import 'package:sooq_merchant/features/auth/presentation/views/widgets/auth_widgets/avatar_selector.dart';
// import 'package:sooq_merchant/features/auth/presentation/views/widgets/auth_widgets/sign_button.dart';

import 'auth_widgets/address_picker.dart';
import 'auth_widgets/email_text_field.dart';

class AuthBody extends StatefulWidget {
  // final String deviceToken;
  final Function() onButtonPressed;
  // final Function(bool state) failedToLogState;
  final Function(bool state) guestState;
  // final bool failedToLog;

  const AuthBody({
    super.key,
    required this.onButtonPressed,
    // required this.deviceToken,
    // required this.failedToLogState,
    // required this.failedToLog,
    required this.guestState,
  });

  @override
  State<AuthBody> createState() => _AuthBodyState();
}

class _AuthBodyState extends State<AuthBody> {
  final _formKey = GlobalKey<FormBuilderState>();
  final SharedPreferencesCubit sharedPreferencesCubit =
      getIt<SharedPreferencesCubit>();
  int avatarIndex = 0;
  bool isSignIn = false;
  bool showCode = false;
  bool userCreated = false;
  bool userVerified = false;
  String signupCode = '';
  String verificationCode = '';

  @override
  void initState() {
    super.initState();

    if (sharedPreferencesCubit.getId() != null) {
      userCreated = true;
      userVerified = true;
      isSignIn = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink();

    // CustomScrollView(
    //   physics: const BouncingScrollPhysics(),
    //   slivers: [
    //     SliverFillRemaining(
    //       child: BlocBuilder<IndexAddressYearCubit, IndexAddressYearState>(
    //         builder: (context, state) {
    //           if (state is IndexAddressYearFailure) {
    //             return Text(state.errMessage);
    //           }
    //           if (state is IndexAddressYearLoading) {
    //             // return const CustomLoading();
    //           }
    //           if (state is! IndexAddressYearSuccess) return const SizedBox();
    //           final indexAddressYears = state;
    //           return Container(
    //             padding: const EdgeInsets.only(top: 10),
    //             decoration: const BoxDecoration(color: Colors.white),
    //             child: SingleChildScrollView(
    //               physics: const BouncingScrollPhysics(),
    //               child: Column(
    //                 children: [
    //                   _buildLogo(),
    //                   if (!userCreated && !userVerified ||
    //                       !isSignIn && !userVerified) ...[
    //                     _buildAuthHeader(),
    //                   ],
    //                   FormBuilder(
    //                     key: _formKey,
    //                     onChanged: _onFormChanged,
    //                     autovalidateMode: AutovalidateMode.onUserInteraction,
    //                     child: _buildAuthForm(indexAddressYears, _formKey),
    //                   ),
    //                 ],
    //               ),
    //             ),
    //           );
    //         },
    //       ),
    //     ),
    //   ],
    // );
  }

  // Widget _buildLogo() {
  //   return Column(
  //     children: [
  //       Text(
  //         'ScholarSphere',
  //         style: GoogleFonts.poppins(
  //           textStyle: const TextStyle(
  //             color: kAppColor,
  //             fontSize: 24,
  //             fontWeight: FontWeight.w600,
  //             //fontStyle: FontStyle.italic,
  //           ),
  //         ),
  //       ),
  //       const SizedBox(
  //         height: 20,
  //       ),
  //       Center(
  //         child: CircleAvatar(
  //           backgroundColor: Colors.transparent,
  //           radius: MediaQuery.of(context).size.width * 0.15,
  //           backgroundImage: const AssetImage('assets/images/logoIcon.png'),
  //         ),
  //       ),
  //       const SizedBox(
  //         height: 28,
  //       ),
  //     ],
  //   );

  //   //   Center(
  //   //   child: CircleAvatar(
  //   //     backgroundColor: Colors.transparent,
  //   //     radius: MediaQuery.of(context).size.width * 0.2,
  //   //     backgroundImage: const AssetImage(AssetsData.logo),
  //   //   ),
  //   // );
  // }

  // Widget _buildAuthHeader() {
  //   return Column(
  //     children: [
  //       if (userCreated) ...[
  //         Text(
  //           'Creat an account',
  //           style: GoogleFonts.poppins(
  //             textStyle: const TextStyle(
  //               color: kAppColor,
  //               fontSize: 20,
  //               fontWeight: FontWeight.w600,
  //               //fontStyle: FontStyle.italic,
  //             ),
  //           ),
  //         ),
  //         const SizedBox(
  //           height: 5,
  //         ),
  //         Text(
  //           'Enter your email to sign up for this app',
  //           style: GoogleFonts.inter(
  //             textStyle: const TextStyle(
  //               color: kAppColor,
  //               fontSize: 15,
  //               fontWeight: FontWeight.normal,
  //               //fontStyle: FontStyle.italic,
  //             ),
  //           ),
  //         ),
  //       ],
  //       const SizedBox(
  //         height: 10,
  //       ),
  //     ],
  //   );
  // }

  // Widget _buildAuthForm(IndexAddressYearSuccess indexAddressYears, formKey) {
  //   return Center(
  //     child: Column(
  //       children: [
  //         if (!userCreated && !isSignIn) ...[
  //           _buildUserCreationForm(),
  //         ],
  //         if (userCreated && !userVerified && !isSignIn) ...[
  //           _buildUserVerificationForm(formKey),
  //         ],

  //         //profile information
  //         if (userCreated && userVerified && !isSignIn) ...[
  //           _buildUserDataForm(indexAddressYears),
  //         ],
  //         if (isSignIn) ...[
  //           Row(
  //             children: [
  //               const Spacer(),
  //               Checkbox(
  //                   value: showCode,
  //                   onChanged: (value) {
  //                     setState(() {
  //                       showCode = value!;
  //                     });
  //                   }),
  //               const Text('استخدام رمز استرداد الحساب'),
  //               const Spacer(),
  //             ],
  //           )
  //         ],
  //         if (isSignIn && showCode) ...[
  //           // OtpField(changeCode: _onVerificationCodeChanged),
  //         ],
  //         if (userVerified || isSignIn) ...[
  //           // SignButton(
  //           //   imageId: avatarIndex.toString(),
  //           //   showCode: showCode,
  //           //   // failedToLog: widget.failedToLog,
  //           //   formKey: _formKey,
  //           //   onButtonPressed: widget.onButtonPressed,
  //           //   deviceToken: widget.deviceToken,
  //           //   isSignIn: isSignIn,
  //           //   // failedToLogState: widget.failedToLogState,
  //           //   verificationCode: verificationCode,
  //           // ),
  //         ],
  //         _buildGuestButton(),
  //         if (!userVerified) ...[
  //           _buildSignInToggle(),
  //         ]
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildUserCreationForm() {
  //   return BlocConsumer<CreateUserCubit, CreateUserState>(
  //     listener: _onUserCreated,
  //     builder: (context, state) {
  //       if (state is CreateUserLoading) {
  //         // return const CustomLoading();
  //       }

  //       return Column(
  //         children: [
  //           // const EmailTextField(),
  //           Container(
  //             width: MediaQuery.of(context).size.width * 0.85,
  //             height: 45,
  //             decoration: BoxDecoration(
  //                 color: const Color(0xFF154957),
  //                 borderRadius: BorderRadius.circular(10)),
  //             child: MaterialButton(
  //               onPressed: _createUser,
  //               child: Text(
  //                 'Continue',
  //                 style: GoogleFonts.poppins(
  //                   textStyle: const TextStyle(
  //                     color: Colors.white,
  //                     fontSize: 18,
  //                     fontWeight: FontWeight.w500,
  //                     //fontStyle: FontStyle.italic,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //           const SizedBox(
  //             height: 10,
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // // Widget _buildUserVerificationForm(formkey) {
  // //   return BlocConsumer<VerifyUserCubit, VerifyUserState>(
  // //     listener: _onUserVerified,
  // //     builder: (context, state) {
  // //       if (state is VerifyUserLoading) {
  // //         // return const CustomLoading();
  // //       }

  // //       return Column(
  // //         children: [
  // //           Directionality(
  // //             textDirection: TextDirection.ltr,
  // //             child: Padding(
  // //               padding: const EdgeInsets.only(top: 15),
  // //               child: OtpTextField(
  // //                 inputFormatters: [
  // //                   FilteringTextInputFormatter.deny(RegExp(r'\s')),
  // //                 ],
  // //                 numberOfFields: 7,
  // //                 borderWidth: 2,
  // //                 keyboardType: TextInputType.text,
  // //                 borderColor: const Color.fromARGB(255, 0, 0, 0),
  // //                 showFieldAsBox: true,
  // //                 autoFocus: true,
  // //                 onSubmit: _onVerificationCodeSubmitted,
  // //               ),
  // //             ),
  // //           ),
  // //           ResendEmailItem(
  // //             formKey: formkey,
  // //           ),
  // //           ElevatedButton(
  // //             onPressed: _verifyUser,
  // //             child: const Text('تأكيد'),
  // //           ),
  // //         ],
  // //       );
  // //     },
  // //   );
  // // }

  // Widget _buildUserDataForm(IndexAddressYearSuccess indexAddressYears) {
  //   return Column(
  //     children: [
  //       if (!isSignIn) ...[
  //         AvatarSelector(
  //           setAvatar: _setAvatar,
  //         ),
  //         const NameTextField(),
  //         const FormDatePicker(),
  //         const GenderPicker(),
  //         AddressPicker(
  //             addresses: indexAddressYears.indexAddressYears.addresses!),
  //         MyYearPicker(years: indexAddressYears.indexAddressYears.years!),
  //       ],
  //       const SizedBox(height: 15),
  //     ],
  //   );
  // }

  // Widget _buildGuestButton() {
  //   return BlocConsumer<AuthCubit, AuthState>(listener: (context, state) {
  //     if (state is AuthSuccess) {
  //       context.pushReplacement(AppRouter.kHomeView);
  //     }
  //   }, builder: (context, state) {
  //     String text = '';
  //     TextStyle style =
  //         GoogleFonts.inter(fontSize: 13, color: const Color(0xFF828282));
  //     if (isSignIn) {
  //       text = 'By continuing, you agree to our ';
  //       style = GoogleFonts.inter(fontSize: 14, color: kAppColor);
  //     }

  //     return Column(
  //       children: [
  //         const SizedBox(
  //           height: 20,
  //         ),
  //         Text.rich(
  //           TextSpan(
  //             text: text,
  //             style: style,
  //             children: <TextSpan>[
  //               if (isSignIn) ...[
  //                 const TextSpan(text: 'Terms of Service'),
  //                 TextSpan(
  //                   text: ' and ',
  //                   style: GoogleFonts.inter(
  //                       fontSize: 13, color: const Color(0xFF828282)),
  //                   children: <TextSpan>[
  //                     TextSpan(
  //                         text: 'Privacy Policy',
  //                         style: GoogleFonts.inter(
  //                             fontSize: 14, color: kAppColor)),
  //                   ],
  //                 ),
  //               ],
  //             ],
  //           ),
  //           textAlign: TextAlign.center,
  //         ),
  //         Padding(
  //           padding: const EdgeInsets.symmetric(horizontal: 120),
  //           child: ElevatedButton(
  //             onPressed: () {
  //               widget.guestState(true);
  //               widget.onButtonPressed();
  //             },
  //             child: const Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Text('تصفح التطبيق'),
  //                 SizedBox(width: 5),
  //                 Icon(Icons.arrow_forward_ios_rounded),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ],
  //     );
  //   });
  // }

  // Widget _buildSignInToggle() {
  //   return Padding(
  //     padding: const EdgeInsets.only(top: 20),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Text(
  //           !isSignIn
  //               ? 'already have an account? '
  //               : 'don\'t have an account? ',

  //           //  'لديك حساب بالفعل؟',
  //           style: GoogleFonts.inter(
  //             textStyle: const TextStyle(
  //               color: Color(0xFF828282),
  //               fontSize: 15,
  //               fontWeight: FontWeight.w400,
  //               //fontStyle: FontStyle.italic,
  //             ),
  //           ),
  //         ),
  //         GestureDetector(
  //           onTap: _toggleSignIn,
  //           child: Text(
  //             !isSignIn ? 'Sign in' : 'Creat an account',
  //             style: GoogleFonts.inter(
  //               textStyle: const TextStyle(
  //                 color: kAppColor,
  //                 fontSize: 15,
  //                 fontWeight: FontWeight.w400,
  //                 //fontStyle: FontStyle.italic,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // void _onFormChanged() {
  //   _formKey.currentState!.save();
  //   debugPrint(_formKey.currentState!.value.toString());
  // }

  // void _onUserCreated(BuildContext context, CreateUserState state) {
  //   if (state is CreateUserFailure) {
  //     customToast(state.errMessage);
  //   }
  //   if (state is CreateUserSuccess) {
  //     setState(() {
  //       userCreated = true;
  //     });
  //   }
  // }

  // void _createUser() {
  //   if (_formKey.currentState!.validate()) {
  //     _formKey.currentState!.save();
  //     BlocProvider.of<CreateUserCubit>(context).createUser(
  //       _formKey.currentState!.value['email'],
  //     );
  //   }
  // }

  // void _onUserVerified(BuildContext context, VerifyUserState state) {
  //   if (state is VerifyUserFailure) {
  //     customToast(state.errMessage);
  //   }
  //   if (state is VerifyUserSuccess) {
  //     setState(() {
  //       userVerified = true;
  //     });
  //   }
  // }

  // void _verifyUser() {
  //   if (signupCode.trim().length < 7) {
  //     customToast('يجب ان يكون الرمز 7 محارف على الاقل');
  //     return;
  //   }
  //   BlocProvider.of<VerifyUserCubit>(context).verfiyUser(
  //     _formKey.currentState!.value['email'],
  //     signupCode,
  //   );
  // }

  // void _setAvatar(int selectedAvatarIndex) {
  //   setState(() {
  //     avatarIndex = selectedAvatarIndex;
  //   });
  // }

  // void _onVerificationCodeSubmitted(String verificationCode) {
  //   signupCode = verificationCode;
  // }

  // // void _setShowCode(bool state) {
  // //   setState(() {
  // //     showCode = state;
  // //   });
  // // }

  // void _onVerificationCodeChanged(String code) {
  //   setState(() {
  //     verificationCode = code;
  //   });
  // }

  // void _toggleSignIn() {
  //   setState(() {
  //     isSignIn = !isSignIn;
  //     _formKey.currentState!.reset();
  //   });
  // }
}
