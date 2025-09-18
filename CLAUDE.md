# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Important: Read Documentation First

**ALWAYS read all documents in the `documents/` directory when starting work on this project.** This directory contains:
- `concept.md`: Project concept and feature specifications (Korean)
- `tech-spec.md`: Technical specifications with Flutter and Supabase architecture
- `design-system.md`: Complete design system with colors, typography, and component styles

These documents provide essential context for understanding the project requirements, technical decisions, and design consistency.

## Project Overview

This is the "blinddate" project - a Korean dating app MVP with the following core features:
- Daily recommendation of 2 people per user
- Country-based matching (same country users only)
- Admin approval-based registration system
- Basic DM functionality with premium real-time chat
- Phone verification and profile-based registration

## Technology Stack

- **Frontend**: Flutter (Cross-platform mobile app)
- **Language**: Dart
- **Backend**: Supabase (BaaS)
- **Database**: PostgreSQL (via Supabase)
- **Authentication**: Supabase Auth with phone verification
- **Real-time**: Supabase Realtime for chat
- **Storage**: Supabase Storage for profile images

## Project Status

This is a new project repository with initial documentation. The project will be built as a Flutter mobile application with Supabase backend.

## Architecture Notes

Based on the concept document (documents/concept.MD), the app will follow this flow:
1. User registration → Phone verification → Profile creation → Admin approval
2. Daily matching system showing 2 recommendations per day
3. Interest-based matching with DM capabilities
4. Premium features for real-time chat

The system is designed with scalability in mind for country-by-country expansion.

## Development Status

The repository currently contains:
- Initial git setup
- Flutter/Dart project configuration (.gitignore)
- Project concept documentation in Korean (documents/concept.MD)
- No actual code implementation yet

## Key Features to Implement (Based on Concept Doc)

1. **User Authentication System**
   - Phone number verification (country-specific)
   - Email and nickname registration
   - Profile creation with photos and interests

2. **Admin Approval System**
   - Profile review and approval/rejection workflow
   - Admin dashboard for user management

3. **Matching System**
   - Daily 2-person recommendation algorithm
   - Interest/Pass selection mechanism
   - Mutual interest detection

4. **Communication Features**
   - Basic DM system (free)
   - Premium real-time chat (paid feature)

5. **Monetization**
   - Premium chat features
   - Additional daily recommendations
   - Profile boost functionality

## Development Commands

Since this is a Flutter project, common development commands will include:
- `flutter pub get`: Install dependencies
- `flutter run`: Run the app in development mode
- `flutter build`: Build the app for production
- `flutter test`: Run tests

## Key Development Notes

- Use Provider or Riverpod for state management
- Follow the feature-based folder structure outlined in tech-spec.md
- Implement Row Level Security (RLS) policies in Supabase
- Use Supabase client for all backend interactions
- Prioritize phone verification and admin approval systems

## Design Guidelines

**CRITICAL**: Always follow the design system (design-system.md) for visual consistency:
- Use the defined color palette (primary: #2D3142, accent: #EF476F)
- Apply consistent spacing system (xs:4, sm:8, md:16, lg:24, xl:32, xxl:48)
- Follow typography hierarchy (H1/H2/H3 for headings, Body1/Body2 for content)
- Use minimal, clean design with plenty of whitespace
- Implement consistent component styles (buttons, cards, inputs)
- Maintain "Minimal Elegance" design philosophy throughout

## Development Approach

Since this is a mobile dating app MVP, development should prioritize:
1. Core user flow (registration → matching → basic communication)
2. Admin approval system for content moderation
3. Basic monetization features
4. Country-specific expansion capabilities