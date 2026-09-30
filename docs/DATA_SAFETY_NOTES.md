# Google Play Data Safety Form Notes for ZeroScroll

*Reference Guide for Submitting ZeroScroll (`com.apexventures.zeroscroll`) to Google Play Console*

This document provides exact responses and architectural justifications for completing the **Data Safety** questionnaire in Google Play Console.

---

## 1. Overview & Core Declarations

| Question | Answer | Rationale / Architecture |
|---|---|---|
| **Does your app collect or share any of the required user data types?** | **No** | ZeroScroll does not transmit any user data, personal info, message content, or device identifiers off the device. All data is processed and stored strictly on-device in the app sandbox. |
| **Is all of the user data collected by your app encrypted in transit?** | **Yes** | All network communications (WebView rendering and static remote config JSON fetches) occur exclusively over HTTPS (TLS 1.2+). Cleartext HTTP is explicitly disabled via Android Network Security Config. |
| **Do you provide a way for users to request that their data be deleted?** | **Yes** | Users can wipe all locally stored data, cookies, preferences, and notifications at any time via Settings > Security > "Log out and wipe data". |

> **Google Play Policy Note regarding "On-Device Only" Storage:**  
> According to Google Play Data Safety guidelines:  
> *"If data is processed only locally on a user's device and not sent off the device, you do not need to disclose it as 'collected' in the Data Safety form."*  
> Because ZeroScroll operates 100% on-device with no backend or external servers, no data categories are collected or shared by Apex Ventures.

---

## 2. Category-by-Category Declaration Breakdown

### Personal Info
- **Name, Email Address, User IDs, Address, Phone Number, Race/Ethnicity, Political/Religious Beliefs, Sexual Orientation**:  
  - **Status:** **Not collected**
  - **Notes:** The app does not ask for or collect user profile data. Account authentication occurs directly on the official Instagram web domain within an isolated Android WebView; ZeroScroll never captures, reads, or transmits credentials.

### Financial Info
- **Credit Card, Debit Card, Bank Account, Other Financial Info**:  
  - **Status:** **Not collected**

### Location
- **Approximate Location / Precise Location**:  
  - **Status:** **Not collected** (No location permissions requested).

### Messages
- **Emails, SMS / MMS, Other In-App Messages**:  
  - **Status:** **Not collected**
  - **Clarification:** While the user interacts with Direct Messages in the sandboxed WebView, ZeroScroll does not collect, read, analyze, or transmit message bodies or thread metadata to any server. Captured notification snippets (via the optional Android Notification Listener) remain strictly in an on-device SQLite database and can be deleted by the user at any time.

### Photos and Videos
- **Photos / Videos**:  
  - **Status:** **Not collected**
  - **Clarification:** Users may pick media files via Android's native system photo picker to send as an attachment inside a DM. This file handling is direct from the system picker to the Instagram web session; ZeroScroll does not collect or transmit user media.

### Audio Files
- **Voice or Sound Recordings, Music, Other Audio Files**:  
  - **Status:** **Not collected**

### Files and Documents
- **Files and Docs**:  
  - **Status:** **Not collected**

### Calendar & Contacts
- **Calendar Events, Contacts**:  
  - **Status:** **Not collected**

### App Activity
- **App Interactions (e.g., page views, taps)**:  
  - **Status:** **Not collected** (Metrics such as daily foreground minutes and reel counters are stored exclusively on-device in Drift SQLite for user limits).
- **In-App Search History**:  
  - **Status:** **Not collected**
- **Installed Apps**:  
  - **Status:** **Not collected**

### Web Browsing
- **Web Browsing History**:  
  - **Status:** **Not collected**  
  - **Clarification:** The in-app WebView navigates strictly within instagram.com DM and activity paths. No browsing history is tracked, logged, or sent to any server.

### App Info & Performance
- **Crash Logs, Diagnostics, Performance Metrics**:  
  - **Status:** **Not collected**  
  - **Clarification:** ZeroScroll does not include Firebase Crashlytics, Sentry, Bugsnag, or any crash/telemetry SDKs in v1.

### Device or Other Identifiers
- **Device or other IDs (e.g., IMEI, MAC address, Advertising ID)**:  
  - **Status:** **Not collected** (ZeroScroll does not request or use Google Advertising ID).

---

## 3. Security Practices Summary

When filling out the **Security practices** section in Google Play Console:

1. **Data encryption in transit**:  
   Select **Yes**. ZeroScroll uses HTTPS exclusively for all web sessions and configuration downloads.
2. **Data deletion mechanism**:  
   Select **Yes**. The app provides a prominent, one-tap "Log out and wipe data" button in Settings that instantly drops all SQLite tables, deletes all WebView cookies/cache, and clears all `SharedPreferences`.
3. **Target Audience**:  
   General audience (13+). ZeroScroll does not target children under 13.

---

## 4. Privacy Policy URL

When submitting to Google Play Console:
- **Privacy Policy URL**: Host the contents of `docs/PRIVACY_POLICY.md` at a publicly accessible HTTPS web address (e.g., `https://apexventures.com/zeroscroll/privacy` or GitHub Pages) and enter that URL in the Play Console under App Content > Privacy Policy.
