# GoFit.ai Design System

## Overview

The GoFit.ai app features a modern, fun, and elegant design with smooth animations throughout. This document outlines the design system used across the entire application.

## Design Principles

1. **Fun & Engaging** - Interactive elements that make health tracking enjoyable
2. **Elegant** - Clean, modern UI with thoughtful spacing and typography
3. **Smooth Animations** - Spring-based animations for natural, fluid motion
4. **Consistent** - Unified design language across all screens
5. **Accessible** - Clear hierarchy and readable text

## Color Palette

### Primary Colors
- **Teal Green**: `#33B3A0` (RGB: 0.2, 0.7, 0.6)
  - Primary brand color
  - Used for buttons, accents, and key UI elements
  
- **Teal Light**: `#4DCCC8` (RGB: 0.3, 0.8, 0.7)
  - Gradient companion
  - Used in gradients and highlights

- **Teal Dark**: `#26998A` (RGB: 0.15, 0.6, 0.5)
  - Darker variant
  - Used for pressed states

### Accent Colors
- **Sunrise Yellow**: `#FFD700` (RGB: 1.0, 0.84, 0.0)
  - Premium features
  - Highlights and badges

### Category Colors
- **Calories**: Orange
- **Protein**: Blue
- **Carbs**: Purple
- **Fat**: Pink
- **Water**: Blue
- **Steps**: Green
- **Heart Rate**: Red

## Typography

All fonts use the `.rounded` design for a friendly, approachable feel:

- **Large Title**: 34pt, Bold
- **Title**: 28pt, Bold
- **Title 2**: 22pt, Semibold
- **Headline**: 17pt, Semibold
- **Body**: 17pt, Regular
- **Subheadline**: 15pt, Regular
- **Caption**: 12pt, Regular

## Spacing System

Consistent spacing scale:
- **XS**: 4pt
- **SM**: 8pt
- **MD**: 16pt
- **LG**: 24pt
- **XL**: 32pt

## Corner Radius

- **Small**: 8pt
- **Medium**: 12pt
- **Large**: 16pt
- **XLarge**: 24pt

## Shadows

Three shadow levels for depth:
- **Small**: 4pt radius, 0.1 opacity
- **Medium**: 8pt radius, 0.15 opacity
- **Large**: 12pt radius, 0.2 opacity

## Animations

### Spring Animations
- **Standard**: Response 0.5s, Damping 0.7
- **Fast**: Response 0.3s, Damping 0.6
- **Slow**: Response 0.7s, Damping 0.8

### Animation Principles
1. **Spring-based** - Natural, bouncy feel
2. **Staggered** - Sequential animations for lists
3. **Scale on Press** - 0.95 scale for button feedback
4. **Smooth Transitions** - Fade and slide for navigation

## Components

### Cards
- Rounded corners (16pt)
- Subtle shadows
- Padding: 24pt
- Background: System background or custom color

### Buttons
- Primary: Gradient background with shadow
- Secondary: Outlined or filled with opacity
- Scale animation on press (0.95)
- Minimum touch target: 44x44pt

### Icons
- SF Symbols with consistent sizing
- Color-coded by category
- Circular backgrounds for emphasis

### Progress Indicators
- Animated progress bars
- Circular progress for timers
- Smooth transitions

## Screen-Specific Design

### Home Dashboard
- Welcome header with personalized greeting
- Large, prominent stats cards
- Quick action buttons with gradients
- Health metrics in grid layout
- Water intake with animated progress bar
- AI recommendations card

### Profile Screen
- Circular avatar with gradient
- Quick stats row
- Organized settings sections
- Smooth sheet presentations
- Loading states with overlays

### Fasting View
- Large circular timer
- Animated progress ring
- Preset window buttons
- Streak counter
- Clear action buttons

### Paywall
- Crown icon header
- Feature list with icons
- Plan selection cards
- Prominent CTA button
- Terms and conditions

### Meal History
- Expandable meal cards
- Color-coded macros
- Empty state illustration
- Smooth expand/collapse animations

## Interaction Patterns

### Tap Feedback
- Scale to 0.95 on press
- Opacity change to 0.8
- Spring animation

### Navigation
- Smooth sheet presentations
- Tab transitions with icon changes
- Back button with color accent

### Loading States
- Progress indicators
- Shimmer effects (optional)
- Skeleton screens (future)

## Accessibility

- Minimum touch targets: 44x44pt
- High contrast text
- Clear visual hierarchy
- Readable font sizes
- Color not sole indicator

## Implementation

All design tokens are centralized in `DesignSystem.swift`:

```swift
// Colors
Design.Colors.primary
Design.Colors.primaryGradient

// Typography
Design.Typography.headline

// Spacing
Design.Spacing.md

// Animations
Design.Animation.spring

// Apply card style
.cardStyle()
```

## Future Enhancements

- Dark mode optimizations
- Haptic feedback
- More micro-interactions
- Custom illustrations
- Advanced animations

---

**Last Updated**: December 2024
**Version**: 1.0

