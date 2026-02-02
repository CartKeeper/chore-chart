# Carter's Quest Log - Deployment Guide

## Quick Deploy to Netlify (Easiest)

1. **Go to** [netlify.com/drop](https://app.netlify.com/drop)
2. **Drag the entire `carter-quest-log` folder** onto the page
3. **Done!** You'll get a URL like `random-name-123.netlify.app`
4. **Optional:** Click "Site settings" to change the URL to something memorable like `carter-quests.netlify.app`

## Adding to Carter's Phone

### iPhone:
1. Open the site URL in Safari
2. Tap the Share button (square with arrow)
3. Scroll down and tap "Add to Home Screen"
4. Name it "Quest Log" and tap Add

### Android:
1. Open the site URL in Chrome
2. Tap the three dots menu (⋮)
3. Tap "Add to Home Screen" or "Install App"
4. The install banner may also appear automatically

## Enabling Notifications

1. Open the app
2. Set the reminder time (default 8:00 PM)
3. Tap "Enable Reminders"
4. Allow notifications when prompted

**Note:** Notifications work best when the app is installed to the home screen.

---

## 💰 REWARD SYSTEM

### Weekly Pay Scale (Based on Rank)

| Rank | XP Required | Weekly Pay |
|------|-------------|------------|
| Common | 0-99 XP | $5 |
| Uncommon | 100-199 XP | $10 |
| Rare | 200-299 XP | $15 |
| Epic | 300-399 XP | $20 |
| Legendary | 400+ XP | $25 |

### 🔥 Streak Bonus
Complete ALL nightly patrols (all 3 zones, all 7 days) = **1.5x multiplier** on weekly pay!

Example: Epic rank ($20) + perfect streak = **$30**

### 🏆 One-Time Achievement Bonuses

| Achievement | Requirement | Bonus |
|-------------|-------------|-------|
| First Legend | Reach Legendary rank | +$10 |
| On Fire | 7-day perfect nightly streak | +$5 |
| Overachiever | 500+ XP in one week | +$10 |
| Garage Boss | Garage Guardian 4 weeks in a row | +$15 |
| Early Bird | All quests done by Thursday | +$5 |
| Perfectionist | 100% completion in a week | +$20 |

### Example Week

Carter completes:
- All weekly quests → 310 XP = **Epic Rank ($20)**
- Perfect nightly streak → **1.5x multiplier**
- Unlocks "On Fire" achievement → **+$5 bonus**

**Total: $20 × 1.5 + $5 = $35**

---

## What's Included

- `index.html` - The main app
- `manifest.json` - PWA configuration
- `sw.js` - Service worker for offline support
- `icon-192.png` & `icon-512.png` - App icons

## Features

- ✅ Works offline once loaded
- ✅ Saves progress automatically
- ✅ Weekly auto-reset with earnings tracking
- ✅ XP/Level/Rank tracking
- ✅ Wallet with earnings breakdown
- ✅ Achievement system with bonuses
- ✅ Streak tracking with 1.5x bonus
- ✅ Nightly reminders
- ✅ Lifetime stats (total earned, weeks completed)
- ✅ Mobile-first design
