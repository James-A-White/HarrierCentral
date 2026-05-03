import 'package:hcportal/imports.dart';

// ---------------------------------------------------------------------------
// Tab Type Enum
// ---------------------------------------------------------------------------

enum KennelWebsiteTabType {
  identity(
    key: 'identity',
    title: 'Identity',
    description: 'Control whether your website is publicly accessible and '
        'configure its URL shortcode and custom domain.\n\n'
        'Enable your website here when you are ready to go live.',
    icon: MaterialCommunityIcons.web,
    isTabLockable: true,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  appearance(
    key: 'appearance',
    title: 'Appearance',
    description: 'Set the visual theme for your kennel website.\n\n'
        'Choose between dark and light mode, pick your primary brand colour, '
        'and fine-tune text and surface colours for a polished look.',
    icon: FontAwesome5Solid.paint_brush,
    isTabLockable: true,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  images(
    key: 'images',
    title: 'Images',
    description: 'Upload images for your kennel website.\n\n'
        'The banner image appears as the hero at the top of your page. '
        'The background image is shown behind your content. '
        'The OG image is used when your page is shared on social media '
        '(recommended: 1200×630 px).',
    icon: FontAwesome5Solid.images,
    isTabLockable: true,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  content(
    key: 'content',
    title: 'Content',
    description: 'Set the main text content for your kennel website.\n\n'
        'The title is your kennel\'s display name shown in the hero. '
        'The tagline is a short strapline. '
        'The welcome text is your homepage introduction.',
    icon: FontAwesome5Solid.align_left,
    isTabLockable: true,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  seo(
    key: 'seo',
    title: 'SEO',
    description: 'Optimise your kennel website for search engines.\n\n'
        'The SEO title appears in browser tabs and search results (max 60 characters). '
        'The description is shown in search result snippets (max 155 characters).',
    icon: FontAwesome5Solid.search,
    isTabLockable: true,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: true,
  ),

  advanced(
    key: 'advanced',
    title: 'Advanced',
    description: 'Advanced website content managed as structured JSON.\n\n'
        'Use these fields to configure the mis-management page, custom '
        'navigation menus, and contact details. Leave empty to use defaults.',
    icon: FontAwesome5Solid.code,
    isTabLockable: true,
    hasCustomTabStatusFunction: false,
    showTabInSubmitSummary: false,
  );

  const KennelWebsiteTabType({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.isTabLockable,
    required this.hasCustomTabStatusFunction,
    required this.showTabInSubmitSummary,
  });

  final String key;
  final String title;
  final String description;
  final IconData icon;
  final bool isTabLockable;
  final bool hasCustomTabStatusFunction;
  final bool showTabInSubmitSummary;
}

// ---------------------------------------------------------------------------
// Field Enums
// ---------------------------------------------------------------------------

enum KennelWebsiteIdentityField {
  enabled,
  urlShortcode,
  customDomain,
}

enum KennelWebsiteAppearanceField {
  themeMode,
  primaryColor,
  accentColor,
  menuBackgroundColor,
  menuTextColor,
  scrollBlur,
  titleTextColor,
  bodyTextColor,
  textMutedColor,
  cardBackgroundColor,
}

enum KennelWebsiteImagesField {
  bannerImage,
  backgroundImage,
  ogImageUrl,
}

enum KennelWebsiteContentField {
  titleText,
  tagline,
  welcomeText,
}

enum KennelWebsiteSeoField {
  seoTitle,
  seoDescription,
}

enum KennelWebsiteAdvancedField {
  mismanagementDescription,
  mismanagementJson,
  extraMenusJson,
  contactDetailsJson,
}
