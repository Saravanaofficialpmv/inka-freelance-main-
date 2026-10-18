# 🧠 Inka Knowledge Brain & Documentation Portal

Welcome to the **Inka Invoicing & Billing** Project Brain. This directory is the centralized, modular source of truth for the architecture, design system, data entities, feature implementations, cloud infrastructure, and developer guidelines of the Inka application.

---

## 🗂️ Knowledge Base Directory Structure

| Folder | Focus Area | Description |
| :--- | :--- | :--- |
| [📁 `00-overview/`](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/00-overview) | **Project Foundations** | Executive summary, technology stack, and comprehensive project sitemap. |
| [📁 `01-architecture/`](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/01-architecture) | **System Architecture** | Clean architecture layers, Hive-Firestore offline-first synchronization, and GoRouter navigation. |
| [📁 `02-design-system/`](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/02-design-system) | **UI & Design Tokens** | White & vibrant orange theme, Space Grotesk / Inter typography, and UI component standards. |
| [📁 `03-data-models/`](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/03-data-models) | **Data & Domain Models** | Hive TypeId registry (0–8), Business Profile, Invoices, Clients, Products, Projects, Time, and Expenses. |
| [📁 `04-features/`](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/04-features) | **Feature Deep Dives** | Invoicing engine, PDF templates, dynamic UPI, multi-currency, time tracker, digital signatures, and speech AI. |
| [📁 `05-backend-and-cloud/`](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/05-backend-and-cloud) | **Cloud & Backend** | Firebase Firestore schema, sandboxed security rules, and multi-provider authentication. |
| [📁 `06-developer-guides/`](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/06-developer-guides) | **Engineering Guides** | Getting started, adding new models/screens, and unit/widget testing best practices. |

---

## 🧭 Master Document Index

### 00. Overview
- [Executive Summary](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/00-overview/executive_summary.md): Product vision, value propositions, and target users.
- [Technology Stack](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/00-overview/technology_stack.md): Multiplatform Flutter, Riverpod, Hive, Firebase, and native plugins.
- [Project Sitemap](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/00-overview/project_sitemap.md): Full source tree file map and screen route matrix.

### 01. Architecture
- [System Architecture](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/01-architecture/system_architecture.md): Layered Clean Architecture (Presentation, Services, Data).
- [Offline-First & Cloud Sync](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/01-architecture/offline_first_and_sync.md): Immediate Hive mutations + background Firestore bi-directional sync.
- [Navigation & Responsive Layout](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/01-architecture/navigation_and_responsive.md): GoRouter declarative routing, ShellRoute, mobile nav shell, and web sidebar.

### 02. Design System
- [Colors & Design Tokens](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/02-design-system/colors_and_tokens.md): Inka Orange (`#FF5722`), Lime accent (`#9BD71B`), surfaces, and status palettes.
- [Typography & Assets](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/02-design-system/typography_and_assets.md): Space Grotesk, Inter, Poppins fonts, custom SVG icons, and assets.
- [UI Components](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/02-design-system/ui_components.md): Rounded cards, bottom sheets, floating navigation pill, and signature pads.

### 03. Data Models
- [Hive TypeId Registry](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/03-data-models/hive_registry.md): TypeId allocation table (0–8), adapter registration, and disk auto-recovery.
- [Business Profile Model](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/03-data-models/business_profile.md): Company profile, branding, bank coordinates, and UPI settings.
- [Invoice & Items Model](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/03-data-models/invoice_and_items.md): Invoice and InvoiceItem entities, calculations, and status lifecycle.
- [Clients & Products Model](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/03-data-models/clients_and_products.md): Client directory and product catalog entities with categorization.
- [Projects & Time Tracking Model](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/03-data-models/projects_and_time.md): Project budgets, stages, and TimeEntry models.
- [Expenses & Profit Model](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/03-data-models/expenses_and_profit.md): Expense logging, categories, and business net profit computation.
- [Subscription Plans Model](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/03-data-models/subscription_plans.md): Free vs Pro tiers, billing cycles, and feature gates.

### 04. Features
- [Invoice Builder & Vector PDF](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/04-features/invoice_builder_and_pdf.md): PDF engine, 10+ templates (Modern, Professional, Legend, Evergreen, etc.).
- [Dynamic UPI Payments](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/04-features/dynamic_upi_payments.md): Dynamic UPI QR code embedding (`upi://pay`), bank settlement, and preview sheets.
- [Currency & Tax Engine](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/04-features/currency_and_tax.md): Multi-currency conversions, exchange rates, and GST/VAT/Sales tax computations.
- [Time Tracker](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/04-features/time_tracker.md): Active stopwatch, manual time entries, and 1-tap conversion to billable invoices.
- [Digital Signatures](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/04-features/digital_signatures.md): SignaturePad canvas, high-res PNG export, and invoice embedding.
- [Voice Dictation AI](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/04-features/voice_dictation.md): Speech-to-text parser for hands-free item and note entries.
- [Contacts & WhatsApp Sharing](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/04-features/contacts_and_whatsapp.md): Device contact picker and direct WhatsApp invoice delivery.
- [Localization & i18n](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/04-features/localization_i18n.md): English, Tamil, Hindi, Spanish dynamic runtime switching.

### 05. Backend & Cloud
- [Firebase Firestore](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/05-backend-and-cloud/firebase_firestore.md): Firestore document tree (`/users/{uid}/*`) and sync protocol.
- [Security Rules](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/05-backend-and-cloud/security_rules.md): User isolation, permission locks, and data validation rules.
- [Authentication & Sessions](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/05-backend-and-cloud/auth_and_session.md): Email/Password, Google Sign-In, and Sign in with Apple with SHA-256 nonces.

### 06. Developer Guides
- [Development Setup](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/06-developer-guides/development_setup.md): Environment setup, Hive build runner, and running across platforms.
- [Extending Features](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/06-developer-guides/adding_new_features.md): Step-by-step tutorial on adding models, screens, providers, and PDF templates.
- [Testing & QA](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/06-developer-guides/testing_and_qa.md): Unit tests, widget tests, safe navigation, and responsive desktop layout verification.

---

## ⚡ Quick Reference for AI Assistants & LLMs

When generating code or fixing issues in Inka, always consult these three foundational rules:
1. **Offline-First Rule**: Always write mutations to Hive local storage first before pushing to Firestore. Never block the UI waiting on remote cloud calls.
2. **Design Language**: All UI surfaces must use the official Inka palette (`AppColors.primary` `#FF5722`, `AppColors.background` `#F7F8FA`, `AppColors.card` `#FFFFFF`) and typography defined in [Colors & Design Tokens](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/02-design-system/colors_and_tokens.md).
3. **Hive Registry**: When adding models, check [Hive Registry](file:///Users/saravana/flutter/final%20clg%20management%20application/invoice%20generator/invoice_generator/brain/03-data-models/hive_registry.md) to claim an unassigned `typeId >= 9`.
