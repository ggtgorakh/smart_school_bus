---
name: SecurePath Mobility
colors:
  surface: '#f7fafc'
  surface-dim: '#d7dadc'
  surface-bright: '#f7fafc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f4f6'
  surface-container: '#ebeef0'
  surface-container-high: '#e5e9eb'
  surface-container-highest: '#e0e3e5'
  on-surface: '#181c1e'
  on-surface-variant: '#424751'
  inverse-surface: '#2d3133'
  inverse-on-surface: '#eef1f3'
  outline: '#737782'
  outline-variant: '#c3c6d2'
  surface-tint: '#2e5ea5'
  primary: '#003874'
  on-primary: '#ffffff'
  primary-container: '#1a4f95'
  on-primary-container: '#a3c3ff'
  inverse-primary: '#aac7ff'
  secondary: '#994700'
  on-secondary: '#ffffff'
  secondary-container: '#fb7800'
  on-secondary-container: '#592600'
  tertiary: '#004044'
  on-tertiary: '#ffffff'
  tertiary-container: '#00595f'
  on-tertiary-container: '#58d3de'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d6e3ff'
  primary-fixed-dim: '#aac7ff'
  on-primary-fixed: '#001b3e'
  on-primary-fixed-variant: '#08458b'
  secondary-fixed: '#ffdbc8'
  secondary-fixed-dim: '#ffb68b'
  on-secondary-fixed: '#321200'
  on-secondary-fixed-variant: '#753400'
  tertiary-fixed: '#7df4ff'
  tertiary-fixed-dim: '#5dd8e2'
  on-tertiary-fixed: '#002022'
  on-tertiary-fixed-variant: '#004f54'
  background: '#f7fafc'
  on-background: '#181c1e'
  surface-variant: '#e0e3e5'
  safety-blue: '#1A4F95'
  alert-orange: '#FF7A00'
  success-green: '#2D8A29'
  surface-gray: '#F4F7F9'
  text-main: '#121C2D'
typography:
  headline-lg:
    fontFamily: Manrope
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-md:
    fontFamily: Manrope
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Manrope
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  headline-lg-mobile:
    fontFamily: Manrope
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  margin-mobile: 16px
  gutter-mobile: 12px
  card-padding: 16px
  stack-gap: 12px
---

## Brand & Style
The brand personality is anchored in **trust, vigilance, and efficiency**. As a tool for school bus management, the UI must prioritize the safety of students and the peace of mind of parents and administrators. 

The design style is **Corporate / Modern** with a focus on **utility and clarity**. It utilizes high-contrast color pairings and generous touch targets to ensure usability in high-stress or moving environments (like a bus or a busy school zone). Visual elements are organized into a clear hierarchy that emphasizes real-time data—bus telemetry, student check-ins, and route status—without overwhelming the user.

## Colors
The palette is centered on **Safety Blue**, a deep, authoritative navy that evokes professional security and reliability. **Vibrant Safety Orange** is used strategically as a functional accent for alerts, warnings, and critical call-to-actions, ensuring they are immediately visible against the blue.

- **Primary (Safety Blue):** Used for headers, primary actions, and branding.
- **Secondary (Safety Orange):** Reserved for high-priority alerts, bus stop markers, and active status indicators.
- **Neutral:** A cool-toned light gray is used for backgrounds to reduce eye strain and provide a clean canvas for the elevated data cards.

## Typography
This design system utilizes **Manrope** for headlines to provide a modern, balanced, and professional feel. **Inter** is used for all body text and labels due to its exceptional legibility on mobile screens, particularly for data-heavy views like student rosters or ETA lists.

Weights are kept robust—primarily 400 and 600—to ensure text remains readable even in outdoor glare or low-light conditions. Letter spacing is slightly increased on labels for better scanning at smaller sizes.

## Layout & Spacing
The layout follows a **fluid grid** model optimized for mobile devices. It utilizes a 4-column structure for mobile screens with 16px side margins.

- **Rhythm:** An 8px base unit drives all spacing decisions.
- **Data Density:** Elements are spaced using a "Comfortable" density (12px to 16px gaps) to prevent accidental taps, which is critical for drivers or busy parents.
- **Reflow:** On larger tablet screens, the layout shifts to a 2-column card grid to maximize the visibility of live map telemetry alongside the student list.

## Elevation & Depth
Depth is communicated through **Tonal Layers** and **Ambient Shadows**. 

The background is a flat neutral gray (`#F4F7F9`). UI elements, specifically "Student Detail Cards," are placed on white elevated surfaces. These surfaces use a very subtle, diffused shadow (Blur: 12px, Y: 4px, Opacity: 6%) tinted with the primary blue to create a sense of height without adding visual noise. 

Interactive elements like floating action buttons (FABs) for "Emergency Contact" use a higher elevation tier to signify their critical importance.

## Shapes
A **Rounded (0.5rem)** approach is applied to soften the industrial nature of the app and make it feel approachable for families. 

- **Cards & Inputs:** Use the standard `rounded` (8px) radius.
- **Status Pills:** Use `rounded-xl` (24px) to create a distinct shape for quick identification (e.g., "On Board", "At Home").
- **Icons:** Should be encased in circular or heavily rounded containers to maintain the friendly yet professional aesthetic.

## Components

- **Student Cards:** The cornerstone of the app. Elevated white containers with a 16px padding. They feature a 48px rounded avatar, a bold name headline, and a colored status chip (Orange for "Alert", Green for "Safe").
- **Primary Buttons:** Solid Safety Blue with white text, utilizing the full width of the mobile container for ease of use.
- **Status Chips:** Small, high-contrast badges used to track student transitions. Use semantic colors: Orange for delays, Blue for in-progress, and Green for completion.
- **Telemetry Indicators:** Specialized data points (e.g., speed, fuel, temperature) displayed with clean line icons and bold numerical values.
- **Navigation:** A streamlined bottom navigation bar with clear, labeled icons for "Map", "Students", "Notifications", and "Profile".
- **Inputs:** Outlined fields with a 1px border that thickens to 2px in the primary color when active, ensuring clear focus states for data entry.