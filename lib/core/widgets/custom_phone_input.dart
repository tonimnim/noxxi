import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:noxxi/core/theme/app_colors.dart';

class CustomPhoneInput extends StatelessWidget {
  final Function(PhoneNumber) onInputChanged;
  final String? Function(String?)? validator;
  final PhoneNumber initialValue;
  
  const CustomPhoneInput({
    super.key,
    required this.onInputChanged,
    this.validator,
    required this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return InternationalPhoneNumberInput(
        onInputChanged: onInputChanged,
        selectorConfig: const SelectorConfig(
          selectorType: PhoneInputSelectorType.DIALOG,
          setSelectorButtonAsPrefixIcon: true,
          leadingPadding: 12,
          useEmoji: true,
        ),
        ignoreBlank: false,
        autoValidateMode: AutovalidateMode.disabled,
        selectorTextStyle: const TextStyle(
          color: AppColors.primaryText,
          fontSize: 15,
          fontFamily: 'Raleway',
        ),
        initialValue: initialValue,
        textFieldController: TextEditingController(),
        formatInput: true,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        inputDecoration: InputDecoration(
          hintText: 'Phone number',
          hintStyle: const TextStyle(
            color: AppColors.secondaryText,
            fontSize: 15,
            fontFamily: 'Raleway',
          ),
          filled: true,
          fillColor: AppColors.inputBackground.withOpacity(0.5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.primaryAccent,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1,
            ),
          ),
        ),
        textStyle: const TextStyle(
          color: AppColors.primaryText,
          fontSize: 15,
          fontFamily: 'Raleway',
        ),
        validator: validator,
    );
  }
}