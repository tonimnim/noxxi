import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../utils/validators.dart';

// Custom Text Field
class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  const AppTextField({
    Key? key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textInputAction,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      readOnly: readOnly,
      enabled: enabled,
      onTap: onTap,
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      focusNode: focusNode,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

// Email Input Field
class EmailInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? label;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final TextInputAction? textInputAction;

  const EmailInput({
    Key? key,
    this.controller,
    this.validator,
    this.label,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label ?? 'Email',
      hint: 'Enter your email',
      keyboardType: TextInputType.emailAddress,
      validator: validator ?? Validators.emailValidator,
      prefixIcon: const Icon(Icons.email_outlined),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction ?? TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.deny(RegExp(r'\s')), // No spaces
      ],
    );
  }
}

// Password Input Field
class PasswordInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? label;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final TextInputAction? textInputAction;

  const PasswordInput({
    Key? key,
    this.controller,
    this.validator,
    this.label,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
  }) : super(key: key);

  @override
  State<PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label ?? 'Password',
      hint: 'Enter your password',
      obscureText: _obscureText,
      validator: widget.validator ?? Validators.passwordValidator,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
        onPressed: () {
          setState(() {
            _obscureText = !_obscureText;
          });
        },
      ),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      textInputAction: widget.textInputAction ?? TextInputAction.done,
    );
  }
}

// Phone Number Input
class PhoneInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? label;
  final void Function(String)? onChanged;
  final String countryCode;

  const PhoneInput({
    Key? key,
    this.controller,
    this.validator,
    this.label,
    this.onChanged,
    this.countryCode = '+254', // Kenya default
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label ?? 'Phone Number',
      hint: '712345678',
      keyboardType: TextInputType.phone,
      validator: validator ?? Validators.phoneValidator,
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.phone_outlined),
            const SizedBox(width: 8),
            Text(
              countryCode,
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(9), // Kenyan phone without country code
      ],
    );
  }
}

// Search Input Field
class SearchInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;

  const SearchInput({
    Key? key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: hint ?? 'Search...',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: controller?.text.isNotEmpty == true
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller?.clear();
                onClear?.call();
              },
            )
          : null,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
    );
  }
}

// Amount/Price Input Field
class AmountInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? label;
  final String currency;
  final void Function(String)? onChanged;

  const AmountInput({
    Key? key,
    this.controller,
    this.validator,
    this.label,
    this.currency = 'KSh',
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label ?? 'Amount',
      hint: '0.00',
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: validator ?? Validators.priceValidator,
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          currency,
          style: AppTextStyles.bodyLarge,
        ),
      ),
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
    );
  }
}

// Date Picker Input
class DateInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final void Function(DateTime)? onDateSelected;

  const DateInput({
    Key? key,
    this.controller,
    this.label,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label ?? 'Date',
      hint: 'Select date',
      readOnly: true,
      prefixIcon: const Icon(Icons.calendar_today_outlined),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: initialDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2020),
          lastDate: lastDate ?? DateTime(2030),
        );
        
        if (date != null) {
          controller?.text = '${date.day}/${date.month}/${date.year}';
          onDateSelected?.call(date);
        }
      },
    );
  }
}

// Time Picker Input
class TimeInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final TimeOfDay? initialTime;
  final void Function(TimeOfDay)? onTimeSelected;

  const TimeInput({
    Key? key,
    this.controller,
    this.label,
    this.initialTime,
    this.onTimeSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label ?? 'Time',
      hint: 'Select time',
      readOnly: true,
      prefixIcon: const Icon(Icons.access_time),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: initialTime ?? TimeOfDay.now(),
        );
        
        if (time != null) {
          controller?.text = time.format(context);
          onTimeSelected?.call(time);
        }
      },
    );
  }
}

// OTP Input Field
class OtpInput extends StatelessWidget {
  final int length;
  final void Function(String)? onCompleted;
  final void Function(String)? onChanged;
  final MainAxisAlignment mainAxisAlignment;

  const OtpInput({
    Key? key,
    this.length = 6,
    this.onCompleted,
    this.onChanged,
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<TextEditingController> controllers = List.generate(
      length,
      (_) => TextEditingController(),
    );
    
    final List<FocusNode> focusNodes = List.generate(
      length,
      (_) => FocusNode(),
    );

    String getOtp() {
      return controllers.map((c) => c.text).join();
    }

    return Row(
      mainAxisAlignment: mainAxisAlignment,
      children: List.generate(length, (index) {
        return SizedBox(
          width: 45,
          height: 55,
          child: TextFormField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: AppTextStyles.headlineMedium,
            decoration: InputDecoration(
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              if (value.isNotEmpty && index < length - 1) {
                focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                focusNodes[index - 1].requestFocus();
              }
              
              final otp = getOtp();
              onChanged?.call(otp);
              
              if (otp.length == length) {
                onCompleted?.call(otp);
              }
            },
          ),
        );
      }),
    );
  }
}