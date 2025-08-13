class Validators {
  // Email validation
  static bool isValidEmail(String email) {
    final RegExp emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
  
  // Phone number validation (Kenyan format)
  static bool isValidKenyanPhone(String phone) {
    final RegExp kenyanPhoneRegex = RegExp(
      r'^(\+?254|0)?[17]\d{8}$',
    );
    String cleanedNumber = phone.replaceAll(RegExp(r'\s+'), '');
    return kenyanPhoneRegex.hasMatch(cleanedNumber);
  }
  
  // General African phone number validation
  static bool isValidAfricanPhone(String phone) {
    // Supports various African country codes
    final RegExp africanPhoneRegex = RegExp(
      r'^(\+?)(254|256|255|250|234|233|27|20|212|216|237|225|221|228|229|241|242|243|244|245|251|252|253|257|258|260|261|262|263|264|265|266|267|268|269)\d{7,9}$',
    );
    String cleanedNumber = phone.replaceAll(RegExp(r'\s+'), '');
    return africanPhoneRegex.hasMatch(cleanedNumber);
  }
  
  // Password validation
  static bool isValidPassword(String password) {
    // At least 8 characters, one uppercase, one lowercase, one number
    final RegExp passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }
  
  // Simple password validation (minimum 6 characters)
  static bool isSimplePasswordValid(String password) {
    return password.length >= 6;
  }
  
  // Name validation
  static bool isValidName(String name) {
    final RegExp nameRegex = RegExp(
      r"^[a-zA-Z]+(([',. -][a-zA-Z ])?[a-zA-Z]*)*$",
    );
    return name.length >= 2 && nameRegex.hasMatch(name);
  }
  
  // Business name validation
  static bool isValidBusinessName(String name) {
    return name.trim().length >= 2;
  }
  
  // URL validation
  static bool isValidUrl(String url) {
    final RegExp urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );
    return urlRegex.hasMatch(url);
  }
  
  // Form field validators for use in TextFormField
  static String? emailValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }
  
  static String? phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (!isValidKenyanPhone(value)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }
  
  static String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
  
  static String? strongPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (!isValidPassword(value)) {
      return 'Password must be at least 8 characters with uppercase, lowercase, and number';
    }
    return null;
  }
  
  static String? confirmPasswordValidator(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
  
  static String? nameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (!isValidName(value)) {
      return 'Please enter a valid name';
    }
    return null;
  }
  
  static String? requiredFieldValidator(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }
  
  static String? minLengthValidator(String? value, int minLength, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    if (value.length < minLength) {
      return '${fieldName ?? 'This field'} must be at least $minLength characters';
    }
    return null;
  }
  
  static String? maxLengthValidator(String? value, int maxLength, [String? fieldName]) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'This field'} must not exceed $maxLength characters';
    }
    return null;
  }
  
  static String? numberValidator(String? value, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }
  
  static String? priceValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }
    if (price < 0) {
      return 'Price cannot be negative';
    }
    return null;
  }
}