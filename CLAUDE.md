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
- Daily recommendation of 1 person per user
- Country-based matching (same country users only)
- Admin approval-based registration system
- Basic DM functionality with premium real-time chat
- Phone verification and profile-based registration

## Project Structure Guide

**IMPORTANT**: When searching for code or implementing features, refer to this structure to find files efficiently. Focus searches on relevant directories only.

### Root Directory Structure

```
blinddate/
├── lib/                    # Flutter source code (PRIMARY DEVELOPMENT AREA)
├── documents/              # Project documentation (READ FIRST)
├── scripts/                # Database migrations & automation scripts
├── ~/operation/blinddate/  # Production operation scripts (CRITICAL - AI scheduler & background services)
├── supabase/               # Supabase configuration
├── assets/                 # Images, fonts, and other static resources
├── android/                # Android platform-specific code (rarely modified)
├── ios/                    # iOS platform-specific code (rarely modified)
├── web/                    # Web platform code (rarely modified)
├── web_auth/               # Web authentication page
├── test/                   # Unit and integration tests
└── build/                  # Build artifacts (IGNORE - auto-generated)
```

### lib/ Directory (Main Development Area)

```
lib/
├── main.dart               # App entry point - initializes services
├── app/                    # App-level configuration (routing, providers)
│
├── core/                   # Shared core functionality
│   ├── constants/          # App-wide constants (colors, text styles, spacing, table names)
│   ├── services/           # Core services (Supabase, storage, notifications, deep links)
│   ├── theme/              # App theme configuration
│   ├── utils/              # Utility functions
│   └── widgets/            # Reusable widgets (e.g., badge_icon)
│
├── features/               # Feature-based modules (PRIMARY WORK AREA)
│   ├── auth/               # Authentication & onboarding
│   │   ├── screens/        # Login, signup, profile setup, approval screens
│   │   ├── services/       # Auth service logic
│   │   ├── models/         # User models
│   │   └── widgets/        # Auth-specific widgets
│   │
│   ├── matching/           # Daily matching system
│   │   ├── screens/        # Home screen, match history
│   │   ├── services/       # Scheduled matching service
│   │   ├── models/         # Match models
│   │   └── widgets/        # Match cards, action buttons
│   │
│   ├── chat/               # Messaging functionality
│   │   ├── screens/        # Chat list, chat room
│   │   ├── services/       # Chat service, notifications
│   │   ├── models/         # Message models
│   │   └── widgets/        # Chat widgets
│   │
│   ├── profile/            # User profile management
│   │   ├── screens/        # Profile view, edit, settings
│   │   ├── services/       # Profile service
│   │   ├── models/         # Profile models
│   │   └── widgets/        # Profile widgets
│   │
│   └── dashboard/          # Main navigation
│       └── screens/        # Dashboard with bottom navigation
│
├── shared/                 # Shared resources across features
│   ├── models/             # Common data models
│   ├── utils/              # Shared utilities
│   └── widgets/            # Shared UI components
│
└── services/               # Additional app-level services

Total: ~51 Dart files across all modules
```

### documents/ Directory (Essential Context)

```
documents/
├── concept.md              # Product concept & feature specifications (Korean)
├── tech-spec.md            # Technical architecture & decisions
├── design-system.md        # UI/UX design system (colors, typography, spacing)
├── data.md                 # Data models & database schema
├── SETUP.md                # Project setup instructions
├── SCHEDULED_MATCHING_SYSTEM.md  # Matching algorithm documentation
└── playstore-slides-*.md   # App store materials
```

### scripts/ Directory (Database & Automation)

```
scripts/
├── ai_*.sql/py             # AI user system & chat response automation
├── *_migration.sql         # Database schema migrations
├── create_test_*.sql       # Test data generation
├── daily_batch_matching.sql # Daily matching algorithm
├── *.sh                    # Bash automation scripts
└── *.py                    # Python utilities (schema checks, data updates)

Total: ~50+ SQL/Python/Shell scripts for database management
```

### ~/operation/blinddate/ Directory (Production Operations)

**CRITICAL**: This directory contains production-ready background services and automation scripts.

```
~/operation/blinddate/
├── ai_scheduler.py         # Main AI scheduler (processes scheduled_at from queue)
├── ai_scheduler_old.py     # Backup/previous version
├── handlers/               # Action handlers for AI automation
│   ├── like_handler.py     # Handles AI LIKE/PASS decisions via LLM
│   ├── chat_handler.py     # Handles AI chat message generation
│   └── base_handler.py     # Base handler class
├── utils/                  # Utility modules
├── logs/                   # Runtime logs
├── check_*.py              # Monitoring & debugging scripts
├── fix_*.py                # Fix/repair scripts
├── reset_queue.py          # Queue management
├── rollback_and_retry.py   # Error recovery
├── com.blinddate.ai-scheduler.plist  # macOS launchd service config
├── AUTOSTART_SETUP.md      # Service autostart documentation
└── CHATROOM_ISSUE_SOLUTION.md  # Troubleshooting guide
```

**Usage:**
- AI Scheduler runs as background service (launchd on macOS)
- Processes `blinddate_ai_action_queue` table every minute
- Executes actions where `scheduled_at <= NOW()` (UTC time)
- Uses LLM (Ollama/exaone3.5) for AI decision making

**⚠️ CRITICAL SERVICE MANAGEMENT RULES:**

1. **NEVER manually run ai_scheduler.py directly**
   - The scheduler is registered with launchd as a system service
   - Manual execution will create duplicate processes → duplicate log entries → confusion
   - Always use launchd commands to control the service

2. **Service Control Commands:**
   ```bash
   # Check service status
   launchctl list | grep blinddate

   # Start service
   launchctl start com.blinddate.ai-scheduler

   # Stop service
   launchctl stop com.blinddate.ai-scheduler

   # Restart service (after code changes)
   launchctl stop com.blinddate.ai-scheduler && launchctl start com.blinddate.ai-scheduler

   # Reload service configuration
   launchctl unload ~/Library/LaunchAgents/com.blinddate.ai-scheduler.plist
   launchctl load ~/Library/LaunchAgents/com.blinddate.ai-scheduler.plist

   # View logs
   tail -f ~/operation/blinddate/logs/ai_scheduler.log
   ```

3. **Before making changes to ai_scheduler.py:**
   - Stop the service first: `launchctl stop com.blinddate.ai-scheduler`
   - Make your code changes
   - Restart the service: `launchctl start com.blinddate.ai-scheduler`
   - Verify single process: `pgrep -lf ai_scheduler.py` (should show only 1 process)

4. **Troubleshooting duplicate processes:**
   ```bash
   # Kill all ai_scheduler processes
   pkill -f ai_scheduler.py

   # Restart via launchd only
   launchctl start com.blinddate.ai-scheduler

   # Verify single process
   pgrep -lf ai_scheduler.py  # Should show exactly 1 process
   ```

5. **Log file location:**
   - Main log: `~/operation/blinddate/logs/ai_scheduler.log`
   - If you see duplicate log entries, multiple processes are running
   - Always check process count before debugging: `pgrep -lf ai_scheduler.py`

6. **Timezone handling:**
   - Database stores all timestamps in UTC (PostgreSQL TIMESTAMPTZ)
   - ai_scheduler.py uses `datetime.utcnow()` for all comparisons
   - Never use `datetime.now()` for scheduled_at comparisons (causes 9-hour offset in KST)

### Directories to IGNORE During Development

- `build/` - Auto-generated build artifacts
- `.dart_tool/` - Dart SDK tooling cache
- `.idea/` - IDE configuration
- `android/build/` - Android build output
- `ios/build/` - iOS build output
- Any `Pods/` directories - iOS dependencies

### Quick Navigation Tips

1. **UI/Screen changes**: Look in `lib/features/[feature]/screens/`
2. **Business logic**: Look in `lib/features/[feature]/services/`
3. **Database operations**: Look in `lib/core/services/supabase_service.dart`
4. **Design tokens**: Look in `lib/core/constants/` (colors, spacing, text styles)
5. **Database migrations**: Look in `scripts/` directory
6. **Project requirements**: Look in `documents/` directory
7. **AI automation & schedulers**: Look in `~/operation/blinddate/` (production services)
8. **AI action queue processing**: Check `~/operation/blinddate/ai_scheduler.py`

### File Naming Conventions

- Screens: `*_screen.dart` (e.g., `profile_edit_screen.dart`)
- Services: `*_service.dart` (e.g., `chat_service.dart`)
- Models: `*_model.dart` or just feature name (e.g., `user.dart`)
- Widgets: Descriptive names (e.g., `match_history_card.dart`)
- Constants: `app_*.dart` or feature name (e.g., `app_colors.dart`, `table_names.dart`)

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
2. Daily matching system showing 1 recommendation per day
3. Interest-based matching with DM capabilities
4. Premium features for real-time chat

The system is designed with scalability in mind for country-by-country expansion.

## Development Status

The repository currently contains:
- Initial git setup
- Flutter/Dart project configuration (.gitignore)
- Project concept documentation in Korean (documents/concept.MD)
- **Implemented core features:**
  - User authentication system (phone + email verification)
  - Profile creation and editing system
  - Admin approval workflow
  - Daily 1-person matching system
  - Match history tracking
  - Basic chat functionality
  - Dashboard with bottom navigation
  - App settings and profile management

## Implementation Status (Based on Concept Doc)

✅ **Completed Features:**
1. **User Authentication System**
   - ✅ Phone number verification (country-specific)
   - ✅ Email and nickname registration
   - ✅ Profile creation with photos and interests

2. **Admin Approval System**
   - ✅ Profile review and approval/rejection workflow
   - ⏳ Admin dashboard for user management (backend ready, UI pending)

3. **Matching System**
   - ✅ Daily 1-person recommendation algorithm
   - ✅ Interest/Pass selection mechanism
   - ✅ Mutual interest detection
   - ✅ Match history tracking

4. **Communication Features**
   - ✅ Basic DM system (implemented)
   - ⏳ Premium real-time chat (architecture ready, features pending)

5. **Dashboard & Navigation**
   - ✅ Bottom navigation with 4 tabs
   - ✅ Profile management and settings
   - ✅ App settings and preferences

🚧 **Pending Features:**
- Home dashboard content
- Premium chat features
- Additional daily recommendations
- Profile boost functionality
- Admin dashboard UI

## Development Commands

Since this is a Flutter project, common development commands will include:
- `flutter pub get`: Install dependencies
- `flutter run`: Run the app in development mode
- `flutter build`: Build the app for production
- `flutter test`: Run tests

## Key Development Notes

- ✅ Using Provider for state management (implemented)
- ✅ Following feature-based folder structure as outlined in tech-spec.md
- ✅ Implemented Row Level Security (RLS) policies in Supabase
- ✅ Using Supabase client for all backend interactions
- ✅ Phone verification and admin approval systems completed
- 🔄 Current state: Core MVP features implemented, focusing on remaining UI components

## Database Connection Guidelines

**CRITICAL**: When performing any database operations (queries, updates, migrations, etc.), ALWAYS follow these rules:

1. **Read `.env` file first**: Before any database operation, read the `.env` file to get the current database credentials
   - `SUPABASE_URL`: The Supabase project URL
   - `SUPABASE_ANON_KEY`: The anon/public key for client-side operations
   - `SUPABASE_SERVICE_ROLE_KEY`: The service role key for admin/server-side operations

2. **Never use hardcoded credentials**: Do NOT use any hardcoded database credentials like `conn1004`, `conn1234`, or any other pre-configured connection strings

3. **For direct PostgreSQL access**: If you need to connect directly to PostgreSQL:
   - Use Supabase CLI: `supabase db` commands (preferred)
   - Or extract connection details from Supabase dashboard (manual fallback)

4. **Connection priority**:
   - First choice: Use Supabase client SDK (already configured in `lib/core/services/supabase_service.dart`)
   - Second choice: Use Supabase CLI commands
   - Last resort: Direct PostgreSQL connection (only if absolutely necessary and user confirms)

5. **Example workflow** for database tasks:
   ```bash
   # Step 1: Read .env to verify credentials
   cat .env

   # Step 2: Use Supabase CLI for database operations
   supabase db push
   supabase db reset

   # Step 3: For queries, prefer using the Flutter app's Supabase client
   # Check lib/core/services/supabase_service.dart for available methods
   ```

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