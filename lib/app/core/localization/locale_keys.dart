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
  static const forgotPasswordVerifyButton = 'forgot_password_verify_button';
  static const forgotPasswordResend = 'forgot_password_resend';
  static const forgotPasswordResendIn = 'forgot_password_resend_in';
  static const forgotPasswordChangeEmail = 'forgot_password_change_email';
  static const forgotPasswordCodeResent = 'forgot_password_code_resent';
  static const forgotPasswordNewTitle = 'forgot_password_new_title';
  static const forgotPasswordNewSubtitle = 'forgot_password_new_subtitle';
  static const forgotPasswordNewPassword = 'forgot_password_new_password';
  static const forgotPasswordSaveButton = 'forgot_password_save_button';
  static const forgotPasswordUpdated = 'forgot_password_updated';

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
  static const validatorCodeRequired = 'validator_code_required';
  static const validatorCodeInvalid = 'validator_code_invalid';

  // Home
  static const homeGreeting = 'home_greeting';
  static const homeGreetingGeneric = 'home_greeting_generic';
  static const homeSubtitle = 'home_subtitle';
  static const homeScanCtaTitle = 'home_scan_cta_title';
  static const homeScanCtaSubtitle = 'home_scan_cta_subtitle';
  static const homeReviewCta = 'home_review_cta';
  static const homeReviewCtaOne = 'home_review_cta_one';
  static const homeReviewEstimate = 'home_review_estimate';
  static const homeGoalToday = 'home_goal_today';
  static const homeCardsToday = 'home_cards_today';
  static const homeStreakBest = 'home_streak_best';
  static const homeAllCaughtUp = 'home_all_caught_up';
  static const homeCaughtUpToday = 'home_caught_up_today';
  static const homePracticeCta = 'home_practice_cta';
  static const homePracticeNote = 'home_practice_note';
  static const homeStreakStartHint = 'home_streak_start_hint';
  static const homeYourDecks = 'home_your_decks';
  static const homeNoDecksTitle = 'home_no_decks_title';
  static const homeNoDecksBody = 'home_no_decks_body';
  static const homeDeckCardCount = 'home_deck_card_count';
  static const homeSeeAll = 'home_see_all';

  // Decks tab
  static const decksMixedTitle = 'decks_mixed_title';
  static const decksMixedDue = 'decks_mixed_due';
  static const decksMixedPractice = 'decks_mixed_practice';
  static const decksStatDecks = 'decks_stat_decks';
  static const decksStatWords = 'decks_stat_words';
  static const decksStatDue = 'decks_stat_due';
  static const decksAll = 'decks_all';

  // Bottom nav
  static const navHome = 'nav_home';
  static const navScan = 'nav_scan';
  static const navDecks = 'nav_decks';

  // Profile
  static const profileYourAccount = 'profile_your_account';
  static const profileAppearance = 'profile_appearance';
  static const profileLanguage = 'profile_language';
  static const profileHelpSupport = 'profile_help_support';
  static const profileAbout = 'profile_about';
  static const profileSignOut = 'profile_sign_out';
  static const profileEditName = 'profile_edit_name';
  static const profileNameUpdated = 'profile_name_updated';
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
  static const deckListen = 'deck_listen';
  static const deckAllCaughtUp = 'deck_all_caught_up';
  static const deckDueNow = 'deck_due_now';

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
  static const studyGotIt = 'study_got_it';
  static const studyForgot = 'study_forgot';
  static const studyChoicePrompt = 'study_choice_prompt';
  static const studySwipeHint = 'study_swipe_hint';
  static const studyAccuracy = 'study_accuracy';
  static const studyStreakDays = 'study_streak_days';
  static const studyStreakStarted = 'study_streak_started';
  static const streakFreezeEarned = 'streak_freeze_earned';
  static const streakFreezeSavedOne = 'streak_freeze_saved_one';
  static const streakFreezeSavedMany = 'streak_freeze_saved_many';
  static const streakFreezeNextOne = 'streak_freeze_next_one';
  static const streakFreezeNext = 'streak_freeze_next';
  static const streakFreezesReady = 'streak_freezes_ready';
  static const streakInfoTitle = 'streak_info_title';
  static const streakInfoCurrent = 'streak_info_current';
  static const streakInfoFreezes = 'streak_info_freezes';
  static const streakInfoFreezesFull = 'streak_info_freezes_full';
  static const streakRuleDailyTitle = 'streak_rule_daily_title';
  static const streakRuleDailyBody = 'streak_rule_daily_body';
  static const streakRuleDayEndsTitle = 'streak_rule_day_ends_title';
  static const streakRuleDayEndsBody = 'streak_rule_day_ends_body';
  static const streakRuleEarnTitle = 'streak_rule_earn_title';
  static const streakRuleEarnBody = 'streak_rule_earn_body';
  static const streakRuleCoverTitle = 'streak_rule_cover_title';
  static const streakRuleCoverBody = 'streak_rule_cover_body';
  static const streakRuleResetTitle = 'streak_rule_reset_title';
  static const streakRuleResetBody = 'streak_rule_reset_body';
  static const studyGoalProgress = 'study_goal_progress';
  static const studyGoalMet = 'study_goal_met';
  static const studyContinue = 'study_continue';

  // Listening (hands-free) mode
  static const listenTitle = 'listen_title';
  static const listenHint = 'listen_hint';
  static const listenFinished = 'listen_finished';

  // Study reminders
  static const reminderNotificationTitle = 'reminder_notification_title';
  static const reminderNotificationBody = 'reminder_notification_body';
  static const reminderChannelName = 'reminder_channel_name';
  static const reminderChannelDescription = 'reminder_channel_description';
  static const reminderSettingsTitle = 'reminder_settings_title';
  static const reminderEveryDayAt = 'reminder_every_day_at';
  static const reminderOff = 'reminder_off';
  static const reminderPermissionDenied = 'reminder_permission_denied';

  // Study mode picker
  static const studyModeSmart = 'study_mode_smart';
  static const studyModeSmartHint = 'study_mode_smart_hint';
  static const studyModeQuiz = 'study_mode_quiz';
  static const studyModeQuizHint = 'study_mode_quiz_hint';
  static const studyModeFlip = 'study_mode_flip';
  static const studyModeFlipHint = 'study_mode_flip_hint';
  static const studyModeListenHint = 'study_mode_listen_hint';
  static const studyModeTitle = 'study_mode_title';

  // Daily goal
  static const goalSettingsTitle = 'goal_settings_title';
  static const goalCardsPerDay = 'goal_cards_per_day';
}
