/// Typed keys for every translatable string in the app, so a typo in a key
/// name is a compile error instead of silently falling back to the raw
/// key text at runtime. Usage: `LocaleKeys.loginWelcomeBack.tr`.
class LocaleKeys {
  LocaleKeys._();

  // Shared
  static const commonEmail = 'common_email';
  static const commonPassword = 'common_password';
  static const commonFullName = 'common_full_name';
  static const commonOr = 'common_or';
  static const commonSave = 'common_save';
  static const commonCancel = 'common_cancel';
  static const commonComingSoon = 'common_coming_soon';
  static const commonSomethingWentWrong = 'common_something_went_wrong';
  static const commonSuccess = 'common_success';

  // Onboarding
  static const onboardingSkip = 'onboarding_skip';
  static const onboardingNext = 'onboarding_next';
  static const onboardingGetStarted = 'onboarding_get_started';
  static const onboardingScanTitle = 'onboarding_scan_title';
  static const onboardingScanBody = 'onboarding_scan_body';
  static const onboardingWordsTitle = 'onboarding_words_title';
  static const onboardingWordsBody = 'onboarding_words_body';
  static const onboardingSentencesTitle = 'onboarding_sentences_title';
  static const onboardingSentencesBody = 'onboarding_sentences_body';
  static const onboardingDeckTitle = 'onboarding_deck_title';
  static const onboardingDeckBody = 'onboarding_deck_body';

  // Brand header
  static const brandTagline = 'brand_tagline';

  // Login
  static const loginWelcomeBack = 'login_welcome_back';
  static const loginSubtitle = 'login_subtitle';
  static const loginForgotPassword = 'login_forgot_password';
  static const loginButton = 'login_button';
  static const loginContinueGoogle = 'login_continue_google';
  static const loginContinueApple = 'login_continue_apple';
  static const loginNoAccount = 'login_no_account';
  static const loginSignUp = 'login_sign_up';

  // Signup
  static const signupTitle = 'signup_title';
  static const signupSubtitle = 'signup_subtitle';
  static const signupConfirmPassword = 'signup_confirm_password';
  static const signupButton = 'signup_button';
  static const signupNameRequired = 'signup_name_required';
  static const signupCheckInboxTitle = 'signup_check_inbox_title';
  static const signupCheckInboxBody = 'signup_check_inbox_body';

  // Forgot password
  static const forgotPasswordTitle = 'forgot_password_title';
  static const forgotPasswordSubtitle = 'forgot_password_subtitle';
  static const forgotPasswordButton = 'forgot_password_button';
  static const forgotPasswordCheckEmailTitle =
      'forgot_password_check_email_title';
  static const forgotPasswordCheckEmailBody =
      'forgot_password_check_email_body';
  static const forgotPasswordBackToLogin = 'forgot_password_back_to_login';

  // Validators
  static const validatorEmailRequired = 'validator_email_required';
  static const validatorEmailInvalid = 'validator_email_invalid';
  static const validatorPasswordRequired = 'validator_password_required';
  static const validatorPasswordTooShort = 'validator_password_too_short';
  static const validatorConfirmPasswordRequired =
      'validator_confirm_password_required';
  static const validatorPasswordsDontMatch = 'validator_passwords_dont_match';
  static const validatorFieldRequired = 'validator_field_required';
  static const validatorNameRequired = 'validator_name_required';

  // Home
  static const homeGreeting = 'home_greeting';
  static const homeGreetingGeneric = 'home_greeting_generic';
  static const homeSubtitle = 'home_subtitle';
  static const homeScanCtaTitle = 'home_scan_cta_title';
  static const homeScanCtaSubtitle = 'home_scan_cta_subtitle';
  static const homeYourDecks = 'home_your_decks';
  static const homeNoDecksTitle = 'home_no_decks_title';
  static const homeNoDecksBody = 'home_no_decks_body';
  static const homeDeckCardCount = 'home_deck_card_count';
  static const homeSeeAll = 'home_see_all';

  // Bottom nav
  static const navHome = 'nav_home';
  static const navScan = 'nav_scan';
  static const navDecks = 'nav_decks';

  // Profile
  static const profileYourAccount = 'profile_your_account';
  static const profileNotifications = 'profile_notifications';
  static const profileAppearance = 'profile_appearance';
  static const profileLanguage = 'profile_language';
  static const profileHelpSupport = 'profile_help_support';
  static const profileAbout = 'profile_about';
  static const profileSignOut = 'profile_sign_out';
  static const profileEditName = 'profile_edit_name';
  static const profileNameUpdated = 'profile_name_updated';
  static const profileNotificationsComingSoon =
      'profile_notifications_coming_soon';
  static const profileAboutComingSoon = 'profile_about_coming_soon';
  static const themeSystem = 'theme_system';
  static const themeLight = 'theme_light';
  static const themeDark = 'theme_dark';

  // Help
  static const helpTitle = 'help_title';
  static const helpFaqTitle = 'help_faq_title';
  static const helpFaq1Q = 'help_faq_1_q';
  static const helpFaq1A = 'help_faq_1_a';
  static const helpFaq2Q = 'help_faq_2_q';
  static const helpFaq2A = 'help_faq_2_a';
  static const helpFaq3Q = 'help_faq_3_q';
  static const helpFaq3A = 'help_faq_3_a';
  static const helpFaq4Q = 'help_faq_4_q';
  static const helpFaq4A = 'help_faq_4_a';
  static const helpFaq5Q = 'help_faq_5_q';
  static const helpFaq5A = 'help_faq_5_a';
  static const helpStillNeedHelp = 'help_still_need_help';
  static const helpSendMessageBody = 'help_send_message_body';
  static const helpYourMessage = 'help_your_message';
  static const helpMessageHint = 'help_message_hint';
  static const helpEmailSupportButton = 'help_email_support_button';
  static const helpEmptyMessageError = 'help_empty_message_error';
  static const helpNoEmailAppError = 'help_no_email_app_error';
  static const helpMailSubject = 'help_mail_subject';

  // Scan
  static const scanSourceTitle = 'scan_source_title';
  static const scanSourceSubtitle = 'scan_source_subtitle';
  static const scanTakePhoto = 'scan_take_photo';
  static const scanChooseFromGallery = 'scan_choose_from_gallery';
  static const scanRetake = 'scan_retake';
  static const scanUsePhoto = 'scan_use_photo';
  static const scanReadingText = 'scan_reading_text';
  static const scanSelectWordsTitle = 'scan_select_words_title';
  static const scanSelectWordsSubtitle = 'scan_select_words_subtitle';
  static const scanSelectAll = 'scan_select_all';
  static const scanDeselectAll = 'scan_deselect_all';
  static const scanSelectedCount = 'scan_selected_count';
  static const scanContinueButton = 'scan_continue_button';
  static const scanNoTextFoundTitle = 'scan_no_text_found_title';
  static const scanNoTextFoundBody = 'scan_no_text_found_body';
  static const scanTryAgain = 'scan_try_again';
  static const scanProcessingError = 'scan_processing_error';
  static const scanDetectedLanguage = 'scan_detected_language';
  static const scanTargetLanguageTitle = 'scan_target_language_title';
  static const scanTargetLanguageBody = 'scan_target_language_body';
  static const scanSavingDeck = 'scan_saving_deck';
  static const scanDeckCreatedSuccess = 'scan_deck_created_success';
  static const scanDeckSaveError = 'scan_deck_save_error';

  // Permissions
  static const permissionCameraTitle = 'permission_camera_title';
  static const permissionCameraBody = 'permission_camera_body';
  static const permissionGalleryTitle = 'permission_gallery_title';
  static const permissionGalleryBody = 'permission_gallery_body';
  static const permissionAllow = 'permission_allow';
  static const permissionNotNow = 'permission_not_now';
  static const permissionDeniedTitle = 'permission_denied_title';
  static const permissionCameraDeniedBody = 'permission_camera_denied_body';
  static const permissionGalleryDeniedBody = 'permission_gallery_denied_body';
  static const permissionOpenSettings = 'permission_open_settings';

  // Deck detail
  static const deckLoadError = 'deck_load_error';
  static const deckSummary = 'deck_summary';
  static const deckRenameTitle = 'deck_rename_title';
  static const deckRenameError = 'deck_rename_error';
  static const deckDeleteTitle = 'deck_delete_title';
  static const deckDeleteBody = 'deck_delete_body';
  static const deckDeleteConfirm = 'deck_delete_confirm';
  static const deckDeletedSuccess = 'deck_deleted_success';
  static const deckDeleteError = 'deck_delete_error';
  static const deckStudy = 'deck_study';
  static const deckStudyDue = 'deck_study_due';

  // Card detail
  static const cardDetailReviewedOnce = 'card_detail_reviewed_once';
  static const cardDetailReviewedTimes = 'card_detail_reviewed_times';
  static const cardDetailNotReviewedYet = 'card_detail_not_reviewed_yet';
  static const cardDetailNextReviewToday = 'card_detail_next_review_today';
  static const cardDetailNextReviewInDays = 'card_detail_next_review_in_days';

  // Study session
  static const studyProgress = 'study_progress';
  static const studyTapToReveal = 'study_tap_to_reveal';
  static const studyGradeAgain = 'study_grade_again';
  static const studyGradeHard = 'study_grade_hard';
  static const studyGradeGood = 'study_grade_good';
  static const studyGradeEasy = 'study_grade_easy';
  static const studyNothingDueTitle = 'study_nothing_due_title';
  static const studyNothingDueBody = 'study_nothing_due_body';
  static const studyCompleteTitle = 'study_complete_title';
  static const studyCompleteBody = 'study_complete_body';
  static const studyDone = 'study_done';
}
