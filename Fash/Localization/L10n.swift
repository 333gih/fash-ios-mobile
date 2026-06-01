import Foundation

/// Type-safe localization mirroring Android `R.string.*`.
enum L10n {
    // Resolved via L10nBundle.swift + vi/en .lproj

    static var accountSwitchDialogConfirm: String { t("account_switch_dialog_confirm") }
    static var accountSwitchDialogDismiss: String { t("account_switch_dialog_dismiss") }
    static func accountSwitchDialogMessage(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("account_switch_dialog_message"), a1, a2)
    }
    static var accountSwitchDialogTitle: String { t("account_switch_dialog_title") }
    static func accountSwitchNotificationBody(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("account_switch_notification_body"), a1, a2)
    }
    static var accountSwitchNotificationTitle: String { t("account_switch_notification_title") }
    static var addToCart: String { t("add_to_cart") }
    static var addressAddNew: String { t("address_add_new") }
    static var addressAddTitle: String { t("address_add_title") }
    static var addressBadgeDefault: String { t("address_badge_default") }
    static var addressCatalogLoadFailed: String { t("address_catalog_load_failed") }
    static var addressConfirm: String { t("address_confirm") }
    static var addressCountryFixed: String { t("address_country_fixed") }
    static var addressCountryVn: String { t("address_country_vn") }
    static var addressDefaultFailed: String { t("address_default_failed") }
    static var addressDefaultToggle: String { t("address_default_toggle") }
    static var addressDefaultToggleSub: String { t("address_default_toggle_sub") }
    static var addressDone: String { t("address_done") }
    static var addressDropdownNoOptions: String { t("address_dropdown_no_options") }
    static var addressEmptyAlertBody: String { t("address_empty_alert_body") }
    static var addressEmptyAlertCreate: String { t("address_empty_alert_create") }
    static var addressEmptyAlertTitle: String { t("address_empty_alert_title") }
    static var addressFieldCity: String { t("address_field_city") }
    static var addressFieldCityHint: String { t("address_field_city_hint") }
    static var addressFieldDistrict: String { t("address_field_district") }
    static var addressFieldDistrictHint: String { t("address_field_district_hint") }
    static var addressFieldFullName: String { t("address_field_full_name") }
    static var addressFieldFullNameHint: String { t("address_field_full_name_hint") }
    static var addressFieldLabelHint: String { t("address_field_label_hint") }
    static var addressFieldLabelOptional: String { t("address_field_label_optional") }
    static var addressFieldLine1: String { t("address_field_line1") }
    static var addressFieldLine1Hint: String { t("address_field_line1_hint") }
    static var addressFieldLine2Hint: String { t("address_field_line2_hint") }
    static var addressFieldLine2Optional: String { t("address_field_line2_optional") }
    static var addressFieldPhone: String { t("address_field_phone") }
    static var addressFieldPhoneHint: String { t("address_field_phone_hint") }
    static var addressFieldPostalHint: String { t("address_field_postal_hint") }
    static var addressFieldPostalOptional: String { t("address_field_postal_optional") }
    static var addressFieldProvince: String { t("address_field_province") }
    static var addressFieldWard: String { t("address_field_ward") }
    static var addressFieldWardHint: String { t("address_field_ward_hint") }
    static var addressFormHeader: String { t("address_form_header") }
    static var addressListHeader: String { t("address_list_header") }
    static var addressListSubtitle: String { t("address_list_subtitle") }
    static var addressListSubtitleManage: String { t("address_list_subtitle_manage") }
    static var addressListTitle: String { t("address_list_title") }
    static var addressSave: String { t("address_save") }
    static var addressSavedSuccess: String { t("address_saved_success") }
    static var addressSectionShipping: String { t("address_section_shipping") }
    static var addressSelectDistrict: String { t("address_select_district") }
    static var addressSelectProvince: String { t("address_select_province") }
    static var addressSelectWard: String { t("address_select_ward") }
    static var addressSetDefault: String { t("address_set_default") }
    static var addressSyncFailed: String { t("address_sync_failed") }
    static var addressValidationRequired: String { t("address_validation_required") }
    static var addressVnCatalogHint: String { t("address_vn_catalog_hint") }
    static var appName: String { t("app_name") }
    static var appPromoCdClose: String { t("app_promo_cd_close") }
    static var appPromoCdCollapse: String { t("app_promo_cd_collapse") }
    static var appPromoCdExpand: String { t("app_promo_cd_expand") }
    static func appPromoImagePage(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("app_promo_image_page"), a1, a2)
    }
    static func appPromoImagePagerCd(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("app_promo_image_pager_cd"), a1, a2)
    }
    static var appPromoKycBadge: String { t("app_promo_kyc_badge") }
    static var appPromoKycMessage: String { t("app_promo_kyc_message") }
    static var appPromoKycPrimary: String { t("app_promo_kyc_primary") }
    static var appPromoKycTitle: String { t("app_promo_kyc_title") }
    static var appPromoRatingMessage: String { t("app_promo_rating_message") }
    static var appPromoRatingPrimary: String { t("app_promo_rating_primary") }
    static var appPromoRatingTitle: String { t("app_promo_rating_title") }
    static var appPromoSecondaryLater: String { t("app_promo_secondary_later") }
    static var appPromoSellerPackageBadge: String { t("app_promo_seller_package_badge") }
    static var appPromoSellerPackageMessage: String { t("app_promo_seller_package_message") }
    static var appPromoSellerPackagePrimary: String { t("app_promo_seller_package_primary") }
    static var appPromoSellerPackageTitle: String { t("app_promo_seller_package_title") }
    static var appTourBack: String { t("app_tour_back") }
    static var appTourChip: String { t("app_tour_chip") }
    static var appTourDone: String { t("app_tour_done") }
    static var appTourIntroBody: String { t("app_tour_intro_body") }
    static var appTourIntroTitle: String { t("app_tour_intro_title") }
    static var appTourNavChatBody: String { t("app_tour_nav_chat_body") }
    static var appTourNavChatTitle: String { t("app_tour_nav_chat_title") }
    static var appTourNavHomeBody: String { t("app_tour_nav_home_body") }
    static var appTourNavHomeTitle: String { t("app_tour_nav_home_title") }
    static var appTourNavOrdersBody: String { t("app_tour_nav_orders_body") }
    static var appTourNavOrdersTitle: String { t("app_tour_nav_orders_title") }
    static var appTourNavPostBody: String { t("app_tour_nav_post_body") }
    static var appTourNavPostTitle: String { t("app_tour_nav_post_title") }
    static var appTourNavProfileBody: String { t("app_tour_nav_profile_body") }
    static var appTourNavProfileTitle: String { t("app_tour_nav_profile_title") }
    static var appTourNext: String { t("app_tour_next") }
    static var appTourSkip: String { t("app_tour_skip") }
    static var appTourTopBarBody: String { t("app_tour_top_bar_body") }
    static var appTourTopBarTitle: String { t("app_tour_top_bar_title") }
    static var appointmentCardTicket: String { t("appointment_card_ticket") }
    static var avatarDefaultCd: String { t("avatar_default_cd") }
    static var badgeReviewLoadError: String { t("badge_review_load_error") }
    static var badgeReviewRequired: String { t("badge_review_required") }
    static var badgeReviewSubtitle: String { t("badge_review_subtitle") }
    static var badgeReviewTitle: String { t("badge_review_title") }
    static var brandHeaderSuffixChat: String { t("brand_header_suffix_chat") }
    static var brandHeaderSuffixExplore: String { t("brand_header_suffix_explore") }
    static var brandHeaderSuffixHome: String { t("brand_header_suffix_home") }
    static var brandHeaderSuffixOrders: String { t("brand_header_suffix_orders") }
    static var brandHeaderSuffixPost: String { t("brand_header_suffix_post") }
    static var brandHeaderSuffixProfile: String { t("brand_header_suffix_profile") }
    static var brandWordmark: String { t("brand_wordmark") }
    static func browseLocationChip(_ a1: CVarArg) -> String {
        String(format: t("browse_location_chip"), a1)
    }
    static var browseLocationPick: String { t("browse_location_pick") }
    static var browseLocationPickerApply: String { t("browse_location_picker_apply") }
    static var browseLocationPickerHierarchyHint: String { t("browse_location_picker_hierarchy_hint") }
    static var browseLocationPickerSearchDistrict: String { t("browse_location_picker_search_district") }
    static var browseLocationPickerSearchProvince: String { t("browse_location_picker_search_province") }
    static var browseLocationPickerStepDistrict: String { t("browse_location_picker_step_district") }
    static var browseLocationPickerStepProvince: String { t("browse_location_picker_step_province") }
    static var browseLocationPickerTitle: String { t("browse_location_picker_title") }
    static var browseLocationPickerWardOptional: String { t("browse_location_picker_ward_optional") }
    static var buyNow: String { t("buy_now") }
    static var cdBack: String { t("cd_back") }
    static var cdOverflowMenu: String { t("cd_overflow_menu") }
    static var changePasswordSave: String { t("change_password_save") }
    static var changePasswordSubtitle: String { t("change_password_subtitle") }
    static var changePasswordTitle: String { t("change_password_title") }
    static func chatC2cAgreedBody(_ a1: CVarArg) -> String {
        String(format: t("chat_c2c_agreed_body"), a1)
    }
    static var chatC2cAgreedTitle: String { t("chat_c2c_agreed_title") }
    static var chatC2cScheduleMeeting: String { t("chat_c2c_schedule_meeting") }
    static var chatConversationEndedReadonly: String { t("chat_conversation_ended_readonly") }
    static var chatConversationSoldReadonly: String { t("chat_conversation_sold_readonly") }
    static func chatCounterMustBeAboveBuyer(_ a1: CVarArg) -> String {
        String(format: t("chat_counter_must_be_above_buyer"), a1)
    }
    static var chatCounterOfferLabel: String { t("chat_counter_offer_label") }
    static var chatCounterOfferMin: String { t("chat_counter_offer_min") }
    static func chatCounterSheetBuyerOffer(_ a1: CVarArg) -> String {
        String(format: t("chat_counter_sheet_buyer_offer"), a1)
    }
    static var chatCounterSheetSubmit: String { t("chat_counter_sheet_submit") }
    static var chatCounterSheetTitle: String { t("chat_counter_sheet_title") }
    static var chatCounterWaitingBuyer: String { t("chat_counter_waiting_buyer") }
    static var chatDayFri: String { t("chat_day_fri") }
    static var chatDayMon: String { t("chat_day_mon") }
    static var chatDaySat: String { t("chat_day_sat") }
    static var chatDaySun: String { t("chat_day_sun") }
    static var chatDayThu: String { t("chat_day_thu") }
    static var chatDayTue: String { t("chat_day_tue") }
    static var chatDayWed: String { t("chat_day_wed") }
    static var chatDealBannerBuyerPending: String { t("chat_deal_banner_buyer_pending") }
    static var chatDealBannerCancelled: String { t("chat_deal_banner_cancelled") }
    static var chatDealBannerCashMeetup: String { t("chat_deal_banner_cash_meetup") }
    static var chatDealBannerChooseFulfillment: String { t("chat_deal_banner_choose_fulfillment") }
    static var chatDealBannerDelivered: String { t("chat_deal_banner_delivered") }
    static var chatDealBannerDisputed: String { t("chat_deal_banner_disputed") }
    static var chatDealBannerDone: String { t("chat_deal_banner_done") }
    static var chatDealBannerInProgress: String { t("chat_deal_banner_in_progress") }
    static var chatDealBannerSellerPending: String { t("chat_deal_banner_seller_pending") }
    static var chatDealBannerStatusPending: String { t("chat_deal_banner_status_pending") }
    static var chatDealBannerViewOrder: String { t("chat_deal_banner_view_order") }
    static var chatDealEscrowContinueCta: String { t("chat_deal_escrow_continue_cta") }
    static var chatDealMeetupBothCheckedInBuyer: String { t("chat_deal_meetup_both_checked_in_buyer") }
    static var chatDealMeetupBothCheckedInBuyerInTransit: String { t("chat_deal_meetup_both_checked_in_buyer_in_transit") }
    static var chatDealMeetupBothCheckedInSeller: String { t("chat_deal_meetup_both_checked_in_seller") }
    static var chatDealMeetupBothCheckedInSellerInTransit: String { t("chat_deal_meetup_both_checked_in_seller_in_transit") }
    static func chatDealMeetupPayDeadline(_ a1: CVarArg) -> String {
        String(format: t("chat_deal_meetup_pay_deadline"), a1)
    }
    static var chatDealPaymentDeadlineWarningBuyer: String { t("chat_deal_payment_deadline_warning_buyer") }
    static var chatDealPaymentDeadlineWarningSeller: String { t("chat_deal_payment_deadline_warning_seller") }
    static var chatDealScheduleMeetupCta: String { t("chat_deal_schedule_meetup_cta") }
    static var chatDealSosUnlockedHint: String { t("chat_deal_sos_unlocked_hint") }
    static var chatDeleteMessageBody: String { t("chat_delete_message_body") }
    static var chatDeleteMessageConfirm: String { t("chat_delete_message_confirm") }
    static var chatDeleteMessageTitle: String { t("chat_delete_message_title") }
    static var chatDetailAccept: String { t("chat_detail_accept") }
    static var chatDetailActive: String { t("chat_detail_active") }
    static var chatDetailBackCd: String { t("chat_detail_back_cd") }
    static func chatDetailBackInboxUnreadCd(_ a1: CVarArg) -> String {
        String(format: t("chat_detail_back_inbox_unread_cd"), a1)
    }
    static var chatDetailDecline: String { t("chat_detail_decline") }
    static var chatDetailHeaderProfileCd: String { t("chat_detail_header_profile_cd") }
    static var chatDetailMessagePlaceholder: String { t("chat_detail_message_placeholder") }
    static var chatDetailOfferPrompt: String { t("chat_detail_offer_prompt") }
    static func chatDetailOtherInboxUnread(_ a1: CVarArg) -> String {
        String(format: t("chat_detail_other_inbox_unread"), a1)
    }
    static var chatDetailPriceProposal: String { t("chat_detail_price_proposal") }
    static var chatDetailRead: String { t("chat_detail_read") }
    static var chatDetailSetPrice: String { t("chat_detail_set_price") }
    static var chatDetailViewProduct: String { t("chat_detail_view_product") }
    static var chatEmpty: String { t("chat_empty") }
    static var chatEmptyMessagesSubtitle: String { t("chat_empty_messages_subtitle") }
    static var chatEmptyMessagesTip1: String { t("chat_empty_messages_tip_1") }
    static var chatEmptyMessagesTip2: String { t("chat_empty_messages_tip_2") }
    static var chatEmptyMessagesTitle: String { t("chat_empty_messages_title") }
    static var chatEmptySubtitle: String { t("chat_empty_subtitle") }
    static var chatEmptySuggestionsTitle: String { t("chat_empty_suggestions_title") }
    static var chatEmptyTip1: String { t("chat_empty_tip_1") }
    static var chatEmptyTip2: String { t("chat_empty_tip_2") }
    static var chatErrorConversationClosed: String { t("chat_error_conversation_closed") }
    static var chatErrorConversationOrderExists: String { t("chat_error_conversation_order_exists") }
    static var chatErrorForbidden: String { t("chat_error_forbidden") }
    static var chatErrorNotFound: String { t("chat_error_not_found") }
    static func chatErrorOfferLimit(_ a1: CVarArg) -> String {
        String(format: t("chat_error_offer_limit"), a1)
    }
    static var chatErrorOrderExists: String { t("chat_error_order_exists") }
    static var chatErrorPendingOffer: String { t("chat_error_pending_offer") }
    static var chatFilterAll: String { t("chat_filter_all") }
    static var chatFilterBuyer: String { t("chat_filter_buyer") }
    static var chatFilterSeller: String { t("chat_filter_seller") }
    static var chatFilterUnread: String { t("chat_filter_unread") }
    static var chatFulfillmentBannerCta: String { t("chat_fulfillment_banner_cta") }
    static var chatFulfillmentCancelOrderSubtitle: String { t("chat_fulfillment_cancel_order_subtitle") }
    static var chatFulfillmentCancelOrderTitle: String { t("chat_fulfillment_cancel_order_title") }
    static var chatFulfillmentChooseFailed: String { t("chat_fulfillment_choose_failed") }
    static var chatFulfillmentOptionMeetupSubtitle: String { t("chat_fulfillment_option_meetup_subtitle") }
    static var chatFulfillmentOptionMeetupTitle: String { t("chat_fulfillment_option_meetup_title") }
    static var chatFulfillmentOptionShipComingSoon: String { t("chat_fulfillment_option_ship_coming_soon") }
    static var chatFulfillmentOptionShipSubtitle: String { t("chat_fulfillment_option_ship_subtitle") }
    static var chatFulfillmentOptionShipTitle: String { t("chat_fulfillment_option_ship_title") }
    static var chatFulfillmentSheetSubtitle: String { t("chat_fulfillment_sheet_subtitle") }
    static var chatFulfillmentSheetSubtitleShipDisabled: String { t("chat_fulfillment_sheet_subtitle_ship_disabled") }
    static var chatFulfillmentSheetTitle: String { t("chat_fulfillment_sheet_title") }
    static var chatFulfillmentShipDisabledBody: String { t("chat_fulfillment_ship_disabled_body") }
    static var chatFulfillmentShipDisabledTitle: String { t("chat_fulfillment_ship_disabled_title") }
    static func chatGroupUnreadCd(_ a1: CVarArg) -> String {
        String(format: t("chat_group_unread_cd"), a1)
    }
    static var chatHasUnreadCd: String { t("chat_has_unread_cd") }
    static func chatHoursAgo(_ a1: CVarArg) -> String {
        String(format: t("chat_hours_ago"), a1)
    }
    static var chatInboxAdCta: String { t("chat_inbox_ad_cta") }
    static var chatInboxAdSubtitle: String { t("chat_inbox_ad_subtitle") }
    static var chatInboxAdTitle: String { t("chat_inbox_ad_title") }
    static var chatInboxByProduct: String { t("chat_inbox_by_product") }
    static var chatInboxListFooterHint: String { t("chat_inbox_list_footer_hint") }
    static func chatInboxPreviewOfferFromBuyer(_ a1: CVarArg) -> String {
        String(format: t("chat_inbox_preview_offer_from_buyer"), a1)
    }
    static func chatInboxPreviewOfferFromSeller(_ a1: CVarArg) -> String {
        String(format: t("chat_inbox_preview_offer_from_seller"), a1)
    }
    static func chatInboxPreviewOfferGeneric(_ a1: CVarArg) -> String {
        String(format: t("chat_inbox_preview_offer_generic"), a1)
    }
    static func chatInboxPreviewOfferPendingSeller(_ a1: CVarArg) -> String {
        String(format: t("chat_inbox_preview_offer_pending_seller"), a1)
    }
    static func chatInboxPreviewOfferYou(_ a1: CVarArg) -> String {
        String(format: t("chat_inbox_preview_offer_you"), a1)
    }
    static var chatInboxPreviewOrderCancelledSeller: String { t("chat_inbox_preview_order_cancelled_seller") }
    static var chatInboxPreviewOrderCancelledShort: String { t("chat_inbox_preview_order_cancelled_short") }
    static var chatInboxPreviewPlaceholder: String { t("chat_inbox_preview_placeholder") }
    static func chatInboxUnreadBanner(_ a1: CVarArg) -> String {
        String(format: t("chat_inbox_unread_banner"), a1)
    }
    static var chatInputHint: String { t("chat_input_hint") }
    static var chatJustNow: String { t("chat_just_now") }
    static var chatListingSoldLabel: String { t("chat_listing_sold_label") }
    static var chatLoadError: String { t("chat_load_error") }
    static var chatMeetingCancelSuggestReopen: String { t("chat_meeting_cancel_suggest_reopen") }
    static var chatMeetingCancelledOk: String { t("chat_meeting_cancelled_ok") }
    static var chatMeetingCardTitle: String { t("chat_meeting_card_title") }
    static var chatMeetingCheckInAlready: String { t("chat_meeting_check_in_already") }
    static var chatMeetingCheckInCta: String { t("chat_meeting_check_in_cta") }
    static var chatMeetingCheckInNotOrderComplete: String { t("chat_meeting_check_in_not_order_complete") }
    static var chatMeetingCheckInOk: String { t("chat_meeting_check_in_ok") }
    static var chatMeetingCheckInRefreshOnly: String { t("chat_meeting_check_in_refresh_only") }
    static var chatMeetingCheckInWindowError: String { t("chat_meeting_check_in_window_error") }
    static var chatMeetingCheckInWindowHint: String { t("chat_meeting_check_in_window_hint") }
    static var chatMeetingConfirm: String { t("chat_meeting_confirm") }
    static var chatMeetingConfirmedNoMapsHint: String { t("chat_meeting_confirmed_no_maps_hint") }
    static var chatMeetingConfirmedOk: String { t("chat_meeting_confirmed_ok") }
    static var chatMeetingDatePickerTitle: String { t("chat_meeting_date_picker_title") }
    static var chatMeetingDatetimeLabel: String { t("chat_meeting_datetime_label") }
    static var chatMeetingDatetimePlaceholder: String { t("chat_meeting_datetime_placeholder") }
    static var chatMeetingError: String { t("chat_meeting_error") }
    static var chatMeetingFieldMapsHint: String { t("chat_meeting_field_maps_hint") }
    static var chatMeetingFieldMapsUrl: String { t("chat_meeting_field_maps_url") }
    static var chatMeetingIsoPreviewLabel: String { t("chat_meeting_iso_preview_label") }
    static var chatMeetingMapsUrlInvalid: String { t("chat_meeting_maps_url_invalid") }
    static var chatMeetingNextStepsBuyerAfterCheckIn: String { t("chat_meeting_next_steps_buyer_after_check_in") }
    static var chatMeetingNextStepsSellerAfterCheckIn: String { t("chat_meeting_next_steps_seller_after_check_in") }
    static var chatMeetingOpenMaps: String { t("chat_meeting_open_maps") }
    static func chatMeetingOtherCheckedInAt(_ a1: CVarArg) -> String {
        String(format: t("chat_meeting_other_checked_in_at"), a1)
    }
    static var chatMeetingPickDate: String { t("chat_meeting_pick_date") }
    static var chatMeetingPickTime: String { t("chat_meeting_pick_time") }
    static var chatMeetingPickerCancel: String { t("chat_meeting_picker_cancel") }
    static var chatMeetingPickerOk: String { t("chat_meeting_picker_ok") }
    static var chatMeetingProposedOk: String { t("chat_meeting_proposed_ok") }
    static var chatMeetingRecordDeal: String { t("chat_meeting_record_deal") }
    static var chatMeetingReject: String { t("chat_meeting_reject") }
    static var chatMeetingReminder1440: String { t("chat_meeting_reminder_1440") }
    static var chatMeetingReminder15: String { t("chat_meeting_reminder_15") }
    static var chatMeetingReminder30: String { t("chat_meeting_reminder_30") }
    static var chatMeetingReminder60: String { t("chat_meeting_reminder_60") }
    static var chatMeetingReminderLabel: String { t("chat_meeting_reminder_label") }
    static var chatMeetingReminderToggle: String { t("chat_meeting_reminder_toggle") }
    static var chatMeetingSheetSubmit: String { t("chat_meeting_sheet_submit") }
    static var chatMeetingSheetSubtitle: String { t("chat_meeting_sheet_subtitle") }
    static var chatMeetingSheetSubtitleManual: String { t("chat_meeting_sheet_subtitle_manual") }
    static var chatMeetingSheetSubtitleSafe: String { t("chat_meeting_sheet_subtitle_safe") }
    static var chatMeetingSheetTitle: String { t("chat_meeting_sheet_title") }
    static var chatMeetingStateDescCancelled: String { t("chat_meeting_state_desc_cancelled") }
    static var chatMeetingStateDescConfirmed: String { t("chat_meeting_state_desc_confirmed") }
    static var chatMeetingStateDescPending: String { t("chat_meeting_state_desc_pending") }
    static var chatMeetingStatusCancelled: String { t("chat_meeting_status_cancelled") }
    static var chatMeetingStatusConfirmed: String { t("chat_meeting_status_confirmed") }
    static var chatMeetingStatusPending: String { t("chat_meeting_status_pending") }
    static func chatMeetingTimeFromNowHint(_ a1: CVarArg) -> String {
        String(format: t("chat_meeting_time_from_now_hint"), a1)
    }
    static var chatMeetingTimePickerTitle: String { t("chat_meeting_time_picker_title") }
    static var chatMeetingWithdraw: String { t("chat_meeting_withdraw") }
    static func chatMeetingYouCheckedInAt(_ a1: CVarArg) -> String {
        String(format: t("chat_meeting_you_checked_in_at"), a1)
    }
    static var chatMessageOrderCancelledByBuyer: String { t("chat_message_order_cancelled_by_buyer") }
    static func chatMinsAgo(_ a1: CVarArg) -> String {
        String(format: t("chat_mins_ago"), a1)
    }
    static func chatNewMessagesBelow(_ a1: CVarArg) -> String {
        String(format: t("chat_new_messages_below"), a1)
    }
    static var chatOfferAccept: String { t("chat_offer_accept") }
    static var chatOfferAccepted: String { t("chat_offer_accepted") }
    static var chatOfferAcceptedInChat: String { t("chat_offer_accepted_in_chat") }
    static var chatOfferAcceptedLabel: String { t("chat_offer_accepted_label") }
    static var chatOfferBlockedActiveMeetup: String { t("chat_offer_blocked_active_meetup") }
    static var chatOfferCheckout: String { t("chat_offer_checkout") }
    static var chatOfferCounterCta: String { t("chat_offer_counter_cta") }
    static var chatOfferDecline: String { t("chat_offer_decline") }
    static var chatOfferDialogHelper: String { t("chat_offer_dialog_helper") }
    static var chatOfferDialogHint: String { t("chat_offer_dialog_hint") }
    static func chatOfferDialogListedPrice(_ a1: CVarArg) -> String {
        String(format: t("chat_offer_dialog_listed_price"), a1)
    }
    static var chatOfferDialogPlaceholder: String { t("chat_offer_dialog_placeholder") }
    static var chatOfferDialogSubmit: String { t("chat_offer_dialog_submit") }
    static var chatOfferDialogTitle: String { t("chat_offer_dialog_title") }
    static var chatOfferError: String { t("chat_offer_error") }
    static var chatOfferLabel: String { t("chat_offer_label") }
    static func chatOfferLimitResetBanner(_ a1: CVarArg) -> String {
        String(format: t("chat_offer_limit_reset_banner"), a1)
    }
    static func chatOfferLimitTooltip(_ a1: CVarArg) -> String {
        String(format: t("chat_offer_limit_tooltip"), a1)
    }
    static var chatOfferMeetupLockTooltip: String { t("chat_offer_meetup_lock_tooltip") }
    static func chatOfferMustBeBelowListed(_ a1: CVarArg) -> String {
        String(format: t("chat_offer_must_be_below_listed"), a1)
    }
    static func chatOfferPolicyAtLimit(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("chat_offer_policy_at_limit"), a1, a2)
    }
    static func chatOfferPolicyIntro(_ a1: CVarArg) -> String {
        String(format: t("chat_offer_policy_intro"), a1)
    }
    static func chatOfferPolicyLast(_ a1: CVarArg) -> String {
        String(format: t("chat_offer_policy_last"), a1)
    }
    static func chatOfferPolicyProgress(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("chat_offer_policy_progress"), a1, a2)
    }
    static var chatOfferSending: String { t("chat_offer_sending") }
    static var chatOfferStatusAccepted: String { t("chat_offer_status_accepted") }
    static var chatOfferStatusCancelled: String { t("chat_offer_status_cancelled") }
    static var chatOfferStatusDeclined: String { t("chat_offer_status_declined") }
    static var chatOfferStatusExpired: String { t("chat_offer_status_expired") }
    static var chatOfferStatusWaiting: String { t("chat_offer_status_waiting") }
    static var chatOfferWaitingSeller: String { t("chat_offer_waiting_seller") }
    static var chatOfflineDealAgreedPriceHint: String { t("chat_offline_deal_agreed_price_hint") }
    static var chatOfflineDealBannerCompleted: String { t("chat_offline_deal_banner_completed") }
    static var chatOfflineDealBannerScheduled: String { t("chat_offline_deal_banner_scheduled") }
    static var chatOfflineDealBannerTitle: String { t("chat_offline_deal_banner_title") }
    static var chatOfflineDealCancelRecord: String { t("chat_offline_deal_cancel_record") }
    static var chatOfflineDealCancelledOk: String { t("chat_offline_deal_cancelled_ok") }
    static var chatOfflineDealComplete: String { t("chat_offline_deal_complete") }
    static var chatOfflineDealCompletedOk: String { t("chat_offline_deal_completed_ok") }
    static var chatOfflineDealCreated: String { t("chat_offline_deal_created") }
    static var chatOfflineDealError: String { t("chat_offline_deal_error") }
    static var chatOfflineDealErrorListing: String { t("chat_offline_deal_error_listing") }
    static var chatOfflineDealErrorTime: String { t("chat_offline_deal_error_time") }
    static var chatOfflineDealNoConfirmedMeetup: String { t("chat_offline_deal_no_confirmed_meetup") }
    static var chatOfflineDealReviewHint: String { t("chat_offline_deal_review_hint") }
    static var chatOfflineDealReviewOk: String { t("chat_offline_deal_review_ok") }
    static var chatOfflineDealReviewSkip: String { t("chat_offline_deal_review_skip") }
    static var chatOfflineDealReviewSubmit: String { t("chat_offline_deal_review_submit") }
    static var chatOfflineDealReviewTitle: String { t("chat_offline_deal_review_title") }
    static var chatOfflineDealSheetSubtitle: String { t("chat_offline_deal_sheet_subtitle") }
    static var chatOfflineDealSheetTitle: String { t("chat_offline_deal_sheet_title") }
    static var chatOfflineDealSubmit: String { t("chat_offline_deal_submit") }
    static var chatOrderCancelledByBuyer: String { t("chat_order_cancelled_by_buyer") }
    static var chatOrderCancelledBySystem: String { t("chat_order_cancelled_by_system") }
    static var chatOrderCancelledCardLabel: String { t("chat_order_cancelled_card_label") }
    static func chatOrderCancelledReason(_ a1: CVarArg) -> String {
        String(format: t("chat_order_cancelled_reason"), a1)
    }
    static var chatOrderCancelledViewOrder: String { t("chat_order_cancelled_view_order") }
    static var chatOrderStateBuyerCancelled: String { t("chat_order_state_buyer_cancelled") }
    static var chatOrderStateBuyerCashMeetupOpen: String { t("chat_order_state_buyer_cash_meetup_open") }
    static var chatOrderStateBuyerDeliveredConfirmed: String { t("chat_order_state_buyer_delivered_confirmed") }
    static var chatOrderStateBuyerDisputed: String { t("chat_order_state_buyer_disputed") }
    static var chatOrderStateBuyerFulfillmentPending: String { t("chat_order_state_buyer_fulfillment_pending") }
    static var chatOrderStateBuyerInTransit: String { t("chat_order_state_buyer_in_transit") }
    static var chatOrderStateBuyerPaymentHeld: String { t("chat_order_state_buyer_payment_held") }
    static var chatOrderStateBuyerPaymentPending: String { t("chat_order_state_buyer_payment_pending") }
    static func chatOrderStateBuyerUnknown(_ a1: CVarArg) -> String {
        String(format: t("chat_order_state_buyer_unknown"), a1)
    }
    static var chatOrderStateSellerCancelled: String { t("chat_order_state_seller_cancelled") }
    static var chatOrderStateSellerCashMeetupOpen: String { t("chat_order_state_seller_cash_meetup_open") }
    static var chatOrderStateSellerDeliveredConfirmed: String { t("chat_order_state_seller_delivered_confirmed") }
    static var chatOrderStateSellerDisputed: String { t("chat_order_state_seller_disputed") }
    static var chatOrderStateSellerFulfillmentPending: String { t("chat_order_state_seller_fulfillment_pending") }
    static var chatOrderStateSellerInTransit: String { t("chat_order_state_seller_in_transit") }
    static var chatOrderStateSellerPaymentHeld: String { t("chat_order_state_seller_payment_held") }
    static var chatOrderStateSellerPaymentPending: String { t("chat_order_state_seller_payment_pending") }
    static func chatOrderStateSellerUnknown(_ a1: CVarArg) -> String {
        String(format: t("chat_order_state_seller_unknown"), a1)
    }
    static var chatPendingOfferButtonWaiting: String { t("chat_pending_offer_button_waiting") }
    static var chatQuickRepliesLabel: String { t("chat_quick_replies_label") }
    static var chatQuickReplyAvailable: String { t("chat_quick_reply_available") }
    static var chatQuickReplyMeetup: String { t("chat_quick_reply_meetup") }
    static var chatQuickReplyPhotos: String { t("chat_quick_reply_photos") }
    static var chatReopenedSnackbar: String { t("chat_reopened_snackbar") }
    static var chatReportAlreadySubmittedCd: String { t("chat_report_already_submitted_cd") }
    static func chatReportBannerCategory(_ a1: CVarArg) -> String {
        String(format: t("chat_report_banner_category"), a1)
    }
    static func chatReportBannerSubmittedAt(_ a1: CVarArg) -> String {
        String(format: t("chat_report_banner_submitted_at"), a1)
    }
    static var chatReportBannerTitle: String { t("chat_report_banner_title") }
    static var chatReportCategoryHarassment: String { t("chat_report_category_harassment") }
    static var chatReportCategoryInappropriate: String { t("chat_report_category_inappropriate") }
    static var chatReportCategoryOther: String { t("chat_report_category_other") }
    static var chatReportCategoryScam: String { t("chat_report_category_scam") }
    static var chatReportCategorySpam: String { t("chat_report_category_spam") }
    static var chatReportDescriptionHint: String { t("chat_report_description_hint") }
    static var chatReportDescriptionLabel: String { t("chat_report_description_label") }
    static var chatReportDialogSubtitle: String { t("chat_report_dialog_subtitle") }
    static var chatReportDialogTitle: String { t("chat_report_dialog_title") }
    static var chatReportErrorDuplicate: String { t("chat_report_error_duplicate") }
    static var chatReportErrorForbidden: String { t("chat_report_error_forbidden") }
    static var chatReportErrorGeneral: String { t("chat_report_error_general") }
    static var chatReportErrorMissingUser: String { t("chat_report_error_missing_user") }
    static var chatReportErrorNotFound: String { t("chat_report_error_not_found") }
    static var chatReportMenuCd: String { t("chat_report_menu_cd") }
    static var chatReportMenuItem: String { t("chat_report_menu_item") }
    static var chatReportStatusDismissed: String { t("chat_report_status_dismissed") }
    static var chatReportStatusPending: String { t("chat_report_status_pending") }
    static var chatReportStatusSuspended: String { t("chat_report_status_suspended") }
    static func chatReportStatusUnknown(_ a1: CVarArg) -> String {
        String(format: t("chat_report_status_unknown"), a1)
    }
    static var chatReportStatusWarned: String { t("chat_report_status_warned") }
    static var chatReportSubmit: String { t("chat_report_submit") }
    static var chatReportSuccess: String { t("chat_report_success") }
    static var chatRetry: String { t("chat_retry") }
    static var chatSellerSuggestNewListing: String { t("chat_seller_suggest_new_listing") }
    static var chatSend: String { t("chat_send") }
    static var chatSendError: String { t("chat_send_error") }
    static func chatSendErrorGateway(_ a1: CVarArg) -> String {
        String(format: t("chat_send_error_gateway"), a1)
    }
    static var chatSetPrice: String { t("chat_set_price") }
    static var chatShipFlowAddAddress: String { t("chat_ship_flow_add_address") }
    static var chatShipFlowAddressMissingHint: String { t("chat_ship_flow_address_missing_hint") }
    static var chatShipFlowAddressSaved: String { t("chat_ship_flow_address_saved") }
    static func chatShipFlowAmountLine(_ a1: CVarArg) -> String {
        String(format: t("chat_ship_flow_amount_line"), a1)
    }
    static var chatShipFlowChooseSavedAddress: String { t("chat_ship_flow_choose_saved_address") }
    static var chatShipFlowContinueToPayment: String { t("chat_ship_flow_continue_to_payment") }
    static func chatShipFlowEstimatedShippingFee(_ a1: CVarArg) -> String {
        String(format: t("chat_ship_flow_estimated_shipping_fee"), a1)
    }
    static var chatShipFlowLoadingOrder: String { t("chat_ship_flow_loading_order") }
    static var chatShipFlowOrderFallbackTitle: String { t("chat_ship_flow_order_fallback_title") }
    static func chatShipFlowOrderIdLine(_ a1: CVarArg) -> String {
        String(format: t("chat_ship_flow_order_id_line"), a1)
    }
    static var chatShipFlowPayOnlineCta: String { t("chat_ship_flow_pay_online_cta") }
    static var chatShipFlowPaymentBuyerPaidOrProgress: String { t("chat_ship_flow_payment_buyer_paid_or_progress") }
    static var chatShipFlowPaymentBuyerPendingBody: String { t("chat_ship_flow_payment_buyer_pending_body") }
    static var chatShipFlowPaymentDisabledEnv: String { t("chat_ship_flow_payment_disabled_env") }
    static var chatShipFlowPaymentHeading: String { t("chat_ship_flow_payment_heading") }
    static var chatShipFlowPaymentSellerBody: String { t("chat_ship_flow_payment_seller_body") }
    static var chatShipFlowPaymentUnknownRole: String { t("chat_ship_flow_payment_unknown_role") }
    static var chatShipFlowSecureCheckoutNote: String { t("chat_ship_flow_secure_checkout_note") }
    static var chatShipFlowSellerAfterPaidHint: String { t("chat_ship_flow_seller_after_paid_hint") }
    static var chatShipFlowShippingBuyerBody: String { t("chat_ship_flow_shipping_buyer_body") }
    static var chatShipFlowShippingHeading: String { t("chat_ship_flow_shipping_heading") }
    static var chatShipFlowShippingSellerBody: String { t("chat_ship_flow_shipping_seller_body") }
    static var chatShipFlowShippingUnknownRole: String { t("chat_ship_flow_shipping_unknown_role") }
    static func chatShipFlowStatusLine(_ a1: CVarArg) -> String {
        String(format: t("chat_ship_flow_status_line"), a1)
    }
    static var chatShipFlowStepPayment: String { t("chat_ship_flow_step_payment") }
    static var chatShipFlowStepShipping: String { t("chat_ship_flow_step_shipping") }
    static var chatShipFlowTitle: String { t("chat_ship_flow_title") }
    static var chatShipFlowTitleBuyNow: String { t("chat_ship_flow_title_buy_now") }
    static func chatShipFlowTotalHint(_ a1: CVarArg) -> String {
        String(format: t("chat_ship_flow_total_hint"), a1)
    }
    static var chatTitle: String { t("chat_title") }
    static func chatUnreadMessagesCd(_ a1: CVarArg) -> String {
        String(format: t("chat_unread_messages_cd"), a1)
    }
    static var checkoutAddress: String { t("checkout_address") }
    static var checkoutAddressLabel: String { t("checkout_address_label") }
    static var checkoutAwaitingGateway: String { t("checkout_awaiting_gateway") }
    static var checkoutCity: String { t("checkout_city") }
    static var checkoutConfirmPay: String { t("checkout_confirm_pay") }
    static var checkoutDiscount: String { t("checkout_discount") }
    static var checkoutDistrict: String { t("checkout_district") }
    static var checkoutEditorialBadge: String { t("checkout_editorial_badge") }
    static var checkoutFullName: String { t("checkout_full_name") }
    static var checkoutLoadError: String { t("checkout_load_error") }
    static var checkoutMissingAddressHint: String { t("checkout_missing_address_hint") }
    static var checkoutOrderAlreadyPaid: String { t("checkout_order_already_paid") }
    static var checkoutOrderCancelled: String { t("checkout_order_cancelled") }
    static var checkoutOrderFulfillmentPending: String { t("checkout_order_fulfillment_pending") }
    static var checkoutOrderIdLabel: String { t("checkout_order_id_label") }
    static var checkoutOrderNotPayable: String { t("checkout_order_not_payable") }
    static var checkoutOrderOverview: String { t("checkout_order_overview") }
    static var checkoutOrderSummary: String { t("checkout_order_summary") }
    static var checkoutPaymentCancelledOrDispute: String { t("checkout_payment_cancelled_or_dispute") }
    static var checkoutPaymentError: String { t("checkout_payment_error") }
    static var checkoutPaymentInitFailed: String { t("checkout_payment_init_failed") }
    static var checkoutPaymentMethodLabel: String { t("checkout_payment_method_label") }
    static var checkoutPaymentMethodsLoadFailed: String { t("checkout_payment_methods_load_failed") }
    static var checkoutPaymentMethodsUnavailable: String { t("checkout_payment_methods_unavailable") }
    static var checkoutPaymentPollTimeout: String { t("checkout_payment_poll_timeout") }
    static var checkoutPhone: String { t("checkout_phone") }
    static var checkoutPlatformFee: String { t("checkout_platform_fee") }
    static var checkoutPlatformFeeEstimate: String { t("checkout_platform_fee_estimate") }
    static var checkoutPlatformFeeFromOrder: String { t("checkout_platform_fee_from_order") }
    static var checkoutPriceDeal: String { t("checkout_price_deal") }
    static var checkoutPriceListed: String { t("checkout_price_listed") }
    static var checkoutProcessingOverlay: String { t("checkout_processing_overlay") }
    static var checkoutProcessingSubtitle: String { t("checkout_processing_subtitle") }
    static var checkoutProductPrice: String { t("checkout_product_price") }
    static var checkoutSectionOrder: String { t("checkout_section_order") }
    static var checkoutSectionParties: String { t("checkout_section_parties") }
    static var checkoutSectionProduct: String { t("checkout_section_product") }
    static var checkoutSecuredFashPay: String { t("checkout_secured_fash_pay") }
    static var checkoutSecurityNote: String { t("checkout_security_note") }
    static var checkoutSellerReceives: String { t("checkout_seller_receives") }
    static var checkoutShippingFee: String { t("checkout_shipping_fee") }
    static var checkoutShippingReadonlySubtitle: String { t("checkout_shipping_readonly_subtitle") }
    static var checkoutSubtitle: String { t("checkout_subtitle") }
    static var checkoutSuccess: String { t("checkout_success") }
    static var checkoutTitle: String { t("checkout_title") }
    static var checkoutTotal: String { t("checkout_total") }
    static var checkoutTotalPayment: String { t("checkout_total_payment") }
    static var checkoutValueEscrow: String { t("checkout_value_escrow") }
    static var checkoutValueSupport: String { t("checkout_value_support") }
    static var checkoutValueTitle: String { t("checkout_value_title") }
    static var colorBeige: String { t("color_beige") }
    static var colorBlack: String { t("color_black") }
    static var colorBlue: String { t("color_blue") }
    static var colorBrown: String { t("color_brown") }
    static var colorCream: String { t("color_cream") }
    static var colorGray: String { t("color_gray") }
    static var colorGreen: String { t("color_green") }
    static var colorNavy: String { t("color_navy") }
    static var colorOlive: String { t("color_olive") }
    static var colorOrange: String { t("color_orange") }
    static var colorPink: String { t("color_pink") }
    static var colorPurple: String { t("color_purple") }
    static var colorRed: String { t("color_red") }
    static var colorWhite: String { t("color_white") }
    static var colorYellow: String { t("color_yellow") }
    static var comment: String { t("comment") }
    static var commonComingSoon: String { t("common_coming_soon") }
    static var conditionFair: String { t("condition_fair") }
    static var conditionGood: String { t("condition_good") }
    static var conditionLikeNew: String { t("condition_like_new") }
    static var conditionNew: String { t("condition_new") }
    static var createListingAddPhoto: String { t("create_listing_add_photo") }
    static var createListingAddPhotos: String { t("create_listing_add_photos") }
    static var createListingBrandLabel: String { t("create_listing_brand_label") }
    static var createListingCancel: String { t("create_listing_cancel") }
    static var createListingCategoryLabel: String { t("create_listing_category_label") }
    static var createListingCloseCd: String { t("create_listing_close_cd") }
    static var createListingConditionLabel: String { t("create_listing_condition_label") }
    static var createListingCoverLabel: String { t("create_listing_cover_label") }
    static var createListingDiscardCancel: String { t("create_listing_discard_cancel") }
    static var createListingDiscardConfirm: String { t("create_listing_discard_confirm") }
    static var createListingDiscardMessage: String { t("create_listing_discard_message") }
    static var createListingDiscardTitle: String { t("create_listing_discard_title") }
    static var createListingError: String { t("create_listing_error") }
    static var createListingImageError: String { t("create_listing_image_error") }
    static var createListingJustNow: String { t("create_listing_just_now") }
    static var createListingLegalMid: String { t("create_listing_legal_mid") }
    static var createListingLegalPrefix: String { t("create_listing_legal_prefix") }
    static var createListingLegalPrivacyLink: String { t("create_listing_legal_privacy_link") }
    static var createListingLegalSuffix: String { t("create_listing_legal_suffix") }
    static var createListingLegalTermsLink: String { t("create_listing_legal_terms_link") }
    static var createListingLocationDefault: String { t("create_listing_location_default") }
    static var createListingNext: String { t("create_listing_next") }
    static var createListingNoImages: String { t("create_listing_no_images") }
    static var createListingPhotoTip: String { t("create_listing_photo_tip") }
    static var createListingPostForSale: String { t("create_listing_post_for_sale") }
    static var createListingPriceLabel: String { t("create_listing_price_label") }
    static var createListingPricePlaceholder: String { t("create_listing_price_placeholder") }
    static var createListingReview: String { t("create_listing_review") }
    static var createListingSelect: String { t("create_listing_select") }
    static var createListingSelectCategory: String { t("create_listing_select_category") }
    static var createListingSellerJustActive: String { t("create_listing_seller_just_active") }
    static var createListingSizeLabel: String { t("create_listing_size_label") }
    static func createListingStep(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("create_listing_step"), a1, a2)
    }
    static var createListingStep2IncompleteHeader: String { t("create_listing_step2_incomplete_header") }
    static var createListingStep2NeedCategory: String { t("create_listing_step2_need_category") }
    static var createListingStep2NeedCondition: String { t("create_listing_step2_need_condition") }
    static var createListingStep2NeedPrice: String { t("create_listing_step2_need_price") }
    static var createListingStep2NeedTitle: String { t("create_listing_step2_need_title") }
    static var createListingStep3Subtitle: String { t("create_listing_step3_subtitle") }
    static var createListingStep3Title: String { t("create_listing_step3_title") }
    static var createListingStyleLabel: String { t("create_listing_style_label") }
    static var createListingSubmit: String { t("create_listing_submit") }
    static var createListingSuccess: String { t("create_listing_success") }
    static var createListingSuccessDialogMessage: String { t("create_listing_success_dialog_message") }
    static var createListingSuccessDialogTitle: String { t("create_listing_success_dialog_title") }
    static var createListingTipText: String { t("create_listing_tip_text") }
    static var createListingTipTitle: String { t("create_listing_tip_title") }
    static func createListingTitleDangTin(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("create_listing_title_dang_tin"), a1, a2)
    }
    static var createListingTitleLabel: String { t("create_listing_title_label") }
    static var createListingTitlePlaceholder: String { t("create_listing_title_placeholder") }
    static var createListingUploadError: String { t("create_listing_upload_error") }
    static func dealAgreedPriceBuyNow(_ a1: CVarArg) -> String {
        String(format: t("deal_agreed_price_buy_now"), a1)
    }
    static func dealAgreedPriceNegotiated(_ a1: CVarArg) -> String {
        String(format: t("deal_agreed_price_negotiated"), a1)
    }
    static var dialogOk: String { t("dialog_ok") }
    static var dialogTitleError: String { t("dialog_title_error") }
    static var dialogTitleInfo: String { t("dialog_title_info") }
    static var dialogTitleSuccess: String { t("dialog_title_success") }
    static var editListingBottomHint: String { t("edit_listing_bottom_hint") }
    static var editListingBrandDropdownEmpty: String { t("edit_listing_brand_dropdown_empty") }
    static var editListingBrandDropdownPlaceholder: String { t("edit_listing_brand_dropdown_placeholder") }
    static var editListingCategoryLocked: String { t("edit_listing_category_locked") }
    static var editListingClearCountry: String { t("edit_listing_clear_country") }
    static var editListingCountryDropdownEmpty: String { t("edit_listing_country_dropdown_empty") }
    static var editListingCountryDropdownPlaceholder: String { t("edit_listing_country_dropdown_placeholder") }
    static var editListingDelete: String { t("edit_listing_delete") }
    static var editListingDeleteBody: String { t("edit_listing_delete_body") }
    static var editListingDeleteConfirm: String { t("edit_listing_delete_confirm") }
    static var editListingDeleteError: String { t("edit_listing_delete_error") }
    static var editListingDeleteTitle: String { t("edit_listing_delete_title") }
    static var editListingDeleted: String { t("edit_listing_deleted") }
    static var editListingDescriptionLabel: String { t("edit_listing_description_label") }
    static var editListingLoadError: String { t("edit_listing_load_error") }
    static var editListingNoChanges: String { t("edit_listing_no_changes") }
    static var editListingNotEditable: String { t("edit_listing_not_editable") }
    static var editListingOffersSection: String { t("edit_listing_offers_section") }
    static var editListingOffersSectionHint: String { t("edit_listing_offers_section_hint") }
    static var editListingPhotosNote: String { t("edit_listing_photos_note") }
    static var editListingPhotosSection: String { t("edit_listing_photos_section") }
    static var editListingPriceInvalid: String { t("edit_listing_price_invalid") }
    static var editListingReadonlyInactive: String { t("edit_listing_readonly_inactive") }
    static var editListingReadonlyLocked: String { t("edit_listing_readonly_locked") }
    static var editListingReadonlySectionSubtitle: String { t("edit_listing_readonly_section_subtitle") }
    static var editListingReadonlySectionTitle: String { t("edit_listing_readonly_section_title") }
    static var editListingRejectedBanner: String { t("edit_listing_rejected_banner") }
    static var editListingRejectedBottomHint: String { t("edit_listing_rejected_bottom_hint") }
    static var editListingResubmitted: String { t("edit_listing_resubmitted") }
    static var editListingSave: String { t("edit_listing_save") }
    static var editListingSaveError: String { t("edit_listing_save_error") }
    static var editListingSaveResubmit: String { t("edit_listing_save_resubmit") }
    static var editListingSaved: String { t("edit_listing_saved") }
    static var editListingScreenTitle: String { t("edit_listing_screen_title") }
    static var editListingStyleTags: String { t("edit_listing_style_tags") }
    static var editListingTagsClearedNote: String { t("edit_listing_tags_cleared_note") }
    static func editListingTagsCountFmt(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("edit_listing_tags_count_fmt"), a1, a2)
    }
    static var editListingTagsDone: String { t("edit_listing_tags_done") }
    static var editListingTagsDropdownPlaceholder: String { t("edit_listing_tags_dropdown_placeholder") }
    static var editListingTagsHint: String { t("edit_listing_tags_hint") }
    static var editListingTitleInvalid: String { t("edit_listing_title_invalid") }
    static func editProfileBioCounter(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("edit_profile_bio_counter"), a1, a2)
    }
    static var editProfileBioLabel: String { t("edit_profile_bio_label") }
    static var editProfileBioPlaceholder: String { t("edit_profile_bio_placeholder") }
    static var editProfileChangePhotoCd: String { t("edit_profile_change_photo_cd") }
    static var editProfileCloseCd: String { t("edit_profile_close_cd") }
    static var editProfileCoverPlaceholder: String { t("edit_profile_cover_placeholder") }
    static func editProfileDisplayNameCounter(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("edit_profile_display_name_counter"), a1, a2)
    }
    static var editProfileDisplayNameLabel: String { t("edit_profile_display_name_label") }
    static var editProfileDisplayNamePlaceholder: String { t("edit_profile_display_name_placeholder") }
    static var editProfileGenderLabel: String { t("edit_profile_gender_label") }
    static var editProfilePhotosHint: String { t("edit_profile_photos_hint") }
    static var editProfileSave: String { t("edit_profile_save") }
    static var editProfileSaveChanges: String { t("edit_profile_save_changes") }
    static var editProfileSaveError: String { t("edit_profile_save_error") }
    static var editProfileSectionBasic: String { t("edit_profile_section_basic") }
    static var editProfileSectionGender: String { t("edit_profile_section_gender") }
    static var editProfileSectionSizing: String { t("edit_profile_section_sizing") }
    static var editProfileSectionStyle: String { t("edit_profile_section_style") }
    static var editProfileStyleClearAll: String { t("edit_profile_style_clear_all") }
    static var editProfileStyleDone: String { t("edit_profile_style_done") }
    static var editProfileStyleEditButton: String { t("edit_profile_style_edit_button") }
    static var editProfileStyleEmptyHint: String { t("edit_profile_style_empty_hint") }
    static var editProfileStyleLabel: String { t("edit_profile_style_label") }
    static var editProfileStyleSearchPlaceholder: String { t("edit_profile_style_search_placeholder") }
    static var editProfileStyleSectionSubtitle: String { t("edit_profile_style_section_subtitle") }
    static func editProfileStyleSelectedCount(_ a1: CVarArg) -> String {
        String(format: t("edit_profile_style_selected_count"), a1)
    }
    static var editProfileTitle: String { t("edit_profile_title") }
    static var editProfileUnitSt: String { t("edit_profile_unit_st") }
    static var editProfileUploadError: String { t("edit_profile_upload_error") }
    static var editProfileUsernameLabel: String { t("edit_profile_username_label") }
    static var editProfileUsernamePlaceholder: String { t("edit_profile_username_placeholder") }
    static var errorGeneric: String { t("error_generic") }
    static var errorHttpBadRequest: String { t("error_http_bad_request") }
    static var errorHttpConflict: String { t("error_http_conflict") }
    static var errorHttpForbidden: String { t("error_http_forbidden") }
    static var errorHttpNotFound: String { t("error_http_not_found") }
    static var errorHttpServer: String { t("error_http_server") }
    static func errorHttpStatus(_ a1: CVarArg) -> String {
        String(format: t("error_http_status"), a1)
    }
    static var errorHttpUnauthorized: String { t("error_http_unauthorized") }
    static var errorNetworkUnavailable: String { t("error_network_unavailable") }
    static var errorRateLimitGeneric: String { t("error_rate_limit_generic") }
    static var errorRateLimitOtp: String { t("error_rate_limit_otp") }
    static func errorRateLimitOtpWait(_ a1: CVarArg) -> String {
        String(format: t("error_rate_limit_otp_wait"), a1)
    }
    static func errorRateLimitWait(_ a1: CVarArg) -> String {
        String(format: t("error_rate_limit_wait"), a1)
    }
    static var exploreAll: String { t("explore_all") }
    static var exploreCategoryAll: String { t("explore_category_all") }
    static var exploreCategorySectionTitle: String { t("explore_category_section_title") }
    static var exploreEmptyClearAll: String { t("explore_empty_clear_all") }
    static var exploreEmptyEditFilters: String { t("explore_empty_edit_filters") }
    static var exploreEmptyFilteredTitle: String { t("explore_empty_filtered_title") }
    static func exploreFeaturedSellerCd(_ a1: CVarArg) -> String {
        String(format: t("explore_featured_seller_cd"), a1)
    }
    static var exploreFeaturedSellers: String { t("explore_featured_sellers") }
    static var exploreFeedSubtitle: String { t("explore_feed_subtitle") }
    static var exploreFilterAestheticClear: String { t("explore_filter_aesthetic_clear") }
    static var exploreFilterAestheticNone: String { t("explore_filter_aesthetic_none") }
    static var exploreFilterAestheticSearchPlaceholder: String { t("explore_filter_aesthetic_search_placeholder") }
    static func exploreFilterAestheticSelectedCount(_ a1: CVarArg) -> String {
        String(format: t("explore_filter_aesthetic_selected_count"), a1)
    }
    static func exploreFilterAestheticSummaryCd(_ a1: CVarArg) -> String {
        String(format: t("explore_filter_aesthetic_summary_cd"), a1)
    }
    static var exploreFilterBrandAny: String { t("explore_filter_brand_any") }
    static var exploreFilterBrandSearchPlaceholder: String { t("explore_filter_brand_search_placeholder") }
    static func exploreFilterBrandSummaryCd(_ a1: CVarArg) -> String {
        String(format: t("explore_filter_brand_summary_cd"), a1)
    }
    static var exploreFilterBrandTitle: String { t("explore_filter_brand_title") }
    static var exploreFilterCategorySearchPlaceholder: String { t("explore_filter_category_search_placeholder") }
    static func exploreFilterCategorySummaryCd(_ a1: CVarArg) -> String {
        String(format: t("explore_filter_category_summary_cd"), a1)
    }
    static var exploreFilterClearPrice: String { t("explore_filter_clear_price") }
    static var exploreFilterConditionAny: String { t("explore_filter_condition_any") }
    static var exploreFilterConditionTitle: String { t("explore_filter_condition_title") }
    static var exploreFilterCountryAny: String { t("explore_filter_country_any") }
    static var exploreFilterCountrySearchPlaceholder: String { t("explore_filter_country_search_placeholder") }
    static func exploreFilterCountrySummaryCd(_ a1: CVarArg) -> String {
        String(format: t("explore_filter_country_summary_cd"), a1)
    }
    static var exploreFilterCountryTitle: String { t("explore_filter_country_title") }
    static var exploreFilterGroupPersonalSubtitle: String { t("explore_filter_group_personal_subtitle") }
    static var exploreFilterGroupPriceSubtitle: String { t("explore_filter_group_price_subtitle") }
    static var exploreFilterGroupPriceTitle: String { t("explore_filter_group_price_title") }
    static var exploreFilterGroupProductSubtitle: String { t("explore_filter_group_product_subtitle") }
    static var exploreFilterGroupProductTitle: String { t("explore_filter_group_product_title") }
    static var exploreFilterHintArea: String { t("explore_filter_hint_area") }
    static var exploreFilterHintCategory: String { t("explore_filter_hint_category") }
    static var exploreFilterHintLabel: String { t("explore_filter_hint_label") }
    static var exploreFilterHintPrice: String { t("explore_filter_hint_price") }
    static var exploreFilterHintSizing: String { t("explore_filter_hint_sizing") }
    static var exploreFilterHintStyle: String { t("explore_filter_hint_style") }
    static var exploreFilterLoading: String { t("explore_filter_loading") }
    static var exploreFilterLocationAll: String { t("explore_filter_location_all") }
    static var exploreFilterLocationManual: String { t("explore_filter_location_manual") }
    static func exploreFilterLocationManualCd(_ a1: CVarArg) -> String {
        String(format: t("explore_filter_location_manual_cd"), a1)
    }
    static func exploreFilterLocationManualHint(_ a1: CVarArg) -> String {
        String(format: t("explore_filter_location_manual_hint"), a1)
    }
    static var exploreFilterLocationNearby: String { t("explore_filter_location_nearby") }
    static func exploreFilterLocationNearbyHint(_ a1: CVarArg) -> String {
        String(format: t("explore_filter_location_nearby_hint"), a1)
    }
    static var exploreFilterLocationTitle: String { t("explore_filter_location_title") }
    static var exploreFilterMaxHint: String { t("explore_filter_max_hint") }
    static var exploreFilterMinHint: String { t("explore_filter_min_hint") }
    static var exploreFilterPersonalTitle: String { t("explore_filter_personal_title") }
    static var exploreFilterPriceTitle: String { t("explore_filter_price_title") }
    static var exploreFilterSheetDone: String { t("explore_filter_sheet_done") }
    static var exploreFilterSheetJourneySubtitle: String { t("explore_filter_sheet_journey_subtitle") }
    static var exploreFilterSizingAll: String { t("explore_filter_sizing_all") }
    static var exploreFilterSizingMatchProfile: String { t("explore_filter_sizing_match_profile") }
    static var exploreFilterSizingTitle: String { t("explore_filter_sizing_title") }
    static var exploreFilterSortTitle: String { t("explore_filter_sort_title") }
    static var exploreFilterSummaryDefault: String { t("explore_filter_summary_default") }
    static var exploreFilterSummaryLocationActive: String { t("explore_filter_summary_location_active") }
    static func exploreFilterSummaryPriceMax(_ a1: CVarArg) -> String {
        String(format: t("explore_filter_summary_price_max"), a1)
    }
    static func exploreFilterSummaryPriceMin(_ a1: CVarArg) -> String {
        String(format: t("explore_filter_summary_price_min"), a1)
    }
    static func exploreFilterSummaryPriceRange(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("explore_filter_summary_price_range"), a1, a2)
    }
    static var exploreFilterSummarySizingMatch: String { t("explore_filter_summary_sizing_match") }
    static var exploreFilterTeaserArea: String { t("explore_filter_teaser_area") }
    static var exploreFilterTeaserBrand: String { t("explore_filter_teaser_brand") }
    static var exploreFilterTeaserCategory: String { t("explore_filter_teaser_category") }
    static var exploreFilterTeaserLineArea: String { t("explore_filter_teaser_line_area") }
    static var exploreFilterTeaserLineCategory: String { t("explore_filter_teaser_line_category") }
    static var exploreFilterTeaserLinePrice: String { t("explore_filter_teaser_line_price") }
    static var exploreFilterTeaserLineSizing: String { t("explore_filter_teaser_line_sizing") }
    static var exploreFilterTeaserLineStyle: String { t("explore_filter_teaser_line_style") }
    static var exploreFilterTeaserPrice: String { t("explore_filter_teaser_price") }
    static var exploreFilterTeaserSeparator: String { t("explore_filter_teaser_separator") }
    static var exploreFilterTeaserSizing: String { t("explore_filter_teaser_sizing") }
    static var exploreFilterTeaserStyle: String { t("explore_filter_teaser_style") }
    static var exploreFilterTeaserTap: String { t("explore_filter_teaser_tap") }
    static var exploreFiltersBarSubtitleActive: String { t("explore_filters_bar_subtitle_active") }
    static var exploreFiltersBarSubtitleIdle: String { t("explore_filters_bar_subtitle_idle") }
    static var exploreFiltersBarTitle: String { t("explore_filters_bar_title") }
    static var exploreFiltersClear: String { t("explore_filters_clear") }
    static var exploreFiltersClearCd: String { t("explore_filters_clear_cd") }
    static var exploreFiltersHide: String { t("explore_filters_hide") }
    static var exploreFiltersShow: String { t("explore_filters_show") }
    static var exploreFiltersToggleCd: String { t("explore_filters_toggle_cd") }
    static var exploreFollowers: String { t("explore_followers") }
    static var exploreGridEmptySubtitle: String { t("explore_grid_empty_subtitle") }
    static var exploreInterestChipsLabel: String { t("explore_interest_chips_label") }
    static var exploreLocationSetupAddAddress: String { t("explore_location_setup_add_address") }
    static var exploreLocationSetupBody: String { t("explore_location_setup_body") }
    static var exploreLocationSetupPickManual: String { t("explore_location_setup_pick_manual") }
    static var exploreLocationSetupSkip: String { t("explore_location_setup_skip") }
    static var exploreLocationSetupTitle: String { t("explore_location_setup_title") }
    static var explorePersonalFiltersEdit: String { t("explore_personal_filters_edit") }
    static var explorePreviewDetailNudge: String { t("explore_preview_detail_nudge") }
    static var explorePreviewDetailNudgeCta: String { t("explore_preview_detail_nudge_cta") }
    static var explorePreviewDetailNudgeSub: String { t("explore_preview_detail_nudge_sub") }
    static func explorePreviewImagePage(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("explore_preview_image_page"), a1, a2)
    }
    static func explorePreviewImagePagerCd(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("explore_preview_image_pager_cd"), a1, a2)
    }
    static var explorePreviewInlineSeparator: String { t("explore_preview_inline_separator") }
    static var explorePreviewLoading: String { t("explore_preview_loading") }
    static var explorePreviewMessageSeller: String { t("explore_preview_message_seller") }
    static var explorePreviewScrollHint: String { t("explore_preview_scroll_hint") }
    static var explorePreviewScrollHintCd: String { t("explore_preview_scroll_hint_cd") }
    static func explorePreviewSellerAtUsername(_ a1: CVarArg) -> String {
        String(format: t("explore_preview_seller_at_username"), a1)
    }
    static var explorePreviewSellerUsernameFallback: String { t("explore_preview_seller_username_fallback") }
    static var explorePreviewSheetSubtitle: String { t("explore_preview_sheet_subtitle") }
    static var explorePreviewSheetTitle: String { t("explore_preview_sheet_title") }
    static var explorePreviewTrustLine: String { t("explore_preview_trust_line") }
    static var explorePreviewViewDetail: String { t("explore_preview_view_detail") }
    static var explorePromoBadge: String { t("explore_promo_badge") }
    static func explorePromoPagerCd(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("explore_promo_pager_cd"), a1, a2)
    }
    static var explorePromoSlide1Subtitle: String { t("explore_promo_slide1_subtitle") }
    static var explorePromoSlide1Title: String { t("explore_promo_slide1_title") }
    static var explorePromoSlide2Subtitle: String { t("explore_promo_slide2_subtitle") }
    static var explorePromoSlide2Title: String { t("explore_promo_slide2_title") }
    static var explorePromoSlide3Subtitle: String { t("explore_promo_slide3_subtitle") }
    static var explorePromoSlide3Title: String { t("explore_promo_slide3_title") }
    static var exploreQuickLocationCd: String { t("explore_quick_location_cd") }
    static var exploreQuickLocationPickLink: String { t("explore_quick_location_pick_link") }
    static var exploreQuickLocationSetupHint: String { t("explore_quick_location_setup_hint") }
    static func exploreQuickLocationSubtitleManual(_ a1: CVarArg) -> String {
        String(format: t("explore_quick_location_subtitle_manual"), a1)
    }
    static func exploreQuickLocationSubtitleNearby(_ a1: CVarArg) -> String {
        String(format: t("explore_quick_location_subtitle_nearby"), a1)
    }
    static var exploreQuickLocationSubtitleOff: String { t("explore_quick_location_subtitle_off") }
    static var exploreQuickLocationTitle: String { t("explore_quick_location_title") }
    static var exploreQuickSizingCd: String { t("explore_quick_sizing_cd") }
    static var exploreQuickSizingEstimateBadge: String { t("explore_quick_sizing_estimate_badge") }
    static var exploreQuickSizingSetupHint: String { t("explore_quick_sizing_setup_hint") }
    static var exploreQuickSizingSubtitleOff: String { t("explore_quick_sizing_subtitle_off") }
    static var exploreQuickSizingSubtitleOn: String { t("explore_quick_sizing_subtitle_on") }
    static var exploreQuickSizingTitle: String { t("explore_quick_sizing_title") }
    static var exploreSearchActiveCd: String { t("explore_search_active_cd") }
    static var exploreSearchActiveLabel: String { t("explore_search_active_label") }
    static var exploreSearchBrowseAction: String { t("explore_search_browse_action") }
    static var exploreSearchBrowseSubtitle: String { t("explore_search_browse_subtitle") }
    static var exploreSearchBrowseTitle: String { t("explore_search_browse_title") }
    static var exploreSearchClearActive: String { t("explore_search_clear_active") }
    static var exploreSearchIdleEmpty: String { t("explore_search_idle_empty") }
    static var exploreSearchNoSuggestions: String { t("explore_search_no_suggestions") }
    static var exploreSearchPlaceholderSellers: String { t("explore_search_placeholder_sellers") }
    static var exploreSearchRecentTitle: String { t("explore_search_recent_title") }
    static func exploreSearchRowCd(_ a1: CVarArg) -> String {
        String(format: t("explore_search_row_cd"), a1)
    }
    static var exploreSearchSuggestionsTitle: String { t("explore_search_suggestions_title") }
    static var exploreSearchSuggestionsTitleListings: String { t("explore_search_suggestions_title_listings") }
    static var exploreSearchSuggestionsTitleSellers: String { t("explore_search_suggestions_title_sellers") }
    static func exploreSearchTagCd(_ a1: CVarArg) -> String {
        String(format: t("explore_search_tag_cd"), a1)
    }
    static var exploreSearchTrendingQueriesTitle: String { t("explore_search_trending_queries_title") }
    static var exploreSearchTrendingTagsTitle: String { t("explore_search_trending_tags_title") }
    static var exploreSectionListings: String { t("explore_section_listings") }
    static var exploreSectionSellers: String { t("explore_section_sellers") }
    static var exploreSeeAll: String { t("explore_see_all") }
    static var exploreSeeAllCd: String { t("explore_see_all_cd") }
    static var exploreSellerNoListingsSubtitle: String { t("explore_seller_no_listings_subtitle") }
    static var exploreSellerNoListingsTitle: String { t("explore_seller_no_listings_title") }
    static var exploreSellersEmpty: String { t("explore_sellers_empty") }
    static var exploreSellersSearchPlaceholder: String { t("explore_sellers_search_placeholder") }
    static var exploreSellersSubtitle: String { t("explore_sellers_subtitle") }
    static var exploreSizingSetupSheetBody: String { t("explore_sizing_setup_sheet_body") }
    static var exploreSizingSetupSheetCta: String { t("explore_sizing_setup_sheet_cta") }
    static var exploreSizingSetupSheetSkip: String { t("explore_sizing_setup_sheet_skip") }
    static var exploreSizingSetupSheetTitle: String { t("explore_sizing_setup_sheet_title") }
    static var exploreSortDisabledHint: String { t("explore_sort_disabled_hint") }
    static var exploreSortPopular: String { t("explore_sort_popular") }
    static var exploreSortPriceHigh: String { t("explore_sort_price_high") }
    static var exploreSortPriceLow: String { t("explore_sort_price_low") }
    static var exploreSortRecent: String { t("explore_sort_recent") }
    static var exploreStyleAny: String { t("explore_style_any") }
    static var exploreStyleChipsTitle: String { t("explore_style_chips_title") }
    static var exploreStyleSectionTitle: String { t("explore_style_section_title") }
    static var exploreTitle: String { t("explore_title") }
    static var featuredSellersAllSubtitle: String { t("featured_sellers_all_subtitle") }
    static var featuredSellersAllTitle: String { t("featured_sellers_all_title") }
    static var featuredSellersNoBio: String { t("featured_sellers_no_bio") }
    static var featuredSellersPreviewHeading: String { t("featured_sellers_preview_heading") }
    static func featuredSellersPreviewListingCd(_ a1: CVarArg) -> String {
        String(format: t("featured_sellers_preview_listing_cd"), a1)
    }
    static func featuredSellersRatingValue(_ a1: CVarArg) -> String {
        String(format: t("featured_sellers_rating_value"), a1)
    }
    static func featuredSellersStatFollowers(_ a1: CVarArg) -> String {
        String(format: t("featured_sellers_stat_followers"), a1)
    }
    static var featuredSellersVerifiedCd: String { t("featured_sellers_verified_cd") }
    static var feedActionError: String { t("feed_action_error") }
    static var feedEmptySubtitle: String { t("feed_empty_subtitle") }
    static var feedEmptyTitle: String { t("feed_empty_title") }
    static var feedLoadError: String { t("feed_load_error") }
    static var feedLoadingMore: String { t("feed_loading_more") }
    static var feedRetry: String { t("feed_retry") }
    static var followButton: String { t("follow_button") }
    static var followConnectionsTitle: String { t("follow_connections_title") }
    static var followFollowing: String { t("follow_following") }
    static var followListEmptyFollowersSubtitle: String { t("follow_list_empty_followers_subtitle") }
    static var followListEmptyFollowersTip1: String { t("follow_list_empty_followers_tip_1") }
    static var followListEmptyFollowersTip2: String { t("follow_list_empty_followers_tip_2") }
    static var followListEmptyFollowersTitle: String { t("follow_list_empty_followers_title") }
    static var followListEmptyFollowingSubtitle: String { t("follow_list_empty_following_subtitle") }
    static var followListEmptyFollowingTip1: String { t("follow_list_empty_following_tip_1") }
    static var followListEmptyFollowingTip2: String { t("follow_list_empty_following_tip_2") }
    static var followListEmptyFollowingTitle: String { t("follow_list_empty_following_title") }
    static var followSuccess: String { t("follow_success") }
    static var followingButton: String { t("following_button") }
    static var genderMen: String { t("gender_men") }
    static var genderNonBinary: String { t("gender_non_binary") }
    static var genderPreferNotToSay: String { t("gender_prefer_not_to_say") }
    static var genderTargetKids: String { t("gender_target_kids") }
    static var genderTargetMen: String { t("gender_target_men") }
    static var genderTargetUnisex: String { t("gender_target_unisex") }
    static var genderTargetWomen: String { t("gender_target_women") }
    static var genderWomen: String { t("gender_women") }
    static var guestLoginReasonBrowseLocation: String { t("guest_login_reason_browse_location") }
    static var guestLoginReasonBuy: String { t("guest_login_reason_buy") }
    static var guestLoginReasonChat: String { t("guest_login_reason_chat") }
    static var guestLoginReasonFollow: String { t("guest_login_reason_follow") }
    static var guestLoginReasonHomeFollowing: String { t("guest_login_reason_home_following") }
    static var guestLoginReasonHomeForYou: String { t("guest_login_reason_home_for_you") }
    static var guestLoginReasonHomeSimilar: String { t("guest_login_reason_home_similar") }
    static var guestLoginReasonHomeStyle: String { t("guest_login_reason_home_style") }
    static var guestLoginReasonInvite: String { t("guest_login_reason_invite") }
    static var guestLoginReasonLike: String { t("guest_login_reason_like") }
    static var guestLoginReasonNotifications: String { t("guest_login_reason_notifications") }
    static var guestLoginReasonOrders: String { t("guest_login_reason_orders") }
    static var guestLoginReasonPost: String { t("guest_login_reason_post") }
    static var guestLoginReasonProfile: String { t("guest_login_reason_profile") }
    static var guestLoginReasonSaved: String { t("guest_login_reason_saved") }
    static var guestLoginReasonSizingMatch: String { t("guest_login_reason_sizing_match") }
    static var guestLoginReasonTopbar: String { t("guest_login_reason_topbar") }
    static var guestLoginSheetContinueBrowsing: String { t("guest_login_sheet_continue_browsing") }
    static var guestLoginSheetPrivacyNote: String { t("guest_login_sheet_privacy_note") }
    static var guestLoginSheetSignIn: String { t("guest_login_sheet_sign_in") }
    static var guestLoginSheetTitle: String { t("guest_login_sheet_title") }
    static var guestTabChatBody: String { t("guest_tab_chat_body") }
    static var guestTabChatTitle: String { t("guest_tab_chat_title") }
    static var guestTabOrdersBody: String { t("guest_tab_orders_body") }
    static var guestTabOrdersTitle: String { t("guest_tab_orders_title") }
    static var guestTabPostBody: String { t("guest_tab_post_body") }
    static var guestTabPostTitle: String { t("guest_tab_post_title") }
    static var guestTabProfileBody: String { t("guest_tab_profile_body") }
    static var guestTabProfileTitle: String { t("guest_tab_profile_title") }
    static var guestTopbarSignIn: String { t("guest_topbar_sign_in") }
    static var guestTopbarSignInCd: String { t("guest_topbar_sign_in_cd") }
    static var homeBrandFooterSub: String { t("home_brand_footer_sub") }
    static var homeBrandMarketplace: String { t("home_brand_marketplace") }
    static var homeDeliveringComingSoonBody: String { t("home_delivering_coming_soon_body") }
    static var homeDeliveringComingSoonTitle: String { t("home_delivering_coming_soon_title") }
    static var homeDeliveringListIntro: String { t("home_delivering_list_intro") }
    static var homeDeliveringScreenTitle: String { t("home_delivering_screen_title") }
    static var homeEditedByFashBadge: String { t("home_edited_by_fash_badge") }
    static var homeEditorialListSubtitle: String { t("home_editorial_list_subtitle") }
    static var homeEditorialListTitle: String { t("home_editorial_list_title") }
    static var homeEditorialPostExcerptOfficeChic: String { t("home_editorial_post_excerpt_office_chic") }
    static var homeEditorialPostExcerptSecondhandSmart: String { t("home_editorial_post_excerpt_secondhand_smart") }
    static var homeEditorialPostExcerptSneaker: String { t("home_editorial_post_excerpt_sneaker") }
    static var homeEditorialPostExcerptStreetVn: String { t("home_editorial_post_excerpt_street_vn") }
    static var homeEditorialPostExcerptWeekend: String { t("home_editorial_post_excerpt_weekend") }
    static func homeEditorialPostOpenCd(_ a1: CVarArg) -> String {
        String(format: t("home_editorial_post_open_cd"), a1)
    }
    static var homeEditorialPostTitleOfficeChic: String { t("home_editorial_post_title_office_chic") }
    static var homeEditorialPostTitleSecondhandSmart: String { t("home_editorial_post_title_secondhand_smart") }
    static var homeEditorialPostTitleSneaker: String { t("home_editorial_post_title_sneaker") }
    static var homeEditorialPostTitleStreetVn: String { t("home_editorial_post_title_street_vn") }
    static var homeEditorialPostTitleWeekend: String { t("home_editorial_post_title_weekend") }
    static var homeEditorialReadMore: String { t("home_editorial_read_more") }
    static var homeEditorialViewDetail: String { t("home_editorial_view_detail") }
    static var homeEmptyCtaExplore: String { t("home_empty_cta_explore") }
    static var homeExploreShortcutAction: String { t("home_explore_shortcut_action") }
    static var homeExploreShortcutCategory: String { t("home_explore_shortcut_category") }
    static var homeExploreShortcutStyle: String { t("home_explore_shortcut_style") }
    static var homeFeedEmptyCtaFeatured: String { t("home_feed_empty_cta_featured") }
    static var homeFeedEmptySubtitle: String { t("home_feed_empty_subtitle") }
    static var homeFeedEmptyTitle: String { t("home_feed_empty_title") }
    static var homeFeedSubtitle: String { t("home_feed_subtitle") }
    static var homeFeedTitle: String { t("home_feed_title") }
    static var homeFollowEmptyCtaFeatured: String { t("home_follow_empty_cta_featured") }
    static var homeFollowEmptyHint: String { t("home_follow_empty_hint") }
    static var homeGuestFollowHint: String { t("home_guest_follow_hint") }
    static var homeGuestTabFollowingBody: String { t("home_guest_tab_following_body") }
    static var homeGuestTabFollowingTitle: String { t("home_guest_tab_following_title") }
    static var homeGuestTabForYouBody: String { t("home_guest_tab_for_you_body") }
    static var homeGuestTabForYouTitle: String { t("home_guest_tab_for_you_title") }
    static var homeGuestTabSignIn: String { t("home_guest_tab_sign_in") }
    static var homeGuestTabSignInCd: String { t("home_guest_tab_sign_in_cd") }
    static var homeGuestTabSimilarBody: String { t("home_guest_tab_similar_body") }
    static var homeGuestTabSimilarTitle: String { t("home_guest_tab_similar_title") }
    static var homeGuestTabStyleBody: String { t("home_guest_tab_style_body") }
    static var homeGuestTabStyleTitle: String { t("home_guest_tab_style_title") }
    static var homeHeaderSearchPlaceholder: String { t("home_header_search_placeholder") }
    static var homeHeroCta: String { t("home_hero_cta") }
    static var homeHeroSubtitle: String { t("home_hero_subtitle") }
    static var homeHeroTitle: String { t("home_hero_title") }
    static var homeHuntTodaySeeAll: String { t("home_hunt_today_see_all") }
    static var homeHuntTodaySubtitle: String { t("home_hunt_today_subtitle") }
    static var homeHuntTodayTitle: String { t("home_hunt_today_title") }
    static var homeInReviewCtaPost: String { t("home_in_review_cta_post") }
    static var homeInReviewEmptySubtitle: String { t("home_in_review_empty_subtitle") }
    static var homeInReviewEmptyTitle: String { t("home_in_review_empty_title") }
    static var homeInReviewErrorSubtitle: String { t("home_in_review_error_subtitle") }
    static var homeInReviewErrorTitle: String { t("home_in_review_error_title") }
    static var homeInReviewListIntro: String { t("home_in_review_list_intro") }
    static var homeInReviewScreenTitle: String { t("home_in_review_screen_title") }
    static var homeJourneyDelivering: String { t("home_journey_delivering") }
    static var homeJourneyInReview: String { t("home_journey_in_review") }
    static var homeJourneySaved: String { t("home_journey_saved") }
    static var homeJourneyTitle: String { t("home_journey_title") }
    static var homeLogout: String { t("home_logout") }
    static var homeLogoutAll: String { t("home_logout_all") }
    static var homeQuickActionsTitle: String { t("home_quick_actions_title") }
    static var homeQuickExplore: String { t("home_quick_explore") }
    static var homeQuickOrders: String { t("home_quick_orders") }
    static var homeQuickSell: String { t("home_quick_sell") }
    static var homeSectionEditorialSubtitle: String { t("home_section_editorial_subtitle") }
    static var homeSectionEditorialTitle: String { t("home_section_editorial_title") }
    static var homeSectionForYouSubtitle: String { t("home_section_for_you_subtitle") }
    static var homeSectionForYouTitle: String { t("home_section_for_you_title") }
    static var homeSectionRecentlyViewedSubtitle: String { t("home_section_recently_viewed_subtitle") }
    static var homeSectionRecentlyViewedTitle: String { t("home_section_recently_viewed_title") }
    static var homeSectionRecommendedSellersSubtitle: String { t("home_section_recommended_sellers_subtitle") }
    static var homeSectionRecommendedSellersTitle: String { t("home_section_recommended_sellers_title") }
    static var homeSectionSimilarToSavedSubtitle: String { t("home_section_similar_to_saved_subtitle") }
    static var homeSectionSimilarToSavedTitle: String { t("home_section_similar_to_saved_title") }
    static var homeSectionTrendingStylesSubtitle: String { t("home_section_trending_styles_subtitle") }
    static var homeSectionTrendingStylesTitle: String { t("home_section_trending_styles_title") }
    static var homeSectionTrendingSubtitle: String { t("home_section_trending_subtitle") }
    static var homeSectionTrendingTitle: String { t("home_section_trending_title") }
    static var homeSettings: String { t("home_settings") }
    static var homeSizingBannerBody: String { t("home_sizing_banner_body") }
    static var homeSizingBannerCta: String { t("home_sizing_banner_cta") }
    static var homeSizingBannerDismissCd: String { t("home_sizing_banner_dismiss_cd") }
    static var homeSizingBannerTitle: String { t("home_sizing_banner_title") }
    static var homeStylePicksSubtitle: String { t("home_style_picks_subtitle") }
    static var homeStylePicksTitle: String { t("home_style_picks_title") }
    static var homeTabEmptyFollowingSubtitle: String { t("home_tab_empty_following_subtitle") }
    static var homeTabEmptyFollowingTitle: String { t("home_tab_empty_following_title") }
    static var homeTabEmptyForYouSubtitle: String { t("home_tab_empty_for_you_subtitle") }
    static var homeTabEmptyForYouTitle: String { t("home_tab_empty_for_you_title") }
    static var homeTabEmptyHuntSubtitle: String { t("home_tab_empty_hunt_subtitle") }
    static var homeTabEmptyHuntTitle: String { t("home_tab_empty_hunt_title") }
    static var homeTabEmptySimilarSubtitle: String { t("home_tab_empty_similar_subtitle") }
    static var homeTabEmptySimilarTitle: String { t("home_tab_empty_similar_title") }
    static var homeTabEmptyStyleSubtitle: String { t("home_tab_empty_style_subtitle") }
    static var homeTabEmptyStyleTitle: String { t("home_tab_empty_style_title") }
    static var homeTopSectionSubtitle: String { t("home_top_section_subtitle") }
    static var homeTopSectionTitle: String { t("home_top_section_title") }
    static func homeTrendingCategoryCd(_ a1: CVarArg) -> String {
        String(format: t("home_trending_category_cd"), a1)
    }
    static var homeWelcome: String { t("home_welcome") }
    static var inviteBenefitCircleBody: String { t("invite_benefit_circle_body") }
    static var inviteBenefitCircleTitle: String { t("invite_benefit_circle_title") }
    static var inviteBenefitPriorityBody: String { t("invite_benefit_priority_body") }
    static var inviteBenefitPriorityTitle: String { t("invite_benefit_priority_title") }
    static var inviteBenefitPromosBody: String { t("invite_benefit_promos_body") }
    static var inviteBenefitPromosTitle: String { t("invite_benefit_promos_title") }
    static var inviteBenefitsSectionTitle: String { t("invite_benefits_section_title") }
    static var inviteCopied: String { t("invite_copied") }
    static var inviteCopyClipboardLabel: String { t("invite_copy_clipboard_label") }
    static var inviteCtaCopy: String { t("invite_cta_copy") }
    static var inviteCtaShare: String { t("invite_cta_share") }
    static var inviteFinePrint: String { t("invite_fine_print") }
    static var inviteScreenHeroBody: String { t("invite_screen_hero_body") }
    static var inviteScreenHeroKicker: String { t("invite_screen_hero_kicker") }
    static var inviteScreenHeroTitle: String { t("invite_screen_hero_title") }
    static var inviteScreenTitle: String { t("invite_screen_title") }
    static func inviteShareBodyFormat(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("invite_share_body_format"), a1, a2)
    }
    static var inviteShareChooserTitle: String { t("invite_share_chooser_title") }
    static var inviteShareSubject: String { t("invite_share_subject") }
    static var languageEnglish: String { t("language_english") }
    static var languageVietnamese: String { t("language_vietnamese") }
    static var like: String { t("like") }
    static var listingBadgeJustListed: String { t("listing_badge_just_listed") }
    static func listingBadgeSavedCount(_ a1: CVarArg) -> String {
        String(format: t("listing_badge_saved_count"), a1)
    }
    static var listingCardA11ySellerRole: String { t("listing_card_a11y_seller_role") }
    static func listingCardPhotoStackA11y(_ a1: CVarArg) -> String {
        String(format: t("listing_card_photo_stack_a11y"), a1)
    }
    static var listingCommitmentBadge: String { t("listing_commitment_badge") }
    static var listingCommitmentBody: String { t("listing_commitment_body") }
    static var listingCommitmentTitle: String { t("listing_commitment_title") }
    static var listingLikeAddedSnackbar: String { t("listing_like_added_snackbar") }
    static var listingLikeRemovedSnackbar: String { t("listing_like_removed_snackbar") }
    static var listingSaveAddedSnackbar: String { t("listing_save_added_snackbar") }
    static var listingSaveRemovedSnackbar: String { t("listing_save_removed_snackbar") }
    static var listingStatusActive: String { t("listing_status_active") }
    static var listingStatusDeleted: String { t("listing_status_deleted") }
    static var listingStatusInReview: String { t("listing_status_in_review") }
    static var listingStatusInactive: String { t("listing_status_inactive") }
    static var listingStatusRejected: String { t("listing_status_rejected") }
    static var listingStatusReserved: String { t("listing_status_reserved") }
    static var listingStatusSold: String { t("listing_status_sold") }
    static var loginContinueWithoutAccount: String { t("login_continue_without_account") }
    static var loginEmailIconCd: String { t("login_email_icon_cd") }
    static var loginEmailInvalid: String { t("login_email_invalid") }
    static var loginEmailLabel: String { t("login_email_label") }
    static var loginEmailPlaceholder: String { t("login_email_placeholder") }
    static var loginFacebook: String { t("login_facebook") }
    static var loginFacebookError: String { t("login_facebook_error") }
    static var loginFacebookNotConfigured: String { t("login_facebook_not_configured") }
    static var loginFacebookSuccess: String { t("login_facebook_success") }
    static var loginGoogle: String { t("login_google") }
    static var loginGoogleDeveloperError: String { t("login_google_developer_error") }
    static var loginGoogleError: String { t("login_google_error") }
    static func loginGoogleErrorCode(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("login_google_error_code"), a1, a2)
    }
    static var loginGoogleNetworkError: String { t("login_google_network_error") }
    static var loginGoogleNotConfigured: String { t("login_google_not_configured") }
    static var loginGooglePlayServicesError: String { t("login_google_play_services_error") }
    static func loginGooglePlayServicesErrorDetail(_ a1: CVarArg) -> String {
        String(format: t("login_google_play_services_error_detail"), a1)
    }
    static var loginGoogleSuccess: String { t("login_google_success") }
    static var loginHeroCd: String { t("login_hero_cd") }
    static func loginHeroPagerCd(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("login_hero_pager_cd"), a1, a2)
    }
    static var loginHeroSlide1Caption: String { t("login_hero_slide1_caption") }
    static var loginHeroSlide2Caption: String { t("login_hero_slide2_caption") }
    static var loginHeroSlide3Caption: String { t("login_hero_slide3_caption") }
    static var loginLegalAnd: String { t("login_legal_and") }
    static var loginLegalPrefix: String { t("login_legal_prefix") }
    static var loginOrContinue: String { t("login_or_continue") }
    static var loginOtpFailed: String { t("login_otp_failed") }
    static var loginOtpResent: String { t("login_otp_resent") }
    static var loginOtpSent: String { t("login_otp_sent") }
    static var loginPasswordFailed: String { t("login_password_failed") }
    static var loginPasswordHideCd: String { t("login_password_hide_cd") }
    static var loginPasswordInvalid: String { t("login_password_invalid") }
    static var loginPasswordLabel: String { t("login_password_label") }
    static var loginPasswordPlaceholder: String { t("login_password_placeholder") }
    static var loginPasswordShowCd: String { t("login_password_show_cd") }
    static var loginPrivacy: String { t("login_privacy") }
    static var loginSendOtp: String { t("login_send_otp") }
    static var loginSendOtpCd: String { t("login_send_otp_cd") }
    static var loginSocialSigningIn: String { t("login_social_signing_in") }
    static var loginSubmit: String { t("login_submit") }
    static var loginTagline: String { t("login_tagline") }
    static var loginTerms: String { t("login_terms") }
    static var loginUseOtpInstead: String { t("login_use_otp_instead") }
    static var loginWithPassword: String { t("login_with_password") }
    static var logoutFailed: String { t("logout_failed") }
    static var logoutSuccess: String { t("logout_success") }
    static var meetingCheckInRequiresOnMyWay: String { t("meeting_check_in_requires_on_my_way") }
    static var meetingIdentityReverifyAckDone: String { t("meeting_identity_reverify_ack_done") }
    static var meetingIdentityReverifyAckError: String { t("meeting_identity_reverify_ack_error") }
    static var meetingIdentityReverifyAckOk: String { t("meeting_identity_reverify_ack_ok") }
    static var meetingIdentityReverifyClose: String { t("meeting_identity_reverify_close") }
    static var meetingIdentityReverifyDialogBody: String { t("meeting_identity_reverify_dialog_body") }
    static var meetingIdentityReverifyDialogTitle: String { t("meeting_identity_reverify_dialog_title") }
    static var meetingIdentityReverifyOpenLink: String { t("meeting_identity_reverify_open_link") }
    static var meetingOnMyWay: String { t("meeting_on_my_way") }
    static var meetingOnMyWayOk: String { t("meeting_on_my_way_ok") }
    static var meetingOtherOnMyWay: String { t("meeting_other_on_my_way") }
    static var meetingSelfOnMyWay: String { t("meeting_self_on_my_way") }
    static var navChat: String { t("nav_chat") }
    static var navExplore: String { t("nav_explore") }
    static var navHome: String { t("nav_home") }
    static var navInbox: String { t("nav_inbox") }
    static var navOrders: String { t("nav_orders") }
    static var navPost: String { t("nav_post") }
    static var navPostFabCd: String { t("nav_post_fab_cd") }
    static var navPostFabLabel: String { t("nav_post_fab_label") }
    static var navProfile: String { t("nav_profile") }
    static var noImage: String { t("no_image") }
    static var notificationActionOpenChat: String { t("notification_action_open_chat") }
    static var notificationActionOpenExplore: String { t("notification_action_open_explore") }
    static var notificationActionOpenFollowers: String { t("notification_action_open_followers") }
    static var notificationActionOpenFollowing: String { t("notification_action_open_following") }
    static var notificationActionOpenInviteFriends: String { t("notification_action_open_invite_friends") }
    static var notificationActionOpenListing: String { t("notification_action_open_listing") }
    static var notificationActionOpenOrder: String { t("notification_action_open_order") }
    static var notificationChannelChatDesc: String { t("notification_channel_chat_desc") }
    static var notificationChannelChatName: String { t("notification_channel_chat_name") }
    static var notificationChannelGeneralDesc: String { t("notification_channel_general_desc") }
    static var notificationChannelGeneralName: String { t("notification_channel_general_name") }
    static var notificationChannelOrdersDesc: String { t("notification_channel_orders_desc") }
    static var notificationChannelOrdersName: String { t("notification_channel_orders_name") }
    static var notificationChannelRecommendationDesc: String { t("notification_channel_recommendation_desc") }
    static var notificationChannelRecommendationName: String { t("notification_channel_recommendation_name") }
    static var notificationDataHideRaw: String { t("notification_data_hide_raw") }
    static var notificationDataLabelBuyer: String { t("notification_data_label_buyer") }
    static var notificationDataLabelChatMessage: String { t("notification_data_label_chat_message") }
    static var notificationDataLabelConversation: String { t("notification_data_label_conversation") }
    static var notificationDataLabelEvent: String { t("notification_data_label_event") }
    static var notificationDataLabelFollowee: String { t("notification_data_label_followee") }
    static var notificationDataLabelFollower: String { t("notification_data_label_follower") }
    static var notificationDataLabelFollowerBatchNames: String { t("notification_data_label_follower_batch_names") }
    static var notificationDataLabelListing: String { t("notification_data_label_listing") }
    static var notificationDataLabelNav: String { t("notification_data_label_nav") }
    static var notificationDataLabelOrder: String { t("notification_data_label_order") }
    static func notificationDataLabelOther(_ a1: CVarArg) -> String {
        String(format: t("notification_data_label_other"), a1)
    }
    static var notificationDataLabelRatingStars: String { t("notification_data_label_rating_stars") }
    static var notificationDataLabelReviewer: String { t("notification_data_label_reviewer") }
    static var notificationDataLabelScreen: String { t("notification_data_label_screen") }
    static var notificationDataLabelSeller: String { t("notification_data_label_seller") }
    static var notificationDataLabelTracking: String { t("notification_data_label_tracking") }
    static var notificationDataNavChat: String { t("notification_data_nav_chat") }
    static var notificationDataNavExploreTab: String { t("notification_data_nav_explore_tab") }
    static var notificationDataNavFollowersTab: String { t("notification_data_nav_followers_tab") }
    static var notificationDataNavFollowingTab: String { t("notification_data_nav_following_tab") }
    static func notificationDataNavGeneric(_ a1: CVarArg) -> String {
        String(format: t("notification_data_nav_generic"), a1)
    }
    static var notificationDataNavListing: String { t("notification_data_nav_listing") }
    static var notificationDataNavOrder: String { t("notification_data_nav_order") }
    static var notificationDataRawOnlyHint: String { t("notification_data_raw_only_hint") }
    static var notificationDataShowRaw: String { t("notification_data_show_raw") }
    static func notificationDataTitleWithId(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("notification_data_title_with_id"), a1, a2)
    }
    static var notificationDetailActionsHeading: String { t("notification_detail_actions_heading") }
    static var notificationDetailMoreLabel: String { t("notification_detail_more_label") }
    static var notificationDetailNoTitle: String { t("notification_detail_no_title") }
    static var notificationDetailPayloadTitle: String { t("notification_detail_payload_title") }
    static var notificationDetailPayloadType: String { t("notification_detail_payload_type") }
    static func notificationDetailPromoGalleryCd(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("notification_detail_promo_gallery_cd"), a1, a2)
    }
    static func notificationDetailReadAt(_ a1: CVarArg) -> String {
        String(format: t("notification_detail_read_at"), a1)
    }
    static var notificationDetailSource: String { t("notification_detail_source") }
    static var notificationDetailSourceEvent: String { t("notification_detail_source_event") }
    static func notificationDetailTime(_ a1: CVarArg) -> String {
        String(format: t("notification_detail_time"), a1)
    }
    static var notificationDetailTitle: String { t("notification_detail_title") }
    static var notificationEmptyHintsTitle: String { t("notification_empty_hints_title") }
    static var notificationEmptySubtitle: String { t("notification_empty_subtitle") }
    static var notificationEmptyTip1: String { t("notification_empty_tip_1") }
    static var notificationEmptyTip2: String { t("notification_empty_tip_2") }
    static var notificationEmptyTip3: String { t("notification_empty_tip_3") }
    static var notificationEmptyTitle: String { t("notification_empty_title") }
    static var notificationGroupAds: String { t("notification_group_ads") }
    static var notificationGroupAdsDesc: String { t("notification_group_ads_desc") }
    static var notificationGroupCommerce: String { t("notification_group_commerce") }
    static var notificationGroupCommerceDesc: String { t("notification_group_commerce_desc") }
    static var notificationGroupEmptyTitle: String { t("notification_group_empty_title") }
    static var notificationGroupRealtime: String { t("notification_group_realtime") }
    static var notificationGroupRealtimeDesc: String { t("notification_group_realtime_desc") }
    static var notificationGroupRecommendation: String { t("notification_group_recommendation") }
    static var notificationGroupRecommendationDesc: String { t("notification_group_recommendation_desc") }
    static var notificationGroupReengagement: String { t("notification_group_reengagement") }
    static var notificationGroupReengagementDesc: String { t("notification_group_reengagement_desc") }
    static var notificationGroupSocial: String { t("notification_group_social") }
    static var notificationGroupSocialDesc: String { t("notification_group_social_desc") }
    static var notificationGroupSystem: String { t("notification_group_system") }
    static var notificationGroupSystemDesc: String { t("notification_group_system_desc") }
    static var notificationInboxUnavailableSubtitle: String { t("notification_inbox_unavailable_subtitle") }
    static var notificationInboxUnavailableTitle: String { t("notification_inbox_unavailable_title") }
    static var notificationLoadErrorSubtitle: String { t("notification_load_error_subtitle") }
    static var notificationLoadErrorTitle: String { t("notification_load_error_title") }
    static var notificationMarkAllRead: String { t("notification_mark_all_read") }
    static var notificationMarkAllReadCd: String { t("notification_mark_all_read_cd") }
    static var notificationMarkAllReadError: String { t("notification_mark_all_read_error") }
    static var notificationMarkAllReadNone: String { t("notification_mark_all_read_none") }
    static func notificationMarkAllReadSuccess(_ a1: CVarArg) -> String {
        String(format: t("notification_mark_all_read_success"), a1)
    }
    static var notificationNewArrivalSnackbar: String { t("notification_new_arrival_snackbar") }
    static var notificationNewArrivalSnackbarAction: String { t("notification_new_arrival_snackbar_action") }
    static var notificationPreferencesLoadError: String { t("notification_preferences_load_error") }
    static var notificationPreferencesQuietHours: String { t("notification_preferences_quiet_hours") }
    static var notificationPreferencesQuietHoursEnabled: String { t("notification_preferences_quiet_hours_enabled") }
    static var notificationPreferencesQuietHoursEnd: String { t("notification_preferences_quiet_hours_end") }
    static var notificationPreferencesQuietHoursHint: String { t("notification_preferences_quiet_hours_hint") }
    static var notificationPreferencesQuietHoursStart: String { t("notification_preferences_quiet_hours_start") }
    static var notificationPreferencesRecommendationEmail: String { t("notification_preferences_recommendation_email") }
    static var notificationPreferencesRecommendationPush: String { t("notification_preferences_recommendation_push") }
    static var notificationPreferencesSaveError: String { t("notification_preferences_save_error") }
    static var notificationPreferencesSubtitle: String { t("notification_preferences_subtitle") }
    static var notificationPreferencesTitle: String { t("notification_preferences_title") }
    static var notificationPtAdminAppPromoInterstitial: String { t("notification_pt_admin_app_promo_interstitial") }
    static var notificationPtAdminMobilePush: String { t("notification_pt_admin_mobile_push") }
    static var notificationPtAdminMobilePushAnnouncement: String { t("notification_pt_admin_mobile_push_announcement") }
    static var notificationPtAdminMobilePushOps: String { t("notification_pt_admin_mobile_push_ops") }
    static var notificationPtAdminMobilePushPromo: String { t("notification_pt_admin_mobile_push_promo") }
    static var notificationPtAdminMobilePushTransactional: String { t("notification_pt_admin_mobile_push_transactional") }
    static var notificationPtMarketplaceChatMessage: String { t("notification_pt_marketplace_chat_message") }
    static var notificationPtMarketplaceChatOfferAccepted: String { t("notification_pt_marketplace_chat_offer_accepted") }
    static var notificationPtMarketplaceChatOfferDeclined: String { t("notification_pt_marketplace_chat_offer_declined") }
    static var notificationPtMarketplaceChatOfferReceived: String { t("notification_pt_marketplace_chat_offer_received") }
    static var notificationPtMarketplaceFollowerBatch: String { t("notification_pt_marketplace_follower_batch") }
    static var notificationPtMarketplaceFollowerNew: String { t("notification_pt_marketplace_follower_new") }
    static var notificationPtMarketplaceListingApproved: String { t("notification_pt_marketplace_listing_approved") }
    static var notificationPtMarketplaceListingApprovedForFollowers: String { t("notification_pt_marketplace_listing_approved_for_followers") }
    static var notificationPtMarketplaceListingLiked: String { t("notification_pt_marketplace_listing_liked") }
    static var notificationPtMarketplaceListingLikedBatch: String { t("notification_pt_marketplace_listing_liked_batch") }
    static var notificationPtMarketplaceOrderCancelled: String { t("notification_pt_marketplace_order_cancelled") }
    static var notificationPtMarketplaceOrderCreated: String { t("notification_pt_marketplace_order_created") }
    static var notificationPtMarketplaceOrderDisputeOpened: String { t("notification_pt_marketplace_order_dispute_opened") }
    static var notificationPtMarketplaceOrderFundsReleased: String { t("notification_pt_marketplace_order_funds_released") }
    static var notificationPtMarketplaceOrderMeetupAborted: String { t("notification_pt_marketplace_order_meetup_aborted") }
    static var notificationPtMarketplaceOrderShipped: String { t("notification_pt_marketplace_order_shipped") }
    static var notificationPtMarketplaceRecommendationCommunityQuiet: String { t("notification_pt_marketplace_recommendation_community_quiet") }
    static var notificationPtMarketplaceRecommendationContinueBrowsing: String { t("notification_pt_marketplace_recommendation_continue_browsing") }
    static var notificationPtMarketplaceRecommendationDailyDigest: String { t("notification_pt_marketplace_recommendation_daily_digest") }
    static var notificationPtMarketplaceRecommendationHuntToday: String { t("notification_pt_marketplace_recommendation_hunt_today") }
    static var notificationPtMarketplaceRecommendationInactiveNudge: String { t("notification_pt_marketplace_recommendation_inactive_nudge") }
    static var notificationPtMarketplaceRecommendationSimilarSaved: String { t("notification_pt_marketplace_recommendation_similar_saved") }
    static var notificationPtMarketplaceRecommendationSocialStyleMatch: String { t("notification_pt_marketplace_recommendation_social_style_match") }
    static var notificationPtMarketplaceRecommendationStyleDrought: String { t("notification_pt_marketplace_recommendation_style_drought") }
    static var notificationPtMarketplaceRecommendationStyleFresh: String { t("notification_pt_marketplace_recommendation_style_fresh") }
    static var notificationPtMarketplaceRecommendationTasteNeighbor: String { t("notification_pt_marketplace_recommendation_taste_neighbor") }
    static var notificationPtMarketplaceReferralInviteRewarded: String { t("notification_pt_marketplace_referral_invite_rewarded") }
    static var notificationPtMarketplaceReviewReceived: String { t("notification_pt_marketplace_review_received") }
    static var notificationRowNoTitle: String { t("notification_row_no_title") }
    static var notificationSrcCoreLocal: String { t("notification_src_core_local") }
    static var notificationSrcKafka: String { t("notification_src_kafka") }
    static var notificationUnreadBadge: String { t("notification_unread_badge") }
    static var notifications: String { t("notifications") }
    static var notificationsCdNone: String { t("notifications_cd_none") }
    static func notificationsCdWithUnread(_ a1: CVarArg) -> String {
        String(format: t("notifications_cd_with_unread"), a1)
    }
    static var onboardingAestheticError: String { t("onboarding_aesthetic_error") }
    static var onboardingContinue: String { t("onboarding_continue") }
    static var onboardingLoadError: String { t("onboarding_load_error") }
    static var onboardingProfilePhotoHint: String { t("onboarding_profile_photo_hint") }
    static var onboardingProfilePhotoRequired: String { t("onboarding_profile_photo_required") }
    static var onboardingProfilePhotoSubtitle: String { t("onboarding_profile_photo_subtitle") }
    static var onboardingProfilePhotoTitle: String { t("onboarding_profile_photo_title") }
    static func onboardingProgressStep(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("onboarding_progress_step"), a1, a2)
    }
    static var onboardingQuestion: String { t("onboarding_question") }
    static func onboardingSelectedCount(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("onboarding_selected_count"), a1, a2)
    }
    static var onboardingShoppingError: String { t("onboarding_shopping_error") }
    static var onboardingShoppingGenderMen: String { t("onboarding_shopping_gender_men") }
    static var onboardingShoppingGenderNonBinary: String { t("onboarding_shopping_gender_non_binary") }
    static var onboardingShoppingGenderSubtitle: String { t("onboarding_shopping_gender_subtitle") }
    static var onboardingShoppingGenderTitle: String { t("onboarding_shopping_gender_title") }
    static var onboardingShoppingGenderWomen: String { t("onboarding_shopping_gender_women") }
    static var onboardingShoppingIntentBuy: String { t("onboarding_shopping_intent_buy") }
    static var onboardingShoppingIntentSell: String { t("onboarding_shopping_intent_sell") }
    static var onboardingShoppingSubtitle: String { t("onboarding_shopping_subtitle") }
    static var onboardingShoppingTitle: String { t("onboarding_shopping_title") }
    static var onboardingSizingBodyFirstSubtitle: String { t("onboarding_sizing_body_first_subtitle") }
    static var onboardingSizingError: String { t("onboarding_sizing_error") }
    static var onboardingSizingOptionalBodySubtitle: String { t("onboarding_sizing_optional_body_subtitle") }
    static var onboardingSizingOptionalBodyTitle: String { t("onboarding_sizing_optional_body_title") }
    static var onboardingSizingOptionalHeightLabel: String { t("onboarding_sizing_optional_height_label") }
    static var onboardingSizingOptionalHeightPlaceholder: String { t("onboarding_sizing_optional_height_placeholder") }
    static var onboardingSizingOptionalHint: String { t("onboarding_sizing_optional_hint") }
    static var onboardingSizingOptionalWeightLabel: String { t("onboarding_sizing_optional_weight_label") }
    static var onboardingSizingOptionalWeightPlaceholder: String { t("onboarding_sizing_optional_weight_placeholder") }
    static var onboardingSizingRequiredHint: String { t("onboarding_sizing_required_hint") }
    static var onboardingSizingScreenTitle: String { t("onboarding_sizing_screen_title") }
    static var onboardingSkip: String { t("onboarding_skip") }
    static var onboardingSubmitError: String { t("onboarding_submit_error") }
    static var onboardingSubtitle: String { t("onboarding_subtitle") }
    static var onboardingTitle: String { t("onboarding_title") }
    static var onboardingUsernameScreenTitle: String { t("onboarding_username_screen_title") }
    static var orderCancelConfirmAction: String { t("order_cancel_confirm_action") }
    static var orderCancelConfirmBody: String { t("order_cancel_confirm_body") }
    static var orderCancelConfirmDismiss: String { t("order_cancel_confirm_dismiss") }
    static var orderCancelConfirmTitle: String { t("order_cancel_confirm_title") }
    static var orderCancelErrorForbidden: String { t("order_cancel_error_forbidden") }
    static var orderCancelErrorGeneric: String { t("order_cancel_error_generic") }
    static var orderCancelErrorNotCancellable: String { t("order_cancel_error_not_cancellable") }
    static var orderCancelErrorNotFound: String { t("order_cancel_error_not_found") }
    static var orderCancelFailed: String { t("order_cancel_failed") }
    static var orderCancelFeedbackCommentLabel: String { t("order_cancel_feedback_comment_label") }
    static var orderCancelFeedbackRatingLabel: String { t("order_cancel_feedback_rating_label") }
    static var orderCancelFeedbackRatingRequired: String { t("order_cancel_feedback_rating_required") }
    static var orderCancelFeedbackSubmit: String { t("order_cancel_feedback_submit") }
    static var orderCancelFeedbackSubtitle: String { t("order_cancel_feedback_subtitle") }
    static var orderCancelFeedbackTitle: String { t("order_cancel_feedback_title") }
    static var orderCancelOrder: String { t("order_cancel_order") }
    static var orderCancelReasonChangedMind: String { t("order_cancel_reason_changed_mind") }
    static var orderCancelReasonFoundElsewhere: String { t("order_cancel_reason_found_elsewhere") }
    static var orderCancelReasonMeetupNotPossible: String { t("order_cancel_reason_meetup_not_possible") }
    static var orderCancelReasonNoteHint: String { t("order_cancel_reason_note_hint") }
    static var orderCancelReasonNoteLabel: String { t("order_cancel_reason_note_label") }
    static var orderCancelReasonNoteRequired: String { t("order_cancel_reason_note_required") }
    static var orderCancelReasonOther: String { t("order_cancel_reason_other") }
    static var orderCancelReasonPaymentExpired: String { t("order_cancel_reason_payment_expired") }
    static var orderCancelReasonPaymentProblem: String { t("order_cancel_reason_payment_problem") }
    static var orderCancelReasonPriceConcern: String { t("order_cancel_reason_price_concern") }
    static var orderCancelReasonSellerSlow: String { t("order_cancel_reason_seller_slow") }
    static var orderCancelReasonShippingNotSuitable: String { t("order_cancel_reason_shipping_not_suitable") }
    static var orderCancelReasonSubtitle: String { t("order_cancel_reason_subtitle") }
    static var orderCancelReasonTitle: String { t("order_cancel_reason_title") }
    static var orderCancelSuccess: String { t("order_cancel_success") }
    static func orderCancelledBuyerHintActive(_ a1: CVarArg) -> String {
        String(format: t("order_cancelled_buyer_hint_active"), a1)
    }
    static var orderCancelledBuyerHintSold: String { t("order_cancelled_buyer_hint_sold") }
    static var orderCancelledBuyerOpenChat: String { t("order_cancelled_buyer_open_chat") }
    static var orderDetailAckCashOk: String { t("order_detail_ack_cash_ok") }
    static var orderDetailAckOfflineCash: String { t("order_detail_ack_offline_cash") }
    static var orderDetailActionShip: String { t("order_detail_action_ship") }
    static var orderDetailAmount: String { t("order_detail_amount") }
    static var orderDetailBuyerProductPrice: String { t("order_detail_buyer_product_price") }
    static var orderDetailBuyerProtectionBody: String { t("order_detail_buyer_protection_body") }
    static var orderDetailBuyerProtectionTitle: String { t("order_detail_buyer_protection_title") }
    static var orderDetailBuyerReviewHeadingBuyer: String { t("order_detail_buyer_review_heading_buyer") }
    static var orderDetailBuyerReviewHeadingSeller: String { t("order_detail_buyer_review_heading_seller") }
    static var orderDetailBuyerReviewHeadingViewer: String { t("order_detail_buyer_review_heading_viewer") }
    static var orderDetailBuyerReviewNoComment: String { t("order_detail_buyer_review_no_comment") }
    static func orderDetailBuyerReviewSubmittedAt(_ a1: CVarArg) -> String {
        String(format: t("order_detail_buyer_review_submitted_at"), a1)
    }
    static var orderDetailBuyerShippingFee: String { t("order_detail_buyer_shipping_fee") }
    static var orderDetailBuyerTotal: String { t("order_detail_buyer_total") }
    static var orderDetailChatBuyer: String { t("order_detail_chat_buyer") }
    static var orderDetailChatSeller: String { t("order_detail_chat_seller") }
    static var orderDetailChatUnavailable: String { t("order_detail_chat_unavailable") }
    static var orderDetailCheckInCta: String { t("order_detail_check_in_cta") }
    static func orderDetailCommissionPercent(_ a1: CVarArg) -> String {
        String(format: t("order_detail_commission_percent"), a1)
    }
    static var orderDetailConfirmHandoff: String { t("order_detail_confirm_handoff") }
    static var orderDetailConfirmHandoffError: String { t("order_detail_confirm_handoff_error") }
    static var orderDetailConfirmHandoffSuccess: String { t("order_detail_confirm_handoff_success") }
    static var orderDetailContinueInChat: String { t("order_detail_continue_in_chat") }
    static var orderDetailCounterpartyBuyer: String { t("order_detail_counterparty_buyer") }
    static var orderDetailCounterpartySeller: String { t("order_detail_counterparty_seller") }
    static func orderDetailDisputeAddPhoto(_ a1: CVarArg) -> String {
        String(format: t("order_detail_dispute_add_photo"), a1)
    }
    static var orderDetailDisputeDescriptionLabel: String { t("order_detail_dispute_description_label") }
    static var orderDetailDisputeDescriptionRequired: String { t("order_detail_dispute_description_required") }
    static var orderDetailDisputeDialogTitleEvidence: String { t("order_detail_dispute_dialog_title_evidence") }
    static var orderDetailDisputeDialogTitleOpen: String { t("order_detail_dispute_dialog_title_open") }
    static var orderDetailDisputeError: String { t("order_detail_dispute_error") }
    static var orderDetailDisputeEvidence: String { t("order_detail_dispute_evidence") }
    static var orderDetailDisputeEvidenceSuccess: String { t("order_detail_dispute_evidence_success") }
    static var orderDetailDisputeOpen: String { t("order_detail_dispute_open") }
    static var orderDetailDisputeOpenSuccess: String { t("order_detail_dispute_open_success") }
    static var orderDetailDisputePhotoLimit: String { t("order_detail_dispute_photo_limit") }
    static var orderDetailDisputeSubmit: String { t("order_detail_dispute_submit") }
    static func orderDetailGraceBuyerChecked(_ a1: CVarArg) -> String {
        String(format: t("order_detail_grace_buyer_checked"), a1)
    }
    static func orderDetailGraceSellerChecked(_ a1: CVarArg) -> String {
        String(format: t("order_detail_grace_seller_checked"), a1)
    }
    static var orderDetailGraceSosUnlocked: String { t("order_detail_grace_sos_unlocked") }
    static var orderDetailHelpBody: String { t("order_detail_help_body") }
    static var orderDetailHelpCd: String { t("order_detail_help_cd") }
    static var orderDetailHelpClose: String { t("order_detail_help_close") }
    static var orderDetailLoadError: String { t("order_detail_load_error") }
    static var orderDetailLoading: String { t("order_detail_loading") }
    static var orderDetailMeetingCheckInAlready: String { t("order_detail_meeting_check_in_already") }
    static var orderDetailMeetingCheckInOk: String { t("order_detail_meeting_check_in_ok") }
    static var orderDetailMeetingCheckInRefreshOnly: String { t("order_detail_meeting_check_in_refresh_only") }
    static var orderDetailMeetingGraceSyncHint: String { t("order_detail_meeting_grace_sync_hint") }
    static var orderDetailMeetingGraceTitle: String { t("order_detail_meeting_grace_title") }
    static var orderDetailMeetupActivityTitle: String { t("order_detail_meetup_activity_title") }
    static func orderDetailMeetupBuyerCheckIn(_ a1: CVarArg) -> String {
        String(format: t("order_detail_meetup_buyer_check_in"), a1)
    }
    static var orderDetailMeetupCheckInNote: String { t("order_detail_meetup_check_in_note") }
    static func orderDetailMeetupCreated(_ a1: CVarArg) -> String {
        String(format: t("order_detail_meetup_created"), a1)
    }
    static var orderDetailMeetupOpenMaps: String { t("order_detail_meetup_open_maps") }
    static func orderDetailMeetupPayBy(_ a1: CVarArg) -> String {
        String(format: t("order_detail_meetup_pay_by"), a1)
    }
    static var orderDetailMeetupReminderOff: String { t("order_detail_meetup_reminder_off") }
    static func orderDetailMeetupReminderOn(_ a1: CVarArg) -> String {
        String(format: t("order_detail_meetup_reminder_on"), a1)
    }
    static func orderDetailMeetupReminderSent(_ a1: CVarArg) -> String {
        String(format: t("order_detail_meetup_reminder_sent"), a1)
    }
    static var orderDetailMeetupSectionTitle: String { t("order_detail_meetup_section_title") }
    static func orderDetailMeetupSellerCheckIn(_ a1: CVarArg) -> String {
        String(format: t("order_detail_meetup_seller_check_in"), a1)
    }
    static func orderDetailMeetupStatus(_ a1: CVarArg) -> String {
        String(format: t("order_detail_meetup_status"), a1)
    }
    static func orderDetailMeetupUpdated(_ a1: CVarArg) -> String {
        String(format: t("order_detail_meetup_updated"), a1)
    }
    static func orderDetailMeetupWhen(_ a1: CVarArg) -> String {
        String(format: t("order_detail_meetup_when"), a1)
    }
    static var orderDetailNoShowDialogTitle: String { t("order_detail_no_show_dialog_title") }
    static var orderDetailNoShowMutualCancel: String { t("order_detail_no_show_mutual_cancel") }
    static var orderDetailNoShowNoteLabel: String { t("order_detail_no_show_note_label") }
    static var orderDetailNoShowOtherAbsent: String { t("order_detail_no_show_other_absent") }
    static var orderDetailNoShowOtherLate: String { t("order_detail_no_show_other_late") }
    static var orderDetailPartyBuyer: String { t("order_detail_party_buyer") }
    static var orderDetailPartySeller: String { t("order_detail_party_seller") }
    static var orderDetailPay: String { t("order_detail_pay") }
    static var orderDetailPaymentBreakdownTitle: String { t("order_detail_payment_breakdown_title") }
    static var orderDetailPlatformFee: String { t("order_detail_platform_fee") }
    static var orderDetailProduct: String { t("order_detail_product") }
    static var orderDetailReportNoShowCta: String { t("order_detail_report_no_show_cta") }
    static var orderDetailReportNoShowOk: String { t("order_detail_report_no_show_ok") }
    static var orderDetailReviewCommentLabel: String { t("order_detail_review_comment_label") }
    static var orderDetailReviewError: String { t("order_detail_review_error") }
    static var orderDetailReviewHint: String { t("order_detail_review_hint") }
    static var orderDetailReviewSent: String { t("order_detail_review_sent") }
    static var orderDetailReviewSubmit: String { t("order_detail_review_submit") }
    static var orderDetailReviewTitle: String { t("order_detail_review_title") }
    static var orderDetailSellerListingPrice: String { t("order_detail_seller_listing_price") }
    static var orderDetailSellerNet: String { t("order_detail_seller_net") }
    static var orderDetailSellerPayout: String { t("order_detail_seller_payout") }
    static var orderDetailSellerRevenueTitle: String { t("order_detail_seller_revenue_title") }
    static var orderDetailShipBookCarrier: String { t("order_detail_ship_book_carrier") }
    static var orderDetailShipCarrierLabel: String { t("order_detail_ship_carrier_label") }
    static var orderDetailShipConfirm: String { t("order_detail_ship_confirm") }
    static var orderDetailShipDialogTitle: String { t("order_detail_ship_dialog_title") }
    static var orderDetailShipError: String { t("order_detail_ship_error") }
    static var orderDetailShipManualSection: String { t("order_detail_ship_manual_section") }
    static var orderDetailShipSuccess: String { t("order_detail_ship_success") }
    static var orderDetailShipTrackingLabel: String { t("order_detail_ship_tracking_label") }
    static var orderDetailShipTrackingRequired: String { t("order_detail_ship_tracking_required") }
    static var orderDetailShipmentAdvance: String { t("order_detail_shipment_advance") }
    static var orderDetailShipmentAdvanceOk: String { t("order_detail_shipment_advance_ok") }
    static var orderDetailShippingAddressTitle: String { t("order_detail_shipping_address_title") }
    static var orderDetailShippingChange: String { t("order_detail_shipping_change") }
    static var orderDetailShippingChoose: String { t("order_detail_shipping_choose") }
    static var orderDetailShippingNone: String { t("order_detail_shipping_none") }
    static var orderDetailShippingTitle: String { t("order_detail_shipping_title") }
    static var orderDetailStatusCaption: String { t("order_detail_status_caption") }
    static var orderDetailTitle: String { t("order_detail_title") }
    static var orderDetailTracking: String { t("order_detail_tracking") }
    static var orderDetailTrackingEmpty: String { t("order_detail_tracking_empty") }
    static func orderDetailVariantLine(_ a1: CVarArg) -> String {
        String(format: t("order_detail_variant_line"), a1)
    }
    static func orderExpiryFulfillmentBuyer(_ a1: CVarArg) -> String {
        String(format: t("order_expiry_fulfillment_buyer"), a1)
    }
    static func orderExpiryFulfillmentSeller(_ a1: CVarArg) -> String {
        String(format: t("order_expiry_fulfillment_seller"), a1)
    }
    static func orderExpiryMeetupPaymentBuyer(_ a1: CVarArg) -> String {
        String(format: t("order_expiry_meetup_payment_buyer"), a1)
    }
    static func orderExpiryMeetupPaymentSeller(_ a1: CVarArg) -> String {
        String(format: t("order_expiry_meetup_payment_seller"), a1)
    }
    static func orderExpiryPaymentBuyer(_ a1: CVarArg) -> String {
        String(format: t("order_expiry_payment_buyer"), a1)
    }
    static func orderExpiryPaymentSeller(_ a1: CVarArg) -> String {
        String(format: t("order_expiry_payment_seller"), a1)
    }
    static func orderHeroBuyerEscrowSub(_ a1: CVarArg) -> String {
        String(format: t("order_hero_buyer_escrow_sub"), a1)
    }
    static var orderHeroBuyerPaymentHeldSub: String { t("order_hero_buyer_payment_held_sub") }
    static var orderHeroBuyerPaymentHeldTitle: String { t("order_hero_buyer_payment_held_title") }
    static var orderHeroBuyerPaymentPendingSub: String { t("order_hero_buyer_payment_pending_sub") }
    static var orderHeroBuyerPaymentPendingTitle: String { t("order_hero_buyer_payment_pending_title") }
    static func orderHeroCancelledSub(_ a1: CVarArg) -> String {
        String(format: t("order_hero_cancelled_sub"), a1)
    }
    static var orderHeroCancelledSubGeneric: String { t("order_hero_cancelled_sub_generic") }
    static var orderHeroCashMeetupSub: String { t("order_hero_cash_meetup_sub") }
    static func orderHeroCompletedSub(_ a1: CVarArg) -> String {
        String(format: t("order_hero_completed_sub"), a1)
    }
    static var orderHeroDisputedSub: String { t("order_hero_disputed_sub") }
    static func orderHeroEtaLine(_ a1: CVarArg) -> String {
        String(format: t("order_hero_eta_line"), a1)
    }
    static var orderHeroFulfillmentPendingSub: String { t("order_hero_fulfillment_pending_sub") }
    static var orderHeroInTransitSub: String { t("order_hero_in_transit_sub") }
    static var orderHeroSellerPrepareSub: String { t("order_hero_seller_prepare_sub") }
    static func orderHeroSellerPrepareSubDeadline(_ a1: CVarArg) -> String {
        String(format: t("order_hero_seller_prepare_sub_deadline"), a1)
    }
    static var orderHeroSellerPrepareTitle: String { t("order_hero_seller_prepare_title") }
    static var orderHeroSellerWaitPaymentSub: String { t("order_hero_seller_wait_payment_sub") }
    static var orderHeroSellerWaitPaymentTitle: String { t("order_hero_seller_wait_payment_title") }
    static var orderStatusCancelled: String { t("order_status_cancelled") }
    static var orderStatusCashMeetupOpen: String { t("order_status_cash_meetup_open") }
    static var orderStatusDeliveredConfirmed: String { t("order_status_delivered_confirmed") }
    static var orderStatusDisputed: String { t("order_status_disputed") }
    static var orderStatusFulfillmentPending: String { t("order_status_fulfillment_pending") }
    static var orderStatusInTransit: String { t("order_status_in_transit") }
    static var orderStatusPaymentHeld: String { t("order_status_payment_held") }
    static var orderStatusPaymentPending: String { t("order_status_payment_pending") }
    static var orderStatusUnknown: String { t("order_status_unknown") }
    static var orderTimelineCancelled: String { t("order_timeline_cancelled") }
    static var orderTimelineCashMeetup: String { t("order_timeline_cash_meetup") }
    static var orderTimelineChooseFulfillment: String { t("order_timeline_choose_fulfillment") }
    static var orderTimelineDelivered: String { t("order_timeline_delivered") }
    static var orderTimelineDisputeOpen: String { t("order_timeline_dispute_open") }
    static var orderTimelineInTransit: String { t("order_timeline_in_transit") }
    static var orderTimelineMeetupAwaitingBuyer: String { t("order_timeline_meetup_awaiting_buyer") }
    static var orderTimelineMeetupAwaitingBuyerSub: String { t("order_timeline_meetup_awaiting_buyer_sub") }
    static var orderTimelineMeetupHandoff: String { t("order_timeline_meetup_handoff") }
    static var orderTimelinePaid: String { t("order_timeline_paid") }
    static var orderTimelinePlaced: String { t("order_timeline_placed") }
    static var orderTimelinePreparing: String { t("order_timeline_preparing") }
    static var orderTimelinePreparingSub: String { t("order_timeline_preparing_sub") }
    static var orderTimelineShipped: String { t("order_timeline_shipped") }
    static var orderTimelineTitle: String { t("order_timeline_title") }
    static var orderTimelineWaitingPayment: String { t("order_timeline_waiting_payment") }
    static var ordersAdCta: String { t("orders_ad_cta") }
    static var ordersAdSubtitle: String { t("orders_ad_subtitle") }
    static var ordersAdTitle: String { t("orders_ad_title") }
    static var ordersBack: String { t("orders_back") }
    static var ordersChipAll: String { t("orders_chip_all") }
    static var ordersChipCancelled: String { t("orders_chip_cancelled") }
    static var ordersChipDelivered: String { t("orders_chip_delivered") }
    static var ordersChipDisputed: String { t("orders_chip_disputed") }
    static var ordersChipInTransit: String { t("orders_chip_in_transit") }
    static var ordersChipPaymentHeld: String { t("orders_chip_payment_held") }
    static var ordersChipPaymentPending: String { t("orders_chip_payment_pending") }
    static var ordersConfirmError: String { t("orders_confirm_error") }
    static var ordersConfirmReceived: String { t("orders_confirm_received") }
    static var ordersConfirmSuccess: String { t("orders_confirm_success") }
    static var ordersEmptyBuying: String { t("orders_empty_buying") }
    static var ordersEmptyBuyingSub: String { t("orders_empty_buying_sub") }
    static var ordersEmptyFilteredSub: String { t("orders_empty_filtered_sub") }
    static var ordersEmptyFilteredTitle: String { t("orders_empty_filtered_title") }
    static var ordersEmptySelling: String { t("orders_empty_selling") }
    static var ordersEmptySellingSub: String { t("orders_empty_selling_sub") }
    static var ordersErrorSub: String { t("orders_error_sub") }
    static var ordersErrorTitle: String { t("orders_error_title") }
    static var ordersFilterAll: String { t("orders_filter_all") }
    static var ordersFilterClear: String { t("orders_filter_clear") }
    static var ordersIconCd: String { t("orders_icon_cd") }
    static var ordersPromoBadge: String { t("orders_promo_badge") }
    static func ordersPromoPagerCd(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("orders_promo_pager_cd"), a1, a2)
    }
    static var ordersPromoSlide1Subtitle: String { t("orders_promo_slide1_subtitle") }
    static var ordersPromoSlide1Title: String { t("orders_promo_slide1_title") }
    static var ordersPromoSlide2Subtitle: String { t("orders_promo_slide2_subtitle") }
    static var ordersPromoSlide2Title: String { t("orders_promo_slide2_title") }
    static var ordersPromoSlide3Subtitle: String { t("orders_promo_slide3_subtitle") }
    static var ordersPromoSlide3Title: String { t("orders_promo_slide3_title") }
    static var ordersReview: String { t("orders_review") }
    static var ordersStatusCompleted: String { t("orders_status_completed") }
    static var ordersStatusDelivering: String { t("orders_status_delivering") }
    static var ordersStatusPending: String { t("orders_status_pending") }
    static var ordersTabBuying: String { t("orders_tab_buying") }
    static var ordersTabSelling: String { t("orders_tab_selling") }
    static var ordersTitle: String { t("orders_title") }
    static var otpBackCd: String { t("otp_back_cd") }
    static var otpHelpLine1: String { t("otp_help_line1") }
    static var otpHelpLine2: String { t("otp_help_line2") }
    static var otpHelpLine3: String { t("otp_help_line3") }
    static var otpHelpTitle: String { t("otp_help_title") }
    static var otpInvalidLength: String { t("otp_invalid_length") }
    static var otpResend: String { t("otp_resend") }
    static var otpResendSending: String { t("otp_resend_sending") }
    static func otpResendWait(_ a1: CVarArg) -> String {
        String(format: t("otp_resend_wait"), a1)
    }
    static func otpSubtitle(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("otp_subtitle"), a1, a2)
    }
    static var otpTitle: String { t("otp_title") }
    static var otpVerify: String { t("otp_verify") }
    static var otpVerifyFailed: String { t("otp_verify_failed") }
    static var otpVerifySuccess: String { t("otp_verify_success") }
    static var passwordChangeErrorGeneric: String { t("password_change_error_generic") }
    static var passwordChangeSuccess: String { t("password_change_success") }
    static var passwordConfirmLabel: String { t("password_confirm_label") }
    static var passwordCurrentLabel: String { t("password_current_label") }
    static var passwordErrorCurrentRequired: String { t("password_error_current_required") }
    static var passwordErrorInvalidCurrent: String { t("password_error_invalid_current") }
    static var passwordErrorLength: String { t("password_error_length") }
    static var passwordMismatch: String { t("password_mismatch") }
    static var passwordNewLabel: String { t("password_new_label") }
    static var passwordSetupContinue: String { t("password_setup_continue") }
    static var passwordSetupSubtitle: String { t("password_setup_subtitle") }
    static var passwordSetupTitle: String { t("password_setup_title") }
    static var pendingPaymentBannerCountdownHint: String { t("pending_payment_banner_countdown_hint") }
    static var pendingPaymentBannerCta: String { t("pending_payment_banner_cta") }
    static var pendingPaymentBannerTitle: String { t("pending_payment_banner_title") }
    static var pendingPaymentExpiredLabel: String { t("pending_payment_expired_label") }
    static var pendingPaymentExpiredSnackbar: String { t("pending_payment_expired_snackbar") }
    static var postAcceptOffers: String { t("post_accept_offers") }
    static var postAddShippingAddress: String { t("post_add_shipping_address") }
    static var postAutoPriceDrop: String { t("post_auto_price_drop") }
    static var postBrandFeatured: String { t("post_brand_featured") }
    static func postCategoryChildrenHeading(_ a1: CVarArg) -> String {
        String(format: t("post_category_children_heading"), a1)
    }
    static var postCategoryLevelUp: String { t("post_category_level_up") }
    static var postCategoryNoMatches: String { t("post_category_no_matches") }
    static var postCategoryParentsHeading: String { t("post_category_parents_heading") }
    static var postClearBrand: String { t("post_clear_brand") }
    static var postConditionDefectPhotoHint: String { t("post_condition_defect_photo_hint") }
    static var postConditionDefectsLabel: String { t("post_condition_defects_label") }
    static func postConditionScoreLabel(_ a1: CVarArg) -> String {
        String(format: t("post_condition_score_label"), a1)
    }
    static var postDefectFading: String { t("post_defect_fading") }
    static var postDefectMissingButton: String { t("post_defect_missing_button") }
    static var postDefectOdor: String { t("post_defect_odor") }
    static var postDefectPilling: String { t("post_defect_pilling") }
    static var postDefectStains: String { t("post_defect_stains") }
    static var postDefectWorn: String { t("post_defect_worn") }
    static var postDescriptionLabel: String { t("post_description_label") }
    static var postDropPercent: String { t("post_drop_percent") }
    static var postFillModeFromProfileSubtitleEmpty: String { t("post_fill_mode_from_profile_subtitle_empty") }
    static var postFillModeFromProfileSubtitleReady: String { t("post_fill_mode_from_profile_subtitle_ready") }
    static var postFillModeFromProfileTitle: String { t("post_fill_mode_from_profile_title") }
    static var postFillModeManualSubtitle: String { t("post_fill_mode_manual_subtitle") }
    static var postFillModeManualTitle: String { t("post_fill_mode_manual_title") }
    static var postFillModePrefilledHint: String { t("post_fill_mode_prefilled_hint") }
    static var postFillModeProfileEmpty: String { t("post_fill_mode_profile_empty") }
    static func postFillModeProfileGender(_ a1: CVarArg) -> String {
        String(format: t("post_fill_mode_profile_gender"), a1)
    }
    static func postFillModeProfileSize(_ a1: CVarArg) -> String {
        String(format: t("post_fill_mode_profile_size"), a1)
    }
    static func postFillModeProfileTags(_ a1: CVarArg) -> String {
        String(format: t("post_fill_mode_profile_tags"), a1)
    }
    static var postFillModeSubtitle: String { t("post_fill_mode_subtitle") }
    static var postFillModeTitle: String { t("post_fill_mode_title") }
    static var postFloorPrice: String { t("post_floor_price") }
    static var postHintBrand: String { t("post_hint_brand") }
    static var postHintCategoryRequired: String { t("post_hint_category_required") }
    static var postHintCategoryStep: String { t("post_hint_category_step") }
    static var postHintConditionRequired: String { t("post_hint_condition_required") }
    static var postHintCountry: String { t("post_hint_country") }
    static var postHintListingDetailsStep: String { t("post_hint_listing_details_step") }
    static var postHintMeasure: String { t("post_hint_measure") }
    static var postHintMeasureSize: String { t("post_hint_measure_size") }
    static var postHintPhotos: String { t("post_hint_photos") }
    static var postHintPrice: String { t("post_hint_price") }
    static var postHintShipping: String { t("post_hint_shipping") }
    static var postHintStyleTagsStep: String { t("post_hint_style_tags_step") }
    static var postHintTitleDesc: String { t("post_hint_title_desc") }
    static var postListingColorHint: String { t("post_listing_color_hint") }
    static var postListingDetailsIntro: String { t("post_listing_details_intro") }
    static var postListingPhotoSlotsUnavailable: String { t("post_listing_photo_slots_unavailable") }
    static var postListingSizingGenderHint: String { t("post_listing_sizing_gender_hint") }
    static var postListingSizingGenderRecommended: String { t("post_listing_sizing_gender_recommended") }
    static var postListingSizingSubtitle: String { t("post_listing_sizing_subtitle") }
    static var postMeasureNoticeCombined: String { t("post_measure_notice_combined") }
    static var postMeasureSectionDetails: String { t("post_measure_section_details") }
    static var postMeasureSectionSize: String { t("post_measure_section_size") }
    static var postMeasureSectionUnit: String { t("post_measure_section_unit") }
    static var postMeasureSizeIntro: String { t("post_measure_size_intro") }
    static var postMeasureStepSubtitle: String { t("post_measure_step_subtitle") }
    static var postMeasurementChest: String { t("post_measurement_chest") }
    static var postMeasurementHem: String { t("post_measurement_hem") }
    static var postMeasurementLength: String { t("post_measurement_length") }
    static var postMeasurementShoulders: String { t("post_measurement_shoulders") }
    static var postMeasurementSleeve: String { t("post_measurement_sleeve") }
    static var postNextBlockedCategory: String { t("post_next_blocked_category") }
    static var postNextBlockedCommitment: String { t("post_next_blocked_commitment") }
    static var postNextBlockedCondition: String { t("post_next_blocked_condition") }
    static var postNextBlockedDescriptionLong: String { t("post_next_blocked_description_long") }
    static var postNextBlockedDropPercent: String { t("post_next_blocked_drop_percent") }
    static var postNextBlockedFloor: String { t("post_next_blocked_floor") }
    static var postNextBlockedFloorBelow: String { t("post_next_blocked_floor_below") }
    static var postNextBlockedGeneric: String { t("post_next_blocked_generic") }
    static var postNextBlockedPhotos: String { t("post_next_blocked_photos") }
    static var postNextBlockedPrice: String { t("post_next_blocked_price") }
    static var postNextBlockedPriceRange: String { t("post_next_blocked_price_range") }
    static var postNextBlockedTags: String { t("post_next_blocked_tags") }
    static var postNextBlockedTitleLong: String { t("post_next_blocked_title_long") }
    static var postNextBlockedTitleShort: String { t("post_next_blocked_title_short") }
    static var postNoSavedAddress: String { t("post_no_saved_address") }
    static var postNoticeTitle: String { t("post_notice_title") }
    static var postPriceStepSubtitle: String { t("post_price_step_subtitle") }
    static func postPriceVndExample(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("post_price_vnd_example"), a1, a2)
    }
    static var postPriceVndPrefix: String { t("post_price_vnd_prefix") }
    static func postPriceVndPreview(_ a1: CVarArg) -> String {
        String(format: t("post_price_vnd_preview"), a1)
    }
    static var postPriceVndRangeHint: String { t("post_price_vnd_range_hint") }
    static var postPriceVndSuffix: String { t("post_price_vnd_suffix") }
    static var postReviewBuyerBannerSubtitle: String { t("post_review_buyer_banner_subtitle") }
    static var postReviewBuyerBannerTitle: String { t("post_review_buyer_banner_title") }
    static var postReviewBuyerPageSubtitle: String { t("post_review_buyer_page_subtitle") }
    static var postReviewDetailPreviewHeading: String { t("post_review_detail_preview_heading") }
    static var postReviewEditSection: String { t("post_review_edit_section") }
    static var postReviewFeedPreviewHeading: String { t("post_review_feed_preview_heading") }
    static var postReviewMissingTitle: String { t("post_review_missing_title") }
    static var postReviewNotSet: String { t("post_review_not_set") }
    static var postReviewNoticeTitle: String { t("post_review_notice_title") }
    static var postReviewOptionalEmpty: String { t("post_review_optional_empty") }
    static func postReviewPhotoCount(_ a1: CVarArg) -> String {
        String(format: t("post_review_photo_count"), a1)
    }
    static var postSearchBrand: String { t("post_search_brand") }
    static var postSearchCategory: String { t("post_search_category") }
    static var postSearchCountry: String { t("post_search_country") }
    static var postSearchStyleTags: String { t("post_search_style_tags") }
    static var postStep1CategoryIntro: String { t("post_step1_category_intro") }
    static var postStep1CategorySectionSubtitle: String { t("post_step1_category_section_subtitle") }
    static var postStep1CategorySectionTitle: String { t("post_step1_category_section_title") }
    static var postStep1Intro: String { t("post_step1_intro") }
    static var postStep1StyleSectionSubtitle: String { t("post_step1_style_section_subtitle") }
    static var postStep1StyleSectionTitle: String { t("post_step1_style_section_title") }
    static var postStep2StyleIntro: String { t("post_step2_style_intro") }
    static var postStepBrand: String { t("post_step_brand") }
    static var postStepCategory: String { t("post_step_category") }
    static var postStepCategoryOnly: String { t("post_step_category_only") }
    static var postStepColor: String { t("post_step_color") }
    static var postStepCondition: String { t("post_step_condition") }
    static var postStepConditionShort: String { t("post_step_condition_short") }
    static var postStepCountry: String { t("post_step_country") }
    static var postStepGenderTarget: String { t("post_step_gender_target") }
    static var postStepListingDetails: String { t("post_step_listing_details") }
    static var postStepMeasure: String { t("post_step_measure") }
    static var postStepPhotos: String { t("post_step_photos") }
    static var postStepPrice: String { t("post_step_price") }
    static var postStepReview: String { t("post_step_review") }
    static var postStepShipping: String { t("post_step_shipping") }
    static var postStepStyleOnly: String { t("post_step_style_only") }
    static var postStepText: String { t("post_step_text") }
    static var postStyleTagsNoMatches: String { t("post_style_tags_no_matches") }
    static var postUnitCm: String { t("post_unit_cm") }
    static var postUnitIn: String { t("post_unit_in") }
    static var postValidationCategory: String { t("post_validation_category") }
    static var postValidationCommitment: String { t("post_validation_commitment") }
    static var postValidationCondition: String { t("post_validation_condition") }
    static var postValidationDescriptionLong: String { t("post_validation_description_long") }
    static var postValidationDropPercent: String { t("post_validation_drop_percent") }
    static var postValidationFloor: String { t("post_validation_floor") }
    static var postValidationFloorBelowPrice: String { t("post_validation_floor_below_price") }
    static var postValidationPhotos: String { t("post_validation_photos") }
    static var postValidationPrice: String { t("post_validation_price") }
    static var postValidationPriceRange: String { t("post_validation_price_range") }
    static var postValidationTagsMax: String { t("post_validation_tags_max") }
    static var postValidationTitleLong: String { t("post_validation_title_long") }
    static var postValidationTitleShort: String { t("post_validation_title_short") }
    static var productActionFollowSeller: String { t("product_action_follow_seller") }
    static var productActionFollowingSeller: String { t("product_action_following_seller") }
    static var productActionLike: String { t("product_action_like") }
    static var productActionSave: String { t("product_action_save") }
    static var productActionShare: String { t("product_action_share") }
    static var productBrand: String { t("product_brand") }
    static var productBuyNow: String { t("product_buy_now") }
    static var productCategory: String { t("product_category") }
    static var productChat: String { t("product_chat") }
    static var productConditionLabel: String { t("product_condition_label") }
    static var productContinueCheckout: String { t("product_continue_checkout") }
    static var productDetailError: String { t("product_detail_error") }
    static var productDetailTitle: String { t("product_detail_title") }
    static func productFromCountry(_ a1: CVarArg) -> String {
        String(format: t("product_from_country"), a1)
    }
    static func productListedOn(_ a1: CVarArg) -> String {
        String(format: t("product_listed_on"), a1)
    }
    static var productListingAvailableSnackbar: String { t("product_listing_available_snackbar") }
    static var productListingSoldBar: String { t("product_listing_sold_bar") }
    static var productMaterial: String { t("product_material") }
    static var productMeasChest: String { t("product_meas_chest") }
    static var productMeasEmpty: String { t("product_meas_empty") }
    static var productMeasHem: String { t("product_meas_hem") }
    static var productMeasLength: String { t("product_meas_length") }
    static var productMeasShoulders: String { t("product_meas_shoulders") }
    static var productMeasSleeve: String { t("product_meas_sleeve") }
    static func productMoreFromSeller(_ a1: CVarArg) -> String {
        String(format: t("product_more_from_seller"), a1)
    }
    static var productSellerNameFallback: String { t("product_seller_name_fallback") }
    static func productRelatedCategory(_ a1: CVarArg) -> String {
        String(format: t("product_related_category"), a1)
    }
    static var productRelatedCategoryFallback: String { t("product_related_category_fallback") }
    static func productRelatedBrand(_ a1: CVarArg) -> String {
        String(format: t("product_related_brand"), a1)
    }
    static var productRelatedStyle: String { t("product_related_style") }
    static var productDiscoveryHubTitle: String { t("product_discovery_hub_title") }
    static var productDiscoveryHubSubtitle: String { t("product_discovery_hub_subtitle") }
    static var productRelationBadgeSeller: String { t("product_relation_badge_seller") }
    static var productRelationLegendSeller: String { t("product_relation_legend_seller") }
    static var productRelationLegendCategory: String { t("product_relation_legend_category") }
    static var productRelationLegendBrand: String { t("product_relation_legend_brand") }
    static var productRelationLegendStyle: String { t("product_relation_legend_style") }
    static func productRelationBadgeA11y(_ label: String) -> String {
        String(format: t("product_relation_badge_a11y"), label)
    }
    static var productOffersAccepted: String { t("product_offers_accepted") }
    static func productPriceDropFloor(_ a1: CVarArg) -> String {
        String(format: t("product_price_drop_floor"), a1)
    }
    static func productPriceDropNext(_ a1: CVarArg) -> String {
        String(format: t("product_price_drop_next"), a1)
    }
    static func productPriceDropPercent(_ a1: CVarArg) -> String {
        String(format: t("product_price_drop_percent"), a1)
    }
    static var productPriceDropTitle: String { t("product_price_drop_title") }
    static var productPurchaseGuideBody: String { t("product_purchase_guide_body") }
    static var productPurchaseGuideBodyNoBuyNow: String { t("product_purchase_guide_body_no_buy_now") }
    static var productPurchaseGuideGotIt: String { t("product_purchase_guide_got_it") }
    static var productPurchaseGuideTitle: String { t("product_purchase_guide_title") }
    static var productReservedBuyer: String { t("product_reserved_buyer") }
    static func productReservedBuyerContinue(_ a1: CVarArg) -> String {
        String(format: t("product_reserved_buyer_continue"), a1)
    }
    static var productReservedOther: String { t("product_reserved_other") }
    static var productSaveNudge: String { t("product_save_nudge") }
    static var productSaveNudgeCta: String { t("product_save_nudge_cta") }
    static var productSaveNudgeDismiss: String { t("product_save_nudge_dismiss") }
    static var productSectionAbout: String { t("product_section_about") }
    static var productSectionAtAGlance: String { t("product_section_at_a_glance") }
    static var productSectionBuying: String { t("product_section_buying") }
    static var productSectionDescription: String { t("product_section_description") }
    static var productSectionDetailedSpecs: String { t("product_section_detailed_specs") }
    static var productSectionMeasurements: String { t("product_section_measurements") }
    static var productSectionSeller: String { t("product_section_seller") }
    static var productSectionShipping: String { t("product_section_shipping") }
    static var productSectionStyle: String { t("product_section_style") }
    static var productSeeMore: String { t("product_see_more") }
    static func productSellerFollowers(_ a1: CVarArg) -> String {
        String(format: t("product_seller_followers"), a1)
    }
    static func productSellerListings(_ a1: CVarArg) -> String {
        String(format: t("product_seller_listings"), a1)
    }
    static func productSellerProductsCount(_ a1: CVarArg) -> String {
        String(format: t("product_seller_products_count"), a1)
    }
    static var productSellerVerifiedCd: String { t("product_seller_verified_cd") }
    static func productShipFromUpper(_ a1: CVarArg) -> String {
        String(format: t("product_ship_from_upper"), a1)
    }
    static var productShippingContactSeller: String { t("product_shipping_contact_seller") }
    static func productShippingEstimate(_ a1: CVarArg) -> String {
        String(format: t("product_shipping_estimate"), a1)
    }
    static var productShippingInfoBody: String { t("product_shipping_info_body") }
    static var productShippingInfoCd: String { t("product_shipping_info_cd") }
    static var productShippingInfoTitle: String { t("product_shipping_info_title") }
    static var productShipsFrom: String { t("product_ships_from") }
    static var productSize: String { t("product_size") }
    static var productSizeLabelShort: String { t("product_size_label_short") }
    static func productSocialLikes(_ a1: CVarArg) -> String {
        String(format: t("product_social_likes"), a1)
    }
    static func productSocialSaves(_ a1: CVarArg) -> String {
        String(format: t("product_social_saves"), a1)
    }
    static func productSocialViews(_ a1: CVarArg) -> String {
        String(format: t("product_social_views"), a1)
    }
    static var productSpecOrigin: String { t("product_spec_origin") }
    static var productStatLikes: String { t("product_stat_likes") }
    static var productStatSaves: String { t("product_stat_saves") }
    static var productStatViews: String { t("product_stat_views") }
    static var productStatusActiveCd: String { t("product_status_active_cd") }
    static var productTotalPayment: String { t("product_total_payment") }
    static var productVisitShop: String { t("product_visit_shop") }
    static func profileAccountEmail(_ a1: CVarArg) -> String {
        String(format: t("profile_account_email"), a1)
    }
    static func profileAccountPhone(_ a1: CVarArg) -> String {
        String(format: t("profile_account_phone"), a1)
    }
    static var profileActionShare: String { t("profile_action_share") }
    static var profileCdBriefScrollToTop: String { t("profile_cd_brief_scroll_to_top") }
    static var profileEdit: String { t("profile_edit") }
    static var profileEmptyInReviewSubtitle: String { t("profile_empty_in_review_subtitle") }
    static var profileEmptyInReviewTitle: String { t("profile_empty_in_review_title") }
    static var profileEmptyPinnedFooterInReview: String { t("profile_empty_pinned_footer_in_review") }
    static var profileEmptyPinnedFooterRejected: String { t("profile_empty_pinned_footer_rejected") }
    static var profileEmptyPinnedFooterSelling: String { t("profile_empty_pinned_footer_selling") }
    static var profileEmptyPinnedFooterSold: String { t("profile_empty_pinned_footer_sold") }
    static var profileEmptyPinnedFooterWishlist: String { t("profile_empty_pinned_footer_wishlist") }
    static var profileEmptyRejectedSubtitle: String { t("profile_empty_rejected_subtitle") }
    static var profileEmptyRejectedTitle: String { t("profile_empty_rejected_title") }
    static var profileEmptySellingSubtitle: String { t("profile_empty_selling_subtitle") }
    static var profileEmptySellingTitle: String { t("profile_empty_selling_title") }
    static var profileEmptySoldSubtitle: String { t("profile_empty_sold_subtitle") }
    static var profileEmptySoldTitle: String { t("profile_empty_sold_title") }
    static var profileEmptyWishlistSubtitle: String { t("profile_empty_wishlist_subtitle") }
    static var profileEmptyWishlistTitle: String { t("profile_empty_wishlist_title") }
    static var profileFastDelivery: String { t("profile_fast_delivery") }
    static var profileFollowers: String { t("profile_followers") }
    static var profileFollowersOpenCd: String { t("profile_followers_open_cd") }
    static var profileFollowing: String { t("profile_following") }
    static var profileFollowingOpenCd: String { t("profile_following_open_cd") }
    static func profileHeightCm(_ a1: CVarArg) -> String {
        String(format: t("profile_height_cm"), a1)
    }
    static var profileInviteFriendsSubtitle: String { t("profile_invite_friends_subtitle") }
    static var profileInviteFriendsTitle: String { t("profile_invite_friends_title") }
    static var profileLoadError: String { t("profile_load_error") }
    static var profileMeetingIdentityReverifyBody: String { t("profile_meeting_identity_reverify_body") }
    static func profileMeetingIdentityReverifySuspendedUntil(_ a1: CVarArg) -> String {
        String(format: t("profile_meeting_identity_reverify_suspended_until"), a1)
    }
    static var profileMeetingIdentityReverifyTitle: String { t("profile_meeting_identity_reverify_title") }
    static var profileMeetingNoShowWarning: String { t("profile_meeting_no_show_warning") }
    static func profilePreviewCaptionAll(_ a1: CVarArg) -> String {
        String(format: t("profile_preview_caption_all"), a1)
    }
    static func profilePreviewCaptionPartial(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("profile_preview_caption_partial"), a1, a2)
    }
    static var profilePreviewSlotEmptyCd: String { t("profile_preview_slot_empty_cd") }
    static var profilePreviewSlotEmptyLabel: String { t("profile_preview_slot_empty_label") }
    static var profileProducts: String { t("profile_products") }
    static var profileQuickActionsTitle: String { t("profile_quick_actions_title") }
    static func profileRatingFormat(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("profile_rating_format"), a1, a2)
    }
    static var profileRatingNoneSeller: String { t("profile_rating_none_seller") }
    static func profileRatingScoreOnly(_ a1: CVarArg) -> String {
        String(format: t("profile_rating_score_only"), a1)
    }
    static func profileReputationPoints(_ a1: CVarArg) -> String {
        String(format: t("profile_reputation_points"), a1)
    }
    static var profileScreenTitle: String { t("profile_screen_title") }
    static var profileSellerFollowCtaHint: String { t("profile_seller_follow_cta_hint") }
    static var profileSellerRatingPending: String { t("profile_seller_rating_pending") }
    static var profileSellerRatingPendingHint: String { t("profile_seller_rating_pending_hint") }
    static func profileSellerTrustReviewsCount(_ a1: CVarArg) -> String {
        String(format: t("profile_seller_trust_reviews_count"), a1)
    }
    static var profileSellerTrustSubtitleScoreOnly: String { t("profile_seller_trust_subtitle_score_only") }
    static var profileSetupChooseName: String { t("profile_setup_choose_name") }
    static var profileSetupComplete: String { t("profile_setup_complete") }
    static var profileSetupFillTypicalMeasurements: String { t("profile_setup_fill_typical_measurements") }
    static var profileSetupMeasurementChest: String { t("profile_setup_measurement_chest") }
    static var profileSetupMeasurementHem: String { t("profile_setup_measurement_hem") }
    static var profileSetupMeasurementLength: String { t("profile_setup_measurement_length") }
    static var profileSetupMeasurementOptionalNote: String { t("profile_setup_measurement_optional_note") }
    static func profileSetupMeasurementReferenceRange(_ a1: CVarArg) -> String {
        String(format: t("profile_setup_measurement_reference_range"), a1)
    }
    static var profileSetupMeasurementShoulders: String { t("profile_setup_measurement_shoulders") }
    static var profileSetupMeasurementSleeve: String { t("profile_setup_measurement_sleeve") }
    static var profileSetupMeasurementUnit: String { t("profile_setup_measurement_unit") }
    static var profileSetupMeasurementsGuidelineHint: String { t("profile_setup_measurements_guideline_hint") }
    static var profileSetupMeasurementsOptional: String { t("profile_setup_measurements_optional") }
    static var profileSetupReferenceSizeCustom: String { t("profile_setup_reference_size_custom") }
    static var profileSetupReferenceSizeCustomLabel: String { t("profile_setup_reference_size_custom_label") }
    static var profileSetupReferenceSizeHint: String { t("profile_setup_reference_size_hint") }
    static var profileSetupReferenceSizeLabel: String { t("profile_setup_reference_size_label") }
    static var profileSetupSizeChipRecommended: String { t("profile_setup_size_chip_recommended") }
    static func profileSetupSizeRecommendationAlternate(_ a1: CVarArg) -> String {
        String(format: t("profile_setup_size_recommendation_alternate"), a1)
    }
    static var profileSetupSizeRecommendationApply: String { t("profile_setup_size_recommendation_apply") }
    static func profileSetupSizeRecommendationBannerBoth(_ a1: CVarArg, _ a2: CVarArg, _ a3: CVarArg) -> String {
        String(format: t("profile_setup_size_recommendation_banner_both"), a1, a2, a3)
    }
    static func profileSetupSizeRecommendationBannerHeight(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("profile_setup_size_recommendation_banner_height"), a1, a2)
    }
    static func profileSetupSizeRecommendationBannerWeight(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("profile_setup_size_recommendation_banner_weight"), a1, a2)
    }
    static var profileSetupSizeRecommendationDismiss: String { t("profile_setup_size_recommendation_dismiss") }
    static var profileSetupSizeRecommendationTitle: String { t("profile_setup_size_recommendation_title") }
    static var profileSetupSizingChartMen: String { t("profile_setup_sizing_chart_men") }
    static var profileSetupSizingChartWomen: String { t("profile_setup_sizing_chart_women") }
    static var profileSetupSizingGuideBody: String { t("profile_setup_sizing_guide_body") }
    static func profileSetupSizingGuideTitle(_ a1: CVarArg) -> String {
        String(format: t("profile_setup_sizing_guide_title"), a1)
    }
    static var profileSetupSizingInlineHint: String { t("profile_setup_sizing_inline_hint") }
    static var profileSetupSizingSubtitle: String { t("profile_setup_sizing_subtitle") }
    static var profileSetupSizingTitle: String { t("profile_setup_sizing_title") }
    static var profileSetupSubtitle: String { t("profile_setup_subtitle") }
    static var profileSetupTitle: String { t("profile_setup_title") }
    static var profileSetupUnitCm: String { t("profile_setup_unit_cm") }
    static var profileSetupUnitIn: String { t("profile_setup_unit_in") }
    static var profileSetupUsernameAvailable: String { t("profile_setup_username_available") }
    static var profileSetupUsernameHint: String { t("profile_setup_username_hint") }
    static var profileSetupUsernameInvalid: String { t("profile_setup_username_invalid") }
    static var profileSetupUsernameRules: String { t("profile_setup_username_rules") }
    static var profileSetupUsernameTaken: String { t("profile_setup_username_taken") }
    static var profileShareShopSubtitle: String { t("profile_share_shop_subtitle") }
    static var profileShareShopTitle: String { t("profile_share_shop_title") }
    static var profileShippingAddresses: String { t("profile_shipping_addresses") }
    static func profileSizingRefChest(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("profile_sizing_ref_chest"), a1, a2)
    }
    static var profileSizingRefCompletedOnly: String { t("profile_sizing_ref_completed_only") }
    static var profileSizingRefEdit: String { t("profile_sizing_ref_edit") }
    static var profileSizingRefEmptyHint: String { t("profile_sizing_ref_empty_hint") }
    static func profileSizingRefHem(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("profile_sizing_ref_hem"), a1, a2)
    }
    static func profileSizingRefLength(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("profile_sizing_ref_length"), a1, a2)
    }
    static var profileSizingRefSeparator: String { t("profile_sizing_ref_separator") }
    static func profileSizingRefShoulders(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("profile_sizing_ref_shoulders"), a1, a2)
    }
    static func profileSizingRefSize(_ a1: CVarArg) -> String {
        String(format: t("profile_sizing_ref_size"), a1)
    }
    static func profileSizingRefSleeve(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("profile_sizing_ref_sleeve"), a1, a2)
    }
    static var profileSizingRefSubtitle: String { t("profile_sizing_ref_subtitle") }
    static var profileSizingRefTitle: String { t("profile_sizing_ref_title") }
    static var profileSizingRefUnitDefault: String { t("profile_sizing_ref_unit_default") }
    static var profileSlowLoadHint: String { t("profile_slow_load_hint") }
    static var profileSold: String { t("profile_sold") }
    static var profileTabInReview: String { t("profile_tab_in_review") }
    static var profileTabRejected: String { t("profile_tab_rejected") }
    static var profileTabSelling: String { t("profile_tab_selling") }
    static var profileTabSold: String { t("profile_tab_sold") }
    static var profileTabWishlist: String { t("profile_tab_wishlist") }
    static var profileVerifiedCd: String { t("profile_verified_cd") }
    static func profileWeightKg(_ a1: CVarArg) -> String {
        String(format: t("profile_weight_kg"), a1)
    }
    static var safeZoneCityHanoi: String { t("safe_zone_city_hanoi") }
    static var safeZoneCityHcm: String { t("safe_zone_city_hcm") }
    static var safeZoneEmptyHint: String { t("safe_zone_empty_hint") }
    static var safeZoneHubSubtitle: String { t("safe_zone_hub_subtitle") }
    static var safeZoneListTitle: String { t("safe_zone_list_title") }
    static var safeZoneLoadError: String { t("safe_zone_load_error") }
    static var safeZoneManualHint: String { t("safe_zone_manual_hint") }
    static var safeZoneRetry: String { t("safe_zone_retry") }
    static var safeZoneSelectedLabel: String { t("safe_zone_selected_label") }
    static var safeZoneSwitchManual: String { t("safe_zone_switch_manual") }
    static var safeZoneTabManual: String { t("safe_zone_tab_manual") }
    static var safeZoneTabPicker: String { t("safe_zone_tab_picker") }
    static var safeZoneTypeCafe: String { t("safe_zone_type_cafe") }
    static var safeZoneTypeConvenience: String { t("safe_zone_type_convenience") }
    static var safeZoneTypeMall: String { t("safe_zone_type_mall") }
    static var safeZoneTypeOther: String { t("safe_zone_type_other") }
    static var save: String { t("save") }
    static var searchLabel: String { t("search_label") }
    static var searchPlaceholder: String { t("search_placeholder") }
    static var sellerFocusAesthetics: String { t("seller_focus_aesthetics") }
    static var sellerFocusBrands: String { t("seller_focus_brands") }
    static var sellerFocusCategories: String { t("seller_focus_categories") }
    static var sellerFocusForbidden: String { t("seller_focus_forbidden") }
    static var sellerFocusSectionSubtitle: String { t("seller_focus_section_subtitle") }
    static var sellerFocusSectionTitle: String { t("seller_focus_section_title") }
    static var sellerFollowingStatusSubtitle: String { t("seller_following_status_subtitle") }
    static var sellerFollowingStatusTitle: String { t("seller_following_status_title") }
    static var sellerPackagesBackToList: String { t("seller_packages_back_to_list") }
    static var sellerPackagesBuyNow: String { t("seller_packages_buy_now") }
    static var sellerPackagesCheckoutDuration: String { t("seller_packages_checkout_duration") }
    static var sellerPackagesCheckoutFeatures: String { t("seller_packages_checkout_features") }
    static var sellerPackagesCheckoutLegal: String { t("seller_packages_checkout_legal") }
    static var sellerPackagesCheckoutSubtotal: String { t("seller_packages_checkout_subtotal") }
    static var sellerPackagesCheckoutTitle: String { t("seller_packages_checkout_title") }
    static var sellerPackagesCheckoutTotal: String { t("seller_packages_checkout_total") }
    static var sellerPackagesComingSoonBody: String { t("seller_packages_coming_soon_body") }
    static var sellerPackagesComingSoonCta: String { t("seller_packages_coming_soon_cta") }
    static var sellerPackagesComingSoonTitle: String { t("seller_packages_coming_soon_title") }
    static func sellerPackagesDurationDays(_ a1: CVarArg) -> String {
        String(format: t("seller_packages_duration_days"), a1)
    }
    static var sellerPackagesEmpty: String { t("seller_packages_empty") }
    static var sellerPackagesFeatureAuthenticity: String { t("seller_packages_feature_authenticity") }
    static var sellerPackagesFeatureExploreBoost: String { t("seller_packages_feature_explore_boost") }
    static var sellerPackagesFeatureFanpage: String { t("seller_packages_feature_fanpage") }
    static var sellerPackagesFeatureSocial: String { t("seller_packages_feature_social") }
    static var sellerPackagesLoadError: String { t("seller_packages_load_error") }
    static func sellerPackagesPayAmount(_ a1: CVarArg) -> String {
        String(format: t("seller_packages_pay_amount"), a1)
    }
    static func sellerPackagesPricePerMonth(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("seller_packages_price_per_month"), a1, a2)
    }
    static var sellerPackagesScreenSubtitle: String { t("seller_packages_screen_subtitle") }
    static var sellerPackagesScreenTitle: String { t("seller_packages_screen_title") }
    static var sessionExpiredMessage: String { t("session_expired_message") }
    static func settingsAboutEnvLine(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("settings_about_env_line"), a1, a2)
    }
    static var settingsAboutVersionLabel: String { t("settings_about_version_label") }
    static func settingsAboutVersionValue(_ a1: CVarArg, _ a2: CVarArg) -> String {
        String(format: t("settings_about_version_value"), a1, a2)
    }
    static var settingsFooterHint: String { t("settings_footer_hint") }
    static var settingsLanguage: String { t("settings_language") }
    static var settingsLanguageHint: String { t("settings_language_hint") }
    static var settingsRowChangePassword: String { t("settings_row_change_password") }
    static var settingsRowEditProfile: String { t("settings_row_edit_profile") }
    static var settingsRowNotificationSettings: String { t("settings_row_notification_settings") }
    static var settingsRowNotificationSettingsSub: String { t("settings_row_notification_settings_sub") }
    static var settingsRowOrders: String { t("settings_row_orders") }
    static var settingsRowRecommendationNotifications: String { t("settings_row_recommendation_notifications") }
    static var settingsRowRecommendationNotificationsSub: String { t("settings_row_recommendation_notifications_sub") }
    static var settingsRowShippingAddresses: String { t("settings_row_shipping_addresses") }
    static var settingsSectionAbout: String { t("settings_section_about") }
    static var settingsSectionAccount: String { t("settings_section_account") }
    static var settingsSectionDisplay: String { t("settings_section_display") }
    static var settingsSectionLanguage: String { t("settings_section_language") }
    static var settingsSectionNotifications: String { t("settings_section_notifications") }
    static var settingsSectionProfile: String { t("settings_section_profile") }
    static var settingsSectionShopping: String { t("settings_section_shopping") }
    static var settingsThemeDark: String { t("settings_theme_dark") }
    static var settingsThemeLight: String { t("settings_theme_light") }
    static var settingsThemeSystem: String { t("settings_theme_system") }
    static var settingsTitle: String { t("settings_title") }
    static var setupGateErrorBody: String { t("setup_gate_error_body") }
    static var setupGateErrorTitle: String { t("setup_gate_error_title") }
    static var setupGateRetry: String { t("setup_gate_retry") }
    static var setupGateSignOut: String { t("setup_gate_sign_out") }
    static var share: String { t("share") }
    static var shareInviteSuccess: String { t("share_invite_success") }
    static var shareListingSubject: String { t("share_listing_subject") }
    static var shareListingSuccess: String { t("share_listing_success") }
    static func shareListingText(_ a1: CVarArg, _ a2: CVarArg, _ a3: CVarArg) -> String {
        String(format: t("share_listing_text"), a1, a2, a3)
    }
    static func shareProfileSubject(_ a1: CVarArg) -> String {
        String(format: t("share_profile_subject"), a1)
    }
    static var shareProfileSuccess: String { t("share_profile_success") }
    static func shareProfileText(_ a1: CVarArg, _ a2: CVarArg, _ a3: CVarArg) -> String {
        String(format: t("share_profile_text"), a1, a2, a3)
    }
    static var shippingAddressRowUntitled: String { t("shipping_address_row_untitled") }
    static var splashFooterGenZ: String { t("splash_footer_gen_z") }
    static var splashLogoCd: String { t("splash_logo_cd") }
    static var splashWordmark: String { t("splash_wordmark") }
    static var unfollowAction: String { t("unfollow_action") }
    static var uxSurveySubmit: String { t("ux_survey_submit") }
    static var uxSurveyTextHint: String { t("ux_survey_text_hint") }
    static var uxSurveyThanksBody: String { t("ux_survey_thanks_body") }
    static var uxSurveyThanksTitle: String { t("ux_survey_thanks_title") }
    static var uxSurveyTitle: String { t("ux_survey_title") }
    static var waitingScreenEyebrow: String { t("waiting_screen_eyebrow") }
    static var waitingScreenHeadline: String { t("waiting_screen_headline") }
    static var waitingScreenLine2: String { t("waiting_screen_line_2") }
    static var waitingScreenLine3: String { t("waiting_screen_line_3") }
    static var waitingScreenStillLoading: String { t("waiting_screen_still_loading") }
    static var waitingScreenStillLoadingCd: String { t("waiting_screen_still_loading_cd") }
    static var welcomeBannerDialogAction: String { t("welcome_banner_dialog_action") }
    static var welcomeBannerDialogMessage: String { t("welcome_banner_dialog_message") }
    static var welcomeBannerDialogTitle: String { t("welcome_banner_dialog_title") }
}
