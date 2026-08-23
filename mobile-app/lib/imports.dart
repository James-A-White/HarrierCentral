// =============================================================================
// Harrier Central — global barrel file
// =============================================================================
// Most files in the app do `import 'package:harrier_central/imports.dart';`
// and rely on this barrel for SDK, third-party, and local symbols.
//
// Organisation:
//   1. Dart SDK
//   2. Third-party packages
//   3. Internal shared packages (ive_flutter_core / ive_flutter_core_mobile)
//   4. Local — package:harrier_central/... grouped by top-level folder
//
// Keep each section alphabetically sorted. When adding a new local file, drop
// the export into the matching folder group rather than at the end.
//
// NOTE: photo_manager is deliberately NOT re-exported here — its NotifyManager
// collides with get's NotifyManager. Import it directly in files that need it.
// =============================================================================

// -----------------------------------------------------------------------------
// 1. Dart SDK
// -----------------------------------------------------------------------------
export 'dart:async';
export 'dart:convert';
export 'dart:core';
export 'dart:io';
export 'dart:math';
export 'dart:typed_data';

// -----------------------------------------------------------------------------
// 2. Third-party packages
// -----------------------------------------------------------------------------
export 'package:auto_size_text/auto_size_text.dart';
export 'package:cached_network_image/cached_network_image.dart';
export 'package:device_info_plus/device_info_plus.dart';
export 'package:diacritic/diacritic.dart';
export 'package:firebase_core/firebase_core.dart';
export 'package:firebase_messaging/firebase_messaging.dart';
export 'package:flutter/foundation.dart';
export 'package:flutter/material.dart';
export 'package:flutter/rendering.dart';
export 'package:flutter/services.dart';
export 'package:flutter_avif/flutter_avif.dart';
export 'package:flutter_cache_manager/flutter_cache_manager.dart';
export 'package:flutter_chat_ui/flutter_chat_ui.dart';
export 'package:flutter_image_compress/flutter_image_compress.dart';
export 'package:flutter_linkify/flutter_linkify.dart';
export 'package:flutter_map/flutter_map.dart';
export 'package:flutter_map_marker_cluster_plus/flutter_map_marker_cluster_plus.dart';
export 'package:flutter_speed_dial/flutter_speed_dial.dart';
export 'package:flutter_spinkit/flutter_spinkit.dart';
export 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
export 'package:flutter_vector_icons/flutter_vector_icons.dart';
export 'package:freezed_annotation/freezed_annotation.dart';
export 'package:get/get.dart' hide HeaderValue, IterableExtensions, Response;
export 'package:get_storage/get_storage.dart';
export 'package:http/http.dart' hide MultipartFile;
export 'package:image_cropper/image_cropper.dart';
export 'package:image_picker/image_picker.dart';
export 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
export 'package:intro_slider/intro_slider.dart';
export 'package:json_annotation/json_annotation.dart';
export 'package:just_audio/just_audio.dart';
export 'package:keyboard_actions/keyboard_actions.dart';
export 'package:mobile_scanner/mobile_scanner.dart';
export 'package:package_info_plus/package_info_plus.dart';
export 'package:path_provider/path_provider.dart';
export 'package:permission_handler/permission_handler.dart';
export 'package:qr_flutter/qr_flutter.dart';
export 'package:screen_state/screen_state.dart';
export 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
export 'package:shared_preferences/shared_preferences.dart';
export 'package:sqflite/sqflite.dart';
export 'package:table_calendar/table_calendar.dart';
export 'package:url_launcher/url_launcher.dart';
export 'package:uuid/uuid.dart';

// -----------------------------------------------------------------------------
// 3. Internal shared packages (ive_flutter_core / ive_flutter_core_mobile)
// -----------------------------------------------------------------------------
export 'package:ive_flutter_core/util/core_utilities.dart';
export 'package:ive_flutter_core/widgets/circular_progress_indicator.dart';
export 'package:ive_flutter_core/widgets/fancy_divider.dart';
export 'package:ive_flutter_core/widgets/multiple_choice_popup.dart';
export 'package:ive_flutter_core/widgets/qr_popup.dart';
export 'package:ive_flutter_core/widgets/zoomable_image_page.dart';
export 'package:ive_flutter_core_mobile/database/base_service.dart';
export 'package:ive_flutter_core_mobile/database/database.dart';
export 'package:ive_flutter_core_mobile/database/migrations.dart';
export 'package:ive_flutter_core_mobile/util/connection.dart';

// -----------------------------------------------------------------------------
// 4. Local — package:harrier_central/...
// -----------------------------------------------------------------------------

// bindings
export 'package:harrier_central/bindings/initial_bindings.dart';

// controllers
export 'package:harrier_central/controllers/run_tracker_map_controller.dart';

// data/hc3_services
export 'package:harrier_central/data/hc3_services/cities/cities_model_ns.dart';
export 'package:harrier_central/data/hc3_services/cities/cities_service.dart';
export 'package:harrier_central/data/hc3_services/countries/countries_model_ns.dart';
export 'package:harrier_central/data/hc3_services/countries/countries_service.dart';
export 'package:harrier_central/data/hc3_services/events/event_model_ns.dart';
export 'package:harrier_central/data/hc3_services/events/events_service.dart';
export 'package:harrier_central/data/hc3_services/hasher_event_map/hasher_event_map_model_ns.dart';
export 'package:harrier_central/data/hc3_services/hasher_event_map/hasher_event_map_service.dart';
export 'package:harrier_central/data/hc3_services/hasher_kennel_map/hasher_kennel_map_model_ns.dart';
export 'package:harrier_central/data/hc3_services/hasher_kennel_map/hasher_kennel_map_service.dart';
export 'package:harrier_central/data/hc3_services/hashers/hashers_model_ns.dart';
export 'package:harrier_central/data/hc3_services/hashers/hashers_service.dart';
export 'package:harrier_central/data/hc3_services/kennels/kennels_model_ns.dart';
export 'package:harrier_central/data/hc3_services/kennels/kennels_service.dart';
export 'package:harrier_central/data/hc3_services/payments/payments_model_ns.dart';
export 'package:harrier_central/data/hc3_services/payments/payments_service.dart';
export 'package:harrier_central/data/hc3_services/receipts/receipts_model_ns.dart';
export 'package:harrier_central/data/hc3_services/receipts/receipts_service.dart';
export 'package:harrier_central/data/hc3_services/regions/regions_model_ns.dart';
export 'package:harrier_central/data/hc3_services/regions/regions_service.dart';
export 'package:harrier_central/data/hc3_services/songs/songs_model_ns.dart';
export 'package:harrier_central/data/hc3_services/songs/songs_service.dart';
export 'package:harrier_central/data/hc3_services/sync_event_admin_service.dart';
export 'package:harrier_central/data/hc3_services/sync_kennel_admin_service.dart';
export 'package:harrier_central/data/hc3_services/sync_user_data_service.dart';

// data/models
export 'package:harrier_central/data/models/approve_login/approve_login_model.dart';
export 'package:harrier_central/data/models/are_we_at_run/are_we_at_run_model.dart';
export 'package:harrier_central/data/models/check_in_pack/check_in_pack_model.dart';
export 'package:harrier_central/data/models/db_error/db_error_model.dart';
export 'package:harrier_central/data/models/down_down_model.dart';
export 'package:harrier_central/data/models/guest/guest_run_model.dart';
export 'package:harrier_central/data/models/hash_trash_model.dart';
export 'package:harrier_central/data/models/kennel_member_results/kennel_member_results_model.dart';
export 'package:harrier_central/data/models/lite_event/lite_event_model.dart';
export 'package:harrier_central/data/models/payment_query_extensions/payment_query_extensions_model.dart';
export 'package:harrier_central/data/models/run_history/run_history_model.dart';
export 'package:harrier_central/data/models/run_history/run_history_queries.dart';
export 'package:harrier_central/data/models/run_photo_model.dart';
export 'package:harrier_central/data/models/run_query_extensions/run_query_extensions_model.dart';
export 'package:harrier_central/data/models/service_result.dart';
export 'package:harrier_central/data/models/single_result/single_result_model.dart';
export 'package:harrier_central/data/models/trail_slot/trail_slot.dart';
export 'package:harrier_central/data/models/trail_type/trail_type.dart';
export 'package:harrier_central/data/models/user_event_location/user_event_location.dart';
export 'package:harrier_central/data/models/user_positions/user_positions.dart';
export 'package:harrier_central/data/models/user_run_history/user_run_history_model.dart';

// data/repository
export 'package:harrier_central/data/repository/data_repository.dart';

// data/services
export 'package:harrier_central/data/services/app_boot_service.dart';
export 'package:harrier_central/data/services/approve_login_service.dart';
export 'package:harrier_central/data/services/authenticate_web_portal_service.dart';
export 'package:harrier_central/data/services/authorize_device_service.dart';
export 'package:harrier_central/data/services/email_reports_service.dart';
export 'package:harrier_central/data/services/find_my_account_service.dart';
export 'package:harrier_central/data/services/get_reset_code_service.dart';
export 'package:harrier_central/data/services/guest_runs_service.dart';
export 'package:harrier_central/data/services/kennel_photo_service.dart';
export 'package:harrier_central/data/services/kennel_photo_upload_queue.dart';
export 'package:harrier_central/data/services/run_content_service.dart';
export 'package:harrier_central/data/services/service_common.dart';
export 'package:harrier_central/data/services/song_session_service.dart';

// database
export 'package:harrier_central/database/common_queries.dart';
export 'package:harrier_central/database/db_errors.dart';
export 'package:harrier_central/database/notifications_table.dart';
export 'package:harrier_central/database/query_kennels.dart';
export 'package:harrier_central/database/query_runs.dart';
export 'package:harrier_central/database/query_users.dart';
export 'package:harrier_central/database/tables.dart';

// pages/detail_pages
export 'package:harrier_central/pages/detail_pages/chat/chat_page.dart';
export 'package:harrier_central/pages/detail_pages/chat/chat_page_controller.dart';
export 'package:harrier_central/pages/detail_pages/kennel_admin_controller.dart';
export 'package:harrier_central/pages/detail_pages/kennel_admin_main.dart';
export 'package:harrier_central/pages/detail_pages/run_details_page.dart';

// pages/guest
export 'package:harrier_central/pages/guest/guest_discovery_controller.dart';
export 'package:harrier_central/pages/guest/guest_discovery_page.dart';
export 'package:harrier_central/pages/guest/guest_run_detail_page.dart';

// pages/history_sub_pages
export 'package:harrier_central/pages/history_sub_pages/user_country_history_list_page.dart';
export 'package:harrier_central/pages/history_sub_pages/user_run_history_list_page.dart';

// pages/init
export 'package:harrier_central/pages/init/account_question_page.dart';
export 'package:harrier_central/pages/init/app_entry_page.dart';
export 'package:harrier_central/pages/init/avatar_icons_page.dart';
export 'package:harrier_central/pages/init/choose_profile_image.dart';
export 'package:harrier_central/pages/init/create_new_account.dart';
export 'package:harrier_central/pages/init/email_not_received_page.dart';
export 'package:harrier_central/pages/init/find_my_account_page.dart';
export 'package:harrier_central/pages/init/hasher_search_results_page.dart';
export 'package:harrier_central/pages/init/intro_slider.dart';
export 'package:harrier_central/pages/init/new_account.dart';
export 'package:harrier_central/pages/init/permissions_slider.dart';
export 'package:harrier_central/pages/init/third_party_login.dart';
export 'package:harrier_central/pages/init/use_invite_code_page.dart';

// pages/kennel_admin
export 'package:harrier_central/pages/kennel_admin/app_access_page.dart';
export 'package:harrier_central/pages/kennel_admin/filter_events_page.dart';
export 'package:harrier_central/pages/kennel_admin/hash_flash_approval_page.dart';
export 'package:harrier_central/pages/kennel_admin/kennel_members.dart';
export 'package:harrier_central/pages/kennel_admin/mismanagement_roles_page.dart';
export 'package:harrier_central/pages/kennel_admin/run_number_popup.dart';

// pages/live_run_pages
export 'package:harrier_central/pages/live_run_pages/live_run_service.dart';
export 'package:harrier_central/pages/live_run_pages/live_run_shell.dart';

// pages/menu_pages
export 'package:harrier_central/pages/menu_pages/faq_page.dart';
export 'package:harrier_central/pages/menu_pages/get_reset_code_popup.dart';
export 'package:harrier_central/pages/menu_pages/hasher_profile_page.dart';
export 'package:harrier_central/pages/menu_pages/imprint_page.dart';
export 'package:harrier_central/pages/menu_pages/legal_page.dart';
export 'package:harrier_central/pages/menu_pages/privacy_policy_page.dart';
export 'package:harrier_central/widgets/map_overlay_button.dart';
export 'package:harrier_central/widgets/rose_canvas.dart';
export 'package:harrier_central/pages/menu_pages/settings_page.dart';
export 'package:harrier_central/pages/menu_pages/support_page.dart';

// pages/misc_pages
export 'package:harrier_central/pages/misc_pages/generic_widget_page.dart';
export 'package:harrier_central/pages/misc_pages/hash_run_art_gallery_page.dart';

// pages/run_admin
export 'package:harrier_central/pages/run_admin/check_in_pack_page/check_in_pack_page.dart';
export 'package:harrier_central/pages/run_admin/check_in_pack_page/check_in_pack_page_controller.dart';
export 'package:harrier_central/pages/run_admin/check_in_scanner_controller.dart';
export 'package:harrier_central/pages/run_admin/check_in_scanner_page.dart';
export 'package:harrier_central/pages/run_admin/create_new_event_popup.dart';
export 'package:harrier_central/pages/run_admin/drinks_list.dart';
export 'package:harrier_central/pages/run_admin/edit_run_details.dart';
export 'package:harrier_central/pages/run_admin/event_qr_code_page.dart';
export 'package:harrier_central/pages/run_admin/find_hasher_page.dart';
export 'package:harrier_central/pages/run_admin/other_payment_popup.dart';
export 'package:harrier_central/pages/run_admin/payment_popup.dart';
export 'package:harrier_central/pages/run_admin/payment_report.dart';
export 'package:harrier_central/pages/run_admin/receipt_detail_page.dart';
export 'package:harrier_central/pages/run_admin/receipts_page.dart';
export 'package:harrier_central/pages/run_admin/run_admin_controller.dart';
export 'package:harrier_central/pages/run_admin/run_admin_main.dart';

// pages/top_level
export 'package:harrier_central/pages/top_level/future_run_list_page/future_run_list_controller.dart';
export 'package:harrier_central/pages/top_level/future_run_list_page/future_run_list_page.dart';
export 'package:harrier_central/pages/top_level/history_list_page.dart';
export 'package:harrier_central/pages/top_level/kennel_list_controller.dart';
export 'package:harrier_central/pages/top_level/kennel_list_page.dart';
export 'package:harrier_central/pages/top_level/main_navigation_page/main_navigation_page.dart';
export 'package:harrier_central/pages/top_level/main_navigation_page/main_navigation_page_controller.dart';
export 'package:harrier_central/pages/top_level/run_locations.dart';
export 'package:harrier_central/pages/top_level/run_locations_controller.dart';
export 'package:harrier_central/pages/top_level/songs_page.dart';
export 'package:harrier_central/pages/top_level/songs_page_controller.dart';
export 'package:harrier_central/pages/shared/haberdashery_sale_sheet.dart';
export 'package:harrier_central/pages/shared/membership_charge_sheet.dart';
export 'package:harrier_central/pages/top_level/user_qr_code_page.dart';

// services
export 'package:harrier_central/services/connectivity_service.dart';
export 'package:harrier_central/services/data_change_service.dart';
export 'package:harrier_central/services/location_service/location_service.dart';
export 'package:harrier_central/services/watch_bridge_service.dart';
export 'package:harrier_central/services/notification_service.dart';
export 'package:harrier_central/services/services_init.dart';

// types
export 'package:harrier_central/types/typedefs.dart';

// util
export 'package:harrier_central/util/bank_transfer_qr.dart';
export 'package:harrier_central/util/boot_logger.dart';
export 'package:harrier_central/util/constants.dart';
export 'package:harrier_central/util/enums.dart';
export 'package:harrier_central/util/get_positions.dart';
export 'package:harrier_central/util/delete_positions.dart';
export 'package:harrier_central/util/end_event_tracking.dart';
export 'package:harrier_central/util/avatar.dart';
export 'package:harrier_central/util/kennel_permissions.dart';
export 'package:harrier_central/util/async_serializer.dart';
export 'package:harrier_central/util/membership_status.dart';
export 'package:harrier_central/widgets/packtrack_trim_overlay.dart';
export 'package:harrier_central/widgets/packtrack_fullscreen_map.dart';
export 'package:harrier_central/util/get_storage.dart';
export 'package:harrier_central/util/globals.dart';
export 'package:harrier_central/util/routes.dart';
export 'package:harrier_central/util/safe_set_state.dart';
export 'package:harrier_central/util/secure_credentials.dart';
export 'package:harrier_central/util/secure_storage.dart';
export 'package:harrier_central/util/styles.dart';
export 'package:harrier_central/util/text_styles.dart';
export 'package:harrier_central/util/update_ids.dart';
export 'package:harrier_central/util/utilities_null_safe.dart';
export 'package:harrier_central/util/uuid_utils.dart';

// widgets
export 'package:harrier_central/widgets/add_virgin_visitor_popup.dart';
export 'package:harrier_central/widgets/android_safe_area.dart';
export 'package:harrier_central/widgets/app_scaffold.dart';
export 'package:harrier_central/widgets/chat_strip_widget.dart';
export 'package:harrier_central/widgets/check_in_filter_cell.dart';
export 'package:harrier_central/widgets/circular_progress_indicator.dart';
export 'package:harrier_central/widgets/confirm_auto_checkin_popup.dart';
export 'package:harrier_central/widgets/connected_widget.dart';
export 'package:harrier_central/widgets/country_run_history_count_list_item.dart';
export 'package:harrier_central/widgets/editor_map.dart';
export 'package:harrier_central/widgets/email_popup.dart';
export 'package:harrier_central/widgets/filter_event_list_item.dart';
export 'package:harrier_central/widgets/get_point_label.dart';
export 'package:harrier_central/widgets/guest_action_bar.dart';
export 'package:harrier_central/widgets/kennel_filter_cell.dart';
export 'package:harrier_central/widgets/kennel_list_item.dart';
export 'package:harrier_central/widgets/kennel_logo.dart';
export 'package:harrier_central/widgets/kennel_member_list_item.dart';
export 'package:harrier_central/widgets/kennel_run_history_count_list_item.dart';
export 'package:harrier_central/widgets/leaderboard.dart';
export 'package:harrier_central/widgets/map_photo_page.dart';
export 'package:harrier_central/widgets/map_snackbar.dart';
export 'package:harrier_central/widgets/multiple_choice_popup.dart';
export 'package:harrier_central/widgets/offline_mode_ribbon.dart';
export 'package:harrier_central/widgets/payment_icons.dart';
export 'package:harrier_central/widgets/payment_report_list_item.dart';
export 'package:harrier_central/widgets/payment_snackbar.dart';
export 'package:harrier_central/widgets/photo_action_buttons.dart';
export 'package:harrier_central/widgets/pill_arrow_buttons.dart';
export 'package:harrier_central/widgets/profile_photo.dart';
export 'package:harrier_central/widgets/qr_group.dart';
export 'package:harrier_central/widgets/restart_widget.dart';
export 'package:harrier_central/widgets/run_details.dart';
export 'package:harrier_central/widgets/run_list_item.dart';
export 'package:harrier_central/widgets/run_qr_share_section.dart';
export 'package:harrier_central/widgets/run_tabs.dart';
export 'package:harrier_central/widgets/run_tracker_map.dart';
export 'package:harrier_central/widgets/style_for_connected.dart';
export 'package:harrier_central/widgets/text_scale_factor_clamper.dart';
export 'package:harrier_central/widgets/user_details_ui.dart';
export 'package:harrier_central/widgets/user_event_list_item.dart';
export 'package:harrier_central/widgets/zoomable_image.dart';

// app entry point
export 'package:harrier_central/main.dart';
