# ZeroScroll Website

A fast, minimalist, and privacy-focused landing page for **ZeroScroll** — an Android app that shows only your Instagram DMs and notifications, with no feed, Search, Reels tab, or Stories.

Built with **Next.js (App Router)**, **TypeScript**, and **Tailwind CSS**, designed for maximum performance, accessibility, and zero-configuration deployment on **Vercel**.

---

## Features

- **Single Landing Page (`/`)**:
  1. Hero with headline, subtext, and Android APK download button
  2. CSS/SVG Phone Mockup showing clean inbox UI (no stock images)
  3. "What it does" (4 core feature cards)
  4. "What it blocks" (Home feed, Search/Explore, Reels tab, Stories, Profile browsing)
  5. "Privacy" (On-device data, zero ads, zero trackers, zero analytics)
  6. Short FAQ (4 key user questions)
  7. Footer with Privacy, Terms, and non-affiliation disclaimer
- **Dedicated Pages**:
  - `/privacy`: Plain-language privacy manifesto
  - `/terms`: Terms of service, disclaimer, and Indian governing law
- **Design**:
  - Calm, minimal aesthetic with deep teal accent
  - Automatic system dark mode support
  - Native system font stack
  - SVG/PNG favicon and complete Open Graph metadata
  - Zero cookies, zero analytics, zero external tracking scripts (Lighthouse 95+ target)

---

## Environment Variables & Automated Release Assets

The website dynamically reads `public/version.json` and serves the latest release APK directly at `/zeroscroll.apk`.

When running `npm run release` from the repository root, the latest sideload APK, SHA-256 hash, and release manifest are deployed directly into `public/zeroscroll.apk` and `public/version.json`.

Optional environment variables:

| Variable | Description | Default Value / Example |
| :--- | :--- | :--- |
| `NEXT_PUBLIC_APK_URL` | Direct download link for the Android `.apk` binary | `/zeroscroll.apk` |
| `NEXT_PUBLIC_APP_VERSION` | Version label displayed on download badges | Read from `public/version.json` or `v1.0.0` |

Copy the example file to create your local environment:
```bash
cp .env.example .env.local
```

---

## Getting Started Locally

1. **Install dependencies:**
   ```bash
   npm install
   ```

2. **Run development server:**
   ```bash
   npm run dev
   ```
   Open [http://localhost:3000](http://localhost:3000) in your browser.

3. **Build for production:**
   ```bash
   npm run build
   ```

4. **Start production server:**
   ```bash
   npm run start
   ```

---

## Deploying to Vercel

### Option 1: Set Root Directory to `website` (Recommended)

1. In the [Vercel Dashboard](https://vercel.com/dashboard), import the `ZeroScroll` repository.
2. In the project setup screen, expand **Root Directory** and select `website`.
3. Vercel automatically configures the Next.js framework preset.
4. In **Environment Variables**, add:
   - `NEXT_PUBLIC_APK_URL`: `<URL to your APK>`
   - `NEXT_PUBLIC_APP_VERSION`: `v1.0.0`
5. Click **Deploy**.

### Option 2: Deploy from Repository Root

If deploying from the repository root, the root `vercel.json` and root `package.json` will automatically forward the build to the `website` directory.
