import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quotely_flutter_app/main.dart';

import '../../layouts/main_layout.dart';

const List<String> kFontFamilies = [
  'Fira Code',
  'Roboto',
  'Open Sans',
  'Lato',
  'Montserrat',
  'Oswald',
  'Source Sans 3',
  'Slabo 27px', // The font name to use for "Slabo 27px/13px"
  'Raleway',
  'PT Sans',
  'Merriweather',
  'Poppins',
  'Nunito',
  'Ubuntu',
];

class AppearanceScreen extends StatefulWidget {
  static const kRouteName = '/appearance';
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  @override
  Widget build(BuildContext context) {
    // Get the current state from the QuotelyApp widget
    final quotelyState = QuotelyApp.of(context);
    final theme = Theme.of(context);

    return MainLayout(
      title: 'Appearance',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Section 1: Theme Mode ---
            _buildSectionHeader(context, "Theme Mode"),
            const SizedBox(height: 8),
            _buildSectionContainer(
              context,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                // A modern segmented button for theme selection
                child: SegmentedButton<ThemeMode>(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainer,
                    ),
                    side: WidgetStateProperty.resolveWith(
                      (states) => states.contains(WidgetState.selected)
                          ? BorderSide.none
                          : BorderSide(
                              color: theme.colorScheme.primary,
                              width: 1,
                            ),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined)),
                    // ButtonSegment(
                    //     value: ThemeMode.system,
                    //     label: Text('System'),
                    //     icon: Icon(Icons.brightness_auto_outlined)),
                    ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_outlined)),
                  ],
                  selected: {quotelyState.themeMode},
                  onSelectionChanged: (newSelection) {
                    quotelyState.changeTheme(newSelection.first);
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- Section 2: Color Palette ---
            _buildSectionHeader(context, "Color Palette"),
            const SizedBox(height: 8),
            _buildSectionContainer(
              context,
              // --- UPDATED: Replaced Wrap with a SizedBox and horizontal ListView ---
              child: SizedBox(
                // Set a fixed height for the horizontal list
                height: 70,
                child: ListView.builder(
                  // Set the scroll direction to horizontal
                  scrollDirection: Axis.horizontal,
                  // Add some padding to the start and end of the list
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                  itemCount: FlexScheme.values.length,
                  itemBuilder: (context, index) {
                    final scheme = FlexScheme.values[index];
                    final isSelected = quotelyState.flexScheme == scheme;

                    // Add padding between the color swatches
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: GestureDetector(
                        onTap: () => quotelyState.changeFlexScheme(scheme),
                        child: Tooltip(
                          // Added a tooltip to show the color name on long press
                          message: scheme.name,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: FlexThemeData.light(scheme: scheme)
                                  .primaryColor,
                              border: isSelected
                                  ? Border.all(
                                      color: theme.colorScheme.onSurface,
                                      width: 3)
                                  : Border.all(
                                      color: theme.dividerColor, width: 0.5),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- ADDED: New Section for Typography ---
            const SizedBox(height: 24),
            _buildSectionHeader(context, "Typography"),
            const SizedBox(height: 8),
            _buildSectionContainer(
              context,
              child: ListTile(
                contentPadding: const EdgeInsets.only(
                    left: 16, right: 10, top: 4, bottom: 4),
                leading: const Icon(Icons.font_download_outlined),
                title: const Text('App Font',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                // A dropdown button to select the font
                trailing: DropdownButton<String>(
                  value: quotelyState.fontFamily,
                  underline:
                      const SizedBox.shrink(), // Hides the default underline
                  icon: const Icon(Icons.arrow_drop_down_rounded),
                  items: kFontFamilies.map((String fontName) {
                    return DropdownMenuItem<String>(
                      value: fontName,
                      // The text is styled with the font itself for a live preview!
                      child: Text(
                        fontName,
                        style: GoogleFonts.getFont(fontName),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newFont) {
                    if (newFont != null) {
                      quotelyState.changeFontFamily(newFont);
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- Section 3: Layout Preferences ---
            _buildSectionHeader(context, "Layout"),
            const SizedBox(height: 8),
            _buildSectionContainer(
              context,
              child: SwitchListTile(
                title: const Text('Default to Grid View',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Applies to Home & Favorites screens'),
                value: quotelyState.isGridView,
                onChanged: (_) => setState(() {
                  quotelyState.toggleGridViewEnabled();
                }),
                secondary: const Icon(Icons.grid_view_outlined),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
    );
  }

  Widget _buildSectionContainer(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
