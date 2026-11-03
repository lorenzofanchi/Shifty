# Changelog

All notable changes to this fork of Shifty. Dates are release dates. For versions up to 1.2, see
[upstream's releases](https://github.com/thompsonate/Shifty/releases).

## 1.4.1 — 2026-11-03

### Changed
- Rule exports are named with the date, such as `Shifty Rules 2026-11-03.json`, so an export made on
  another day doesn't overwrite the last one.
- On the Rules pane, the explanation sits above the list, so adding rules no longer pushes it down.

### Fixed
- Night Shift no longer turns on in daytime when a website you kept on under a disabled domain comes
  to the front. It follows the schedule there instead.
- Settings opens without the sidebar jumping when the window takes focus.

## 1.4 — 2026-10-27

### Added
- **A Rules pane in Settings.** Every app and website rule in one list, sorted by name, with what
  each one does. Subdomain rules sit under their domain. Remove rules here, and use **Import…** and
  **Export…** to move them to another Mac. Importing adds to the rules you have and replaces none of
  them.
- **Quick Toggle picks a click.** Choose Off, Left Click or Right Click: that click on the menu bar
  icon switches Night Shift on or off, and the other opens the menu. With Off, both open the menu.
  Your old setting carries over.

### Changed
- **Settings is a sidebar window**, like System Settings, with General, Night Shift, Rules, Shortcuts
  and About.
- Setting descriptions say what each setting does, instead of starting with "If enabled".
- About credits the original Shifty by Nate Thompson and links to this fork.

### Fixed
- The transition speed defaulted to instant for anyone who had never chosen one, instead of Normal.
  Shifty's default settings had never been registered.

## 1.3 — 2026-10-12

### Added
- **Transition speed.** Settings → Night Shift → Transition makes Night Shift fade on and off Slow,
  Normal, Fast or Very Fast.
- A redrawn first-run wizard, with illustrations of the menu bar and the supported browsers.

### Changed
- The menu opens straight away with a browser in front. It used to take over half a second.
- Settings and the custom time dialog open on the current Space and come to the front.
- The menu is grouped more sensibly, and says "Disable while using" for the frontmost-app rule.
- Website Shifting lets macOS ask for Accessibility, and keeps saying so until it's granted.
- Needs macOS 14 or later.

### Fixed
- The first click in Settings is no longer lost bringing the window forward.
- The Website Shifting checkbox no longer unticks itself.

## 1.2.1 — 2026-08-31

The first release of this fork, built with Xcode 26.

### Added
- Upstream's unreleased work since 1.2: switches in the menu, Brave support, disabling Night Shift
  while an app is running, and right-clicking the menu bar icon to toggle Night Shift.

### Removed
- Microsoft App Center analytics and crash reporting, which shut down in 2025.
- Sparkle automatic updates, which pointed at upstream's update feed.
