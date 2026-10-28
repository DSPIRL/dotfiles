# Quickshell Design-System Foundation Plan

## Mission statement

Make polished shell interactions cheap, consistent, and safe to extend by turning the desktop's existing visual conventions into a small, tested set of shell-wide design tokens, reusable controls, and focused state interfaces.

The desktop already has a coherent material language, centralized typography and colors, reusable glass surfaces, keyboard-aware controls, low-effects behavior, and useful Qt tests. The problem is not a lack of design. The problem is that important conventions remain implicit in hard-coded geometry, control-center-specific components, and large objects that combine service state, policy, and presentation. Every elaborate new interaction therefore costs more custom code and regression risk than it should.

This change should preserve the current appearance and behavior while lowering the marginal cost of future UI work. It is not an attempt to copy Dux Shell, create a general-purpose framework, or redesign the desktop. The foundation is successful when a future agent can build a new panel or interactive element mostly by composing documented, tested project-owned primitives instead of duplicating styling, focus, accessibility, animation, and low-effects logic.

## Desired outcome

The Quickshell configuration has:

- one clear source of truth for typography, palette/material colors, spacing, radii, dimensions, and motion;
- shell-wide controls whose names and APIs match their actual use across control, notification, and bar surfaces;
- explicit behavior for normal, hover, pressed, focused, selected, disabled, and low-effects states;
- presentation components that depend on focused state/action interfaces where a real second consumer or test seam justifies it;
- tests that protect component behavior independently of live compositor and hardware services;
- one small, real component built on the foundation that demonstrates the reduced cost;
- concise documentation showing where new UI code belongs and how to verify it.

## Constraints and non-goals

- Preserve current public shortcuts, settings, persistence, compositor behavior, and service integrations.
- Preserve the current visual result unless a task explicitly identifies and documents a bug.
- Keep generated wallpaper colors in `quickshell/default/wallust/Colors.qml.tmpl`; do not mix generated palette data with stable layout or motion tokens.
- Keep `Typography.qml` as the typography source of truth.
- Do not add a backend daemon, dependency, UI framework, or design-tool export pipeline.
- Do not create speculative controls or state objects. Every extraction needs a second concrete consumer, a demonstrated change cost, or a required test seam, recorded in this plan before implementation.
- Do not retain compatibility wrappers after all in-repository consumers have migrated.
- Do not split files solely to reduce line counts.
- Low-effects mode must continue to disable nonessential motion and expensive effects without erasing saved preferences.
- Keyboard operation, focus visibility, pointer behavior, and accessibility metadata are acceptance requirements, not later polish.
- Work in the chezmoi source tree. Do not edit generated target files under `~/.config` directly.

## Agent execution protocol

Each task is one reviewable change.

1. Read this plan, `docs/hyprland-desktop.md`, and the files named by the task.
2. Confirm prerequisite tasks are complete in the current tree; do not rely only on checkbox state.
3. Make the smallest change that satisfies the task. Avoid opportunistic redesign.
4. Add or update verification in the same task.
5. Run the task's focused checks. Run `hyprctl configerrors` and the native tests only when an unlocked Wayland session is available; otherwise say so in the completion note.
6. Mark the task complete and add a dated entry to the **Completion log** at the end of this plan. Record what was verified, what was skipped, and any deviation.
7. If implementation evidence conflicts with this plan, update the plan with the reason before broadening scope.
8. Tasks marked **Gate** require a written entry in the relevant contract section before any code changes. Tasks marked **Candidate** may only start after their gate entry says "proceed"; otherwise close them as "not justified" with the evidence.
9. Tasks marked **Human** are not completable by an agent. Prepare what the task asks and leave the checkbox for the user.

Do not overwrite unrelated working-tree changes.

## Milestone 0 — Discovery gates

- [x] **QDS-001 — Record the current verification baseline**
  - From the repository root, run the offscreen test and the native test (see **Verification commands**). The offscreen runner prints nothing and exits 1 if run from any other directory.
  - Record pass/fail/skip counts in the Completion log. Baseline on 2026-10-27: offscreen 17 passed, 0 failed.
  - Acceptance: later tasks have a known baseline; no source files change.

- [x] **QDS-002 — Inventory repeated visual constants by semantic role** *(Gate for Milestone 1)*
  - Inspect all QML under `dot_config/quickshell/default`.
  - Classify repeated values as spacing, radius, control height, icon size, panel inset, or motion duration/easing.
  - Distinguish genuine shared roles from incidental equal numbers.
  - Write the evidence-backed token table under **Token contract**: token name, value, and the files that consume it.
  - Acceptance: every proposed token lists at least two consumers; context-specific values are explicitly left local.

- [x] **QDS-003 — Inventory interaction states and component consumers** *(Gate for Milestone 1 and the primitive candidates)*
  - Map every use of `ControlButton`, `ControlSlider`, `ControlToggle`, and `GlassSurface`, including `tests/ControlCenterFixture.qml` and `tests/tst_shell-material.qml`.
  - Record required states and local overrides: fonts, dimensions, flat treatment, selected treatment, focus, disabled treatment, accessibility roles.
  - For slider and toggle, state whether any consumer exists outside `components/control`. As of 2026-10-27 none does; only `ControlButton` has consumers in `components/notifications`.
  - Write the result under **Primitive contract**, with a "proceed" or "not justified" decision for each candidate primitive.
  - Acceptance: the button primitive can be implemented without guessing; slider/toggle/card/heading/row candidates each have a decision.

## Milestone 1 — Tokens and the shell-wide button (required)

- [x] **QDS-004 — Add the shell-wide non-color token singleton with its first consumers**
  - Create one singleton in `quickshell/default` only for roles with at least two consumers in the Token contract; register it in `quickshell/default/qmldir` beside `Typography`.
  - Migrate all listed initial consumers of every introduced token in the same change, including both shared motion roles. Preserve durations, easing and guards exactly. Workspace width, toggle thumb and bar reveal motion are singleton roles and remain local.
  - Names are semantic (for example panel inset, fast state transition). No numbered utility scale.
  - Acceptance: every introduced token is read by its at least two listed migrated consumers; low-effects `enabled:` guards are unchanged; offscreen tests pass. Later migrations apply only where an established role matches.

- [x] **QDS-005 — Add token tests**
  - Extend `tests/tst_shell-material.qml` to access the singleton and assert each contracted token is a finite positive number and a representative consumer reads its token. Do not invent ordering rules.
  - Acceptance: missing or invalid named singleton properties and a mismatched clock pill height fail offscreen tests. This does not cover typos in every consumer or prove every binding.

- [x] **QDS-006 — Reassess shared radii**
  - Review remaining radius literals against the token contract and actual semantic consumers; QDS-004 already migrated the initial contracted radii. Migrate only established matching roles or document evidence for any new shared role; leave unrelated and geometry-derived radii local.
  - Acceptance: record the evidence and any justified changes; component geometry unchanged and offscreen tests pass if code changes.

- [x] **QDS-007 — Migrate shared spacing and dimensions in common chrome**
  - Apply tokens to `GlassSurface`, panel chrome, notification chrome, and bar pill chrome. Do not touch page-specific layout spacing.
  - Acceptance: common chrome no longer duplicates the same semantic insets and control heights.

- [x] **QDS-008 — Migrate shared spacing and dimensions in control pages**
  - Apply established tokens where the same role repeats across control-center pages. Keep content-specific spacing local; do not add one-off tokens.
  - Acceptance: no layout regressions at the default panel size or the narrow fixture in `tests/control-center.sh`.

- [x] **QDS-009 — Introduce the shell-wide action button**
  - Create a shared button component outside `components/control`, based on `ControlButton` behavior.
  - Implement only the variants the Primitive contract requires (expected: standard, flat, selected/highlighted, icon-plus-label, optional subtitle, compact icon action).
  - Preserve keyboard activation, focus outline, disabled label treatment, configurable font, and low-effects color transitions.
  - Acceptance: offscreen tests cover normal, hover, focused, selected, flat, disabled, icon, and subtitle states in both themes.

- [x] **QDS-010 — Migrate control-center button consumers**
  - Replace `ControlButton` usage under `components/control`. Preserve dimensions, labels, symbols, focus navigation, and selected-tab behavior.
  - Acceptance: `tests/control-center.sh` and offscreen tests pass.

- [x] **QDS-011 — Migrate notification button consumers**
  - Replace the dismiss, clear, close, and action buttons in `components/notifications`. Keep notification typography via an explicit font property, not a local style override.
  - Acceptance: `test_typographyChangesAreScoped` still proves notification fonts are isolated from control fonts.

- [x] **QDS-012 — Delete `ControlButton`**
  - Remove `components/control/ControlButton.qml`, obsolete imports, and test fixtures that reference it.
  - Acceptance: `rg ControlButton dot_config/quickshell tests docs` returns nothing; no wrapper remains.

## Milestone 2 — Demonstration (required)

- [x] **QDS-013 — Assess a real interactive composition on the foundation**
  - Revised with user approval: use the existing migrated notification action button in `NotificationCard` within `NotificationPanel`, rather than inventing a new element or building the deferred bar tooltip.
  - Inspect the actual token, surface, typography and button composition and record shared versus bespoke styling, state, focus and animation. Use the evidence to reassess the primitive gates.
  - Acceptance: document the real composition and inspect relevant existing offscreen tests, explicitly identifying their limits; do not require a new feature or claim the notification path itself is tested by a button fixture. Theme, low-effects, hidden-bar and missing-service end-to-end behavior remain subject to the existing verification tasks and live matrix.

## Milestone 3 — Evidence-gated candidates

Each candidate starts only if its gate entry in a contract section says "proceed". Otherwise mark it "not justified" with the evidence and move on.

### Primitive candidates (gate: QDS-003 and QDS-013)

- [x] **QDS-014 — Shell-wide slider** *(Candidate; not justified)*
  - Proceed only if a consumer outside `components/control` exists or QDS-013 needed one.
  - Move/generalize `ControlSlider` without changing behavior; preserve disabled, keyboard, drag, focus handle, and wheel pass-through to the parent `Flickable`. Migrate all consumers and delete the old file in the same task.
  - Acceptance: `test_wheelScrollsInsteadOfChangingSlider` passes unchanged; no control-center assumptions remain beyond injected palette/style.

- [x] **QDS-015 — Shell-wide toggle** *(Candidate; not justified)*
  - Same gate as QDS-014. Move/generalize `ControlToggle`; preserve label/subtitle layout, checked animation, disabled treatment, focus outline, low-effects. Migrate all consumers and delete the old file.
  - Acceptance: checked, unchecked, focused, disabled, subtitle, and larger-font tests pass.

- [x] **QDS-016 — Shared card surface** *(Candidate; not justified)*
  - Proceed only if the Token contract shows at least two card families duplicating fill/border/radius/hover/selected expressions. Migrate both in the same task. Do not replace `GlassSurface`.
  - Acceptance: duplicated card-state color expressions are deleted, not wrapped.

- [x] **QDS-017 — Shared section heading** *(Candidate; not justified)*
  - Proceed only if at least two control pages repeat the same heading typography, spacing, and semantics.
  - Acceptance: repeated heading markup reduced; larger-font layouts still correct.

- [x] **QDS-018 — Shared action/list row** *(Candidate; not justified)*
  - Proceed only if at least two pages repeat the same label/subtitle/trailing-control row. Extract the smallest row that deletes duplication; no universal row with unrelated flags.
  - Acceptance: both consumers simpler; the row has a focused test fixture.

### State-locality candidates (gate: QDS-019)

- [x] **QDS-019 — Document the `BarWindow` consumer API** *(Gate)*
  - Map which children consume each `BarWindow` property and function; classify each as window coordination, presentation formatting, service state, or system action.
  - For each extraction candidate below, record under **State contract**: current consumers, the demonstrated cost (duplicated policy, untestable behavior, or edits spanning many files), and "proceed" or "not justified".
  - Acceptance: no extraction task needs to infer consumers from runtime failures.

- [x] **QDS-020 — Pure presentation helpers** *(Candidate)*
  - Move pure formatting (volume/battery icons, text shortening, workspace labels, battery normalization, notification accent/icon/duration) into a testable JS module. Notification formatting belongs here, not in QDS-025. Do not move command execution.
  - Acceptance: boundary and missing-data tests pass; live behavior unchanged.

- [ ] **QDS-021 — Audio state and actions** *(implemented; live verification pending)*
  - Encapsulate sink/source, device lists, labels, default selection, volume, and mute behind one object. Preserve `PwObjectTracker` ownership so tracked nodes stay alive.
  - Acceptance: selection, mute, volume, missing-device fallbacks, and bar indicators work in tests and live.
  - Implementation keeps `PwObjectTracker` in BarWindow with the extracted state's tracked-node list, retains child-facing BarWindow forwarding, and routes bar mutations through the same actions. Offscreen mocks cover filtering, tracking list, selection, mute, clamping, fallbacks and indicator actions; they do not verify PipeWire lifetime or live device behavior. Human live verification remains outstanding; no apply/reload or device actions performed.

- [x] **QDS-022 — Media presentation state** *(Candidate; not justified)*
  - Encapsulate bar player selection, visibility, playback state, and display text. Do not duplicate `MusicPage`'s richer selection policy unless both need the same behavior.
  - Acceptance: player appear/disappear and stopped/playing states correct.

- [x] **QDS-023 — Power and brightness presentation state** *(Candidate; not justified)*
  - Encapsulate battery availability, normalized percent, icon/color, and brightness-control availability. Keep DDC/laptop command execution in the existing state objects in `shell.qml`.
  - Acceptance: no-battery desktops and missing-tool laptops keep current fallbacks.

- [ ] **QDS-024 — Bluetooth and network presentation state** *(Candidate)*
  - Encapsulate Bluetooth adapter/connected/icon/label/tooltip and move network output parsing into a focused object with explicit disconnected, connected, unavailable, and malformed states. Keep the `nmtui` launch action explicit and injectable.
  - Acceptance: parsing covered without running real commands; live status still refreshes.
  - Human live checklist (only after choosing to deploy; do not run during automated review):
    - [ ] Check connected Wi-Fi/Ethernet status and disconnect/reconnect; bar and Quick status update within the 10-second polling interval.
    - [ ] Open Quick → Network and confirm the configured terminal opens `nmtui`; close it without changing settings unless desired.
    - [ ] If safe, check unavailable/missing NetworkManager behavior and recovery; restore the prior service state.

- [ ] **QDS-025 — Overlay coordination owner** *(Candidate; narrowed proceed, verification blocked)*
  - Retain `BarWindow` as the existing per-monitor owner of panel mutual exclusion; do not extract a new owner solely because focus and Escape are local to the panels. Smallest proposed change: remove the redundant `toastVisible = false` from the toast click; its existing `notificationPanelOpen = true` invokes `BarWindow`'s notification-open handler, which closes the toast and controls. Preserve the toast's own dismiss action and the existing local Escape/focus behavior.
  - First establish a safely isolated production-path transition test, including notification arrivals while panels are open, hidden bar, timers and monitor targeting; then verify real Escape and focus in a safely isolated native session. Do not change live shell or weaken assertions. QDS-030's unresolved focus failure and reported hang block claiming the original native sequence acceptance; no implementation until the relevant verification is safe.
  - Acceptance: the toast-to-panel transition has one mutual-exclusion owner and no redundant sibling closure; opening either panel retains existing behavior; detail-first Escape and valid visible focus are verified on the actual native path. Introduce a shared focus helper only with demonstrated repeated policy in both overlays. Full original extraction is not justified by current evidence.

- [ ] **QDS-026 — Narrow page dependencies** *(Candidate; current extractions not justified, audio pending)*
  - Replace broad `required property var bar` with the smallest state/action properties from the proceeding extractions, one component family per change.
  - Shrink the synthetic bar object in `tests/ControlCenterFixture.qml` accordingly.
  - Acceptance: pages instantiate with small doubles; the fixture no longer needs members that the page does not use.

- [ ] **QDS-027 — Reassess `BarWindow`** *(partial; remaining extractions pending)*
  - Delete dead imports, properties, helpers, and trackers left by whichever extractions proceeded. No line-count target.
  - Acceptance: remaining members are window composition or coordination; reassess after QDS-021 and QDS-025, without removing live service state or tracker ownership.

## Milestone 4 — Interaction contract tests

- [x] **QDS-028 — Offscreen state-visibility tests**
  - In `tests/tst_shell-material.qml`, for both themes and `controlOpacity` in {0, 0.37, 1}: keyboard focus is visible (border width 2, accent color) and the selected state is distinguishable by label color at every opacity. Hover is distinguishable at 0.37 and 1; at 0 the hover fill is intentionally invisible—assert that, do not require otherwise.
  - Acceptance: regressions in focus or selected visibility fail offscreen.

- [x] **QDS-029 — Offscreen low-effects and reversal tests**
  - Prove low-effects disables or completes nonessential animations with correct final geometry for glass, button, toggle, and workspace indicator.
  - Rapidly reverse toggle state and selected state; assert final state only.
  - Acceptance: no primitive needs a caller-specific workaround to stop its own animation.

- [ ] **QDS-029 review — Remaining bar motion scope**
  - Status hover reproduced the mid-flight low-effects defect and is covered by the fix and offscreen test. Tray hover now uses the same fix, but its service-bound delegate is not covered by a production-path test. Bar reveal calls `complete()` on a Behavior animation, which the QDS-029 probe found ineffective; its real mask/exclusive-zone path needs an isolated BarWindow fixture.
  - An offscreen production BarWindow probe cannot load: Quickshell reports `No PanelWindow backend loaded` for NotificationToast. The analogous Binding/Behavior correction is plausible, but without a safe production or accurate isolated reveal/mask fixture its behavior and impact on the input region and exclusive zone are unverified; leave production unchanged. A copied Behavior alone would not test those paths.
  - Decide whether a safe, maintainable tray model and pointer test seam and a safely contained BarWindow fixture are justified (coordinate with QDS-030). Do not claim production-path low-effects coverage for either until verified.

- [ ] **QDS-030 — Native transition and focus tests**
  - In `tests/control-center.sh` (requires an unlocked Wayland session): rapid bar show/hide leaves the input mask and exclusive zone consistent; panel open/close reversal leaves focus on a valid control; Escape layering matches QDS-025's stated behavior.
  - Acceptance: the native test fails on an inconsistent final state; the task notes if it could not run.

## Milestone 5 — Documentation and close

- [x] **QDS-031 — Component usage reference**
  - Add a concise design-system section to `docs/hyprland-desktop.md` (or a linked companion document if it would dominate): token ownership, primitive selection, required states, low-effects expectations, and one composition example drawn from QDS-013. Do not list properties obvious from source.
  - Acceptance: a new agent can tell where a token, primitive, or page-specific style belongs without reading the whole shell.

- [x] **QDS-032 — New-component checklist**
  - Document minimum checks: both themes, keyboard focus, pointer, disabled, larger fonts, narrow width, low-effects, opacity extremes, missing service data, and the exact commands/fixtures to run.
  - Acceptance: every item references a real command or fixture.

- [x] **QDS-033 — Full automated verification** *(current run passed; known native intermittency remains open)*
  - Run every command under **Verification commands**. Record results.
  - Acceptance: no unexplained regressions or newly ignored failures.

- [ ] **QDS-034 — Live visual and interaction matrix** *(Human)*
  - Agent prepares: a checklist of dark/light, blur on/off, shell glass on/off, configured transparency on/off, low-effects, hidden bar, narrow/scaled display, larger typography, missing media player, missing optional audio/display devices, and keyboard-only control-center and notification flows.
  - On the live shell, left-click volume, Bluetooth and network with controls closed and already open; check the selected tab is visible on a narrow panel, session confirmation is cleared, and right-click/wheel behavior remains intact. Repeat on each monitor and verify only the clicked monitor's panel responds; note unavailable hardware or monitors.
  - For QDS-020, after the user chooses to deploy the source, verify the actual BarWindow bindings and integration: volume icon across mute/volume changes, workspace labels, battery percentage/icon/color where available, Spotify text and playback states, and notification icon/accent/toast duration (including urgency and missing data where feasible). Check Quickshell logs for binding/runtime errors and note unavailable services or hardware. Automated helper and panel tests use doubles and do not instantiate BarWindow.
  - User performs the checks on the live desktop and records results in the Completion log.
  - Acceptance: user-recorded results; environment-limited checks noted.

  **Human checklist** (after choosing to deploy the source; record pass/fail and unavailable cases):
  - [ ] Check dark and light themes; blur on/off; shell glass on/off; configured transparency on/off; low-effects; hidden bar; narrow/scaled display; and larger typography.
  - [ ] Check missing media player and optional audio/display devices; note unavailable hardware.
  - [ ] Exercise control-center and notification flows using only the keyboard, including focus and Escape.
  - [ ] On each monitor, left-click volume, Bluetooth and network with controls closed and already open. Confirm the intended tab is visible on a narrow panel, session confirmation clears, and only the clicked monitor's panel responds; note unavailable monitors.
  - [ ] Check volume and Bluetooth right-click behavior and volume wheel adjustment remain intact.
  - [ ] Verify actual BarWindow bindings: volume icon through mute/volume changes; workspace labels; battery percentage/icon/color where available; Spotify text and playback states; notification icon, accent and toast duration, including urgency and missing data where feasible.
  - [ ] Check Quickshell logs for binding/runtime errors; note unavailable services or hardware and record results in the Completion log.

- [ ] **QDS-035 — Remove migration residue and close**
  - Search for obsolete component names, unused imports, duplicate token literals, wrappers, stale comments, dead fixtures. Update the contract sections to describe the final boundaries and any deliberately retained local styling.
  - Acceptance: one supported path per migrated primitive; this plan matches the resulting system.

## Improvements

- [ ] **Focus-loss dismissal for control and notification centers** — Investigate closing a center when its window loses focus, without intercepting the click or stealing focus back. Arm dismissal only after activation; verify live whether desktop, other layers, pointer-follow focus and other monitors produce acceptable behavior. Focus loss is not guaranteed to detect every outside click. Address the rapid-toggle hang before live testing this improvement.

- [x] **QDS-036 — Route bar status indicators to control-center categories**
  - Left-clicking volume opens Audio; left-clicking Bluetooth or network opens Quick. Always leave the panel open and select the requested category, including when another category is already open.
  - Preserve existing right-click behavior, including volume mute and Bluetooth's external-tool action, and preserve volume wheel adjustment.
  - Use existing category-selection and overlay coordination behavior; retain keyboard shortcuts and per-monitor behavior. Update focused tests and `docs/hyprland-desktop.md`; verify missing-service behavior and record live checks or skips.
  - Acceptance: each indicator left-click opens the intended category without launching an external tool; right-click, volume wheel, and existing panel navigation continue to work.

- [ ] **Wi-Fi and Bluetooth radio verification** *(implementation present; human verification pending)*
  - Quick tiles toggle the radios; their right-click, Menu-key and Shift+F10 menus open settings, as do separate settings buttons. Disabled tiles cannot open their menus; settings actions require loaded, non-busy desktop settings and the corresponding tool. Escape dismisses an open menu before closing controls. Bar network right-click has no action; bar Bluetooth right-click is a separate direct launcher.
  - Requests are shared across monitors. After 5 seconds without a matching property change, the error appears but the request remains pending and the tile disabled; a late match clears it. Wi-Fi backend loss or Bluetooth adapter replacement clears its request. Backend signals may be optimistic and Networking's constant backend may not reflect service loss; timeout is not proof of failure. Inspect the backend and ensure any old operation has ended before restarting the shell to forget a stuck request.
  - Offscreen delayed doubles cover pending, timeout, late match and replacement; the native fixture invokes mocked clicks directly. Neither establishes menu pointer/key delivery, real backend confirmation or multi-monitor integration. After choosing to deploy, the user should verify both menus via right-click, Menu and Shift+F10, Escape, separate settings buttons, unavailable tools and blocked/missing radios, and observed radio state across available monitors. Do not perform live actions during automated review.

  **Human radio and audio checklist** (after choosing to deploy; record results and unavailable cases; restore prior settings):
  - [ ] Toggle Wi-Fi and Bluetooth tiles and confirm actual radio state and consistent status on each available monitor. Check blocked/missing radios and unavailable tools where safe.
  - [ ] For both tiles, open settings menus by right-click, Menu and Shift+F10; check Escape dismisses the menu first and separate settings buttons work. Note pending/timeouts and late confirmations without restarting while an operation may still be running.
  - [ ] Check audio output/input lists and defaults, switch devices where available, adjust volume and mute, and confirm bar indicators and right-click/wheel behavior. Check missing-device fallbacks and restore prior selections and levels.
  - [ ] Check Quickshell logs for binding/runtime errors; note unavailable hardware and record results in the Completion log.

- [ ] **Night-light temperature control** *(requested; blocked, not implemented)*
  - Current code has only on/off: `hyprsunset.sh` starts `hyprsunset -t 4000` when no same-UID daemon is detected, and does not change an existing daemon's temperature. Status/import and stopping use same-UID process names, not session identity; disable can signal another session's daemon. The 4000 K subtitle is not evidence of an imported daemon's actual temperature.
  - A proposed persisted temperature and runtime update must not silently apply a default to an imported daemon or address the wrong session. Existing rollback restores the preference but suppresses runtime reapply errors, so it cannot prove runtime restoration. Establish session ownership, existing-daemon migration and failure/rollback policy before implementation; do not treat a hypothetical `hyprctl` temperature update as current behavior.
  - `tests/session-preferences.sh` mocks commands but inherits display and D-Bus inputs unless run in an isolated environment; its fixed 1600 ms assertion and 8 s timeout cannot identify slow startup versus a hang. The exit 255 was reproduced and fixed in an isolated environment; see Completion log. Bounded tests for multiple sessions, imported temperatures and failed rollback remain outstanding. Do not launch the fixture against a live session.

- **Accessible bar status tooltips (deferred):** convenient volume, Bluetooth, battery and network details at their indicators, reachable by pointer and keyboard, would also demonstrate the foundation in a new area. The short, masked bar `PanelWindow` has no keyboard entry path; a tooltip outside it requires a separate surface/window and a non-disruptive keyboard focus-entry and exit policy that does not steal focus from applications. Define hidden-bar and overlay coordination before implementation. Component tests alone cannot prove desktop reachability.
- **Possible panel demonstrations, pending a concrete need:** expose more battery details in Quick when available, or improve access to status details currently shown as button subtitles. First establish which information is missing or inaccessible and confirm the relevant service data and interaction; do not add a duplicate action solely to demonstrate the foundation.

## Token contract

Owned by QDS-002. Record only roles with at least two consumers. Format: token, value, consumers.

All paths below are relative to `dot_config/quickshell/default/components/`; values are logical pixels except durations in ms. These are initial consumers, not a license to replace every equal literal. QDS-004 migrates all listed uses when introducing these roles.

| Token | Value | Consumers and shared role |
|---|---:|---|
| panelRadius | 26 | `control/ControlPanel.qml`, `notifications/NotificationPanel.qml`, `notifications/NotificationToast.qml` — outer overlay surfaces |
| barIndicatorRadius | 10 | `bar/StatusIndicators.qml`, `bar/SystemTraySection.qml` — interactive bar indicator backgrounds |
| deviceCardRadius | 12 | `control/AudioDeviceControl.qml`, `control/DdcBrightnessControl.qml`, `control/LaptopBrightnessControl.qml` — device cards |
| deviceCardInset | 12 | `control/AudioDeviceControl.qml`, `control/DdcBrightnessControl.qml`, `control/LaptopBrightnessControl.qml` — content inset (24 added to implicit height) |
| controlPageSpacing | 12 | `control/QuickPage.qml`, `control/AudioPage.qml`, `control/AppearancePage.qml`, `control/DisplayPage.qml`, `control/SystemPage.qml` — top-level page spacing |
| barItemSpacing | 3 | `bar/WorkspacePill.qml`, `bar/RightPill.qml`, `bar/StatusIndicators.qml`, `bar/SystemTraySection.qml` — bar item gaps |
| barPillHeight | 36 | `bar/WorkspacePill.qml`, `bar/ClockPill.qml`, `bar/RightPill.qml`, `BarWindow.qml` — outer pill height and reserved bar height |
| barIndicatorHeight | 24 | `bar/StatusIndicators.qml`, `bar/SystemTraySection.qml` — indicator target height |
| notificationAppIconSize | 28 | `notifications/NotificationCard.qml`, `notifications/NotificationToast.qml` — app icon width and height |
| notificationActionMinHeight | 32 | `notifications/NotificationCard.qml`, `notifications/NotificationToast.qml` — compact notification actions; retain content-dependent growth |
| surfaceColorDuration | 140 | `GlassSurface.qml`, `control/ControlButton.qml` — low-effects-guarded surface color transitions, default easing |
| barStateColorDuration | 120 | `bar/WorkspacePill.qml`, `bar/StatusIndicators.qml`, `bar/SystemTraySection.qml` — low-effects-guarded bar hover and workspace selection color transitions, default easing |

Leave local: panel insets differ (toast 16, notification panel 20, control panel has its own layout); button radius 14, generic glass/card radius 18, and 16-radius appearance/quick cards do not establish a shared stateful card role. Geometry-derived circles remain local. Typography owns font/icon sizes; equal icon and control dimensions in unrelated contexts are incidental. Workspace width animation (180/OutCubic), bar reveal (200/OutCubic), and toggle thumb (100/default easing) each have one consumer: do not create motion or easing tokens for them. Other page-specific gaps and individual control heights stay local.

## Primitive contract

Owned by QDS-003, updated by QDS-013. Record required variants, state behavior, and a decision per candidate.

| Candidate | Consumers outside `components/control` | Decision | Evidence |
|---|---|---|---|
| Shell-wide button | notifications (card, toast, panel) | proceed | Same `ControlButton` already used across areas; preserve contract below. |
| Slider | none | not justified | All production uses are in control; the notification action composition needs no slider. |
| Toggle | none | not justified | All production uses are in control; the notification action composition needs no toggle. |
| Card surface | notifications and control have different families | not justified | `NotificationCard.qml` and `control/AudioDeviceControl.qml` use different geometry/borders; `QuickPage.qml` and `AppearancePage.qml` do not share hover/selected expressions. No two families duplicate the full required state treatment. |
| Section heading | none | not justified | `control/AppearancePage.qml` alone defines the `controlHeadingFont` heading component; no second page repeats that heading contract. |
| Action/list row | none | not justified | `control/ControlToggle.qml` owns toggle label/subtitle layout; `AppearancePage.qml` wallpaper row and `AudioDeviceControl.qml` device header have different structure and behavior, not two repeated page rows. |

**Complete use map.** Paths are relative to `dot_config/quickshell/default/components/` unless prefixed `tests/`. Counts include repeated declarations and delegates; a delegate can produce multiple instances.

- Button: `control/AudioDeviceControl.qml` (4), `control/ControlPanel.qml` (7), `control/AppearancePage.qml` (3), `control/DisplayPage.qml` (1), `control/MusicPage.qml` (4), `control/QuickPage.qml` (8), `control/SystemPage.qml` (7); `notifications/NotificationCard.qml` (2), `notifications/NotificationToast.qml` (1), `notifications/NotificationPanel.qml` (2). `tests/tst_shell-material.qml` directly creates control and notification-font buttons; `tests/ControlCenterFixture.qml` instantiates `ControlPanel` and exercises its buttons indirectly.
- Slider: `control/AudioDeviceControl.qml`, `control/DdcBrightnessControl.qml`, `control/LaptopBrightnessControl.qml`, `control/AppearancePage.qml`, `control/MusicPage.qml`, `control/QuickPage.qml` (one declaration each); `tests/tst_shell-material.qml` directly creates one, fixture indirectly through panel pages.
- Toggle: `control/ControlPanel.qml` (1), `control/AppearancePage.qml` (4), `control/DisplayPage.qml` (2); fixture indirectly through panel pages; no direct toggle in `tests/tst_shell-material.qml`.
- Glass: `control/ControlPanel.qml`, `notifications/NotificationToast.qml`, `notifications/NotificationPanel.qml`, `bar/ClockPill.qml`, `bar/RightPill.qml`, `bar/WorkspacePill.qml`; `tests/tst_shell-material.qml` directly creates one, fixture indirectly via panel.

**Button implementation contract.** `control/ControlButton.qml` uses Qt `Button` semantics (including Space and explicit Enter/Return), required `wallust`, `text`, `symbol`, `subtitle`, `highlightedState` defaulting to `checked`, `flat`, and caller-supplied font. Default height is max(36 or 68 with subtitle, content plus vertical padding); minimum width 60, padding 12 horizontal/8 vertical, radius 14. Selected fill/text use `barActive`/`barAccentText`, hover `barButtonHover`, flat otherwise transparent, standard `barCard`; focus border 2 accent versus 0 flat or 1 separator. Disabled labels/glyphs fade to 0.55; background stays opaque for control-center palette, otherwise fades to 0.55. Color transition 140 ms is disabled in low-effects. Glyph and subtitle use control tile-icon and hint fonts; default label switches control label/emphasis font. Preserve per-caller geometry and explicit font, including 40px-or-growing mute icons (`QuickPage.qml`, `AudioDeviceControl.qml`), 52px music actions, notification 32px-or-growing actions with `notificationActionFont`, and notification panel `centerButtonFont`. Category tabs use custom contents, `Accessible.PageTab` and selected; appearance theme buttons are flat radio buttons with checked metadata, wallpaper is flat; other named icon actions supply `Accessible.name`. Preserve default Button role unless a caller overrides it, focus navigation, plain text, and Qt pressed/keyboard behavior rather than inventing a pressed fill.

**Other states.** `control/ControlSlider.qml`: Qt Slider role, 0–100 step 1 defaults, 28 height, focus handle 16 versus 12 with border, drag/keyboard, `wheelEnabled: false` so parent scrolls; callers provide names, ranges and disabled bindings. `control/ControlToggle.qml`: Qt Switch role, label/subtitle, 42/58 minimum heights with content growth, hover and 2px focus outline, checked/unchecked track and animated thumb (100 ms, low-effects guarded), disabled track/label opacity. `GlassSurface.qml`: shared material, radius 18 default overridden to 26 by overlays, edge highlights and low-effects-guarded hover color; not a button or replacement for cards. Keep caller palette, sizing and accessibility overrides.

## State contract

Owned by QDS-019. The map describes the current tree, not a proposed API. Names below are relative to `dot_config/quickshell/default/components/`; `bar/`, `control/` and `notifications/` are abbreviated B, C and N. A passed `bar` is the same `BarWindow`, not a separate state object. `RightPill` forwards it to `StatusIndicators`, `WorkspacePill` to `SpotifyPill`, `ControlPanel` to its pages, `AudioPage` to `AudioDeviceControl`, Quick/Display to brightness controls, and `NotificationPanel` to `NotificationCard`. MusicPage uses its own MPRIS policy, not `bar`. The control fixture substitutes a synthetic bar.

**Child-facing member map** (classification follows use; actions can also change service state):

| Class | Members → consumers |
|---|---|
| Window coordination | inherited `screen`, `height`, `barVisible` → C/ControlPanel, N/NotificationPanel, N/NotificationToast; `barVisible`, `setBarVisible` signal → C/AppearancePage; inherited `width` → B/ClockPill, B/WorkspacePill; `hyprMonitor` → B/WorkspacePill; `controlPanelOpen` → C/ControlPanel, AppearancePage, SystemPage, B/StatusIndicators, N/NotificationToast; `notificationPanelOpen` → N/NotificationPanel, NotificationToast; `toastVisible` → N/NotificationToast; `sessionRequested`, `categoryRequested` signals → B/StatusIndicators, C/ControlPanel. |
| Presentation formatting | `workspaceText` → B/WorkspacePill; `volumeIcon` → B/StatusIndicators, C/QuickPage, AudioDeviceControl; `batteryIcon`, `batteryTextColor` → B/StatusIndicators; `notificationAccent`, `notificationIcon` → N/NotificationToast, NotificationCard. |
| Service state | `desktopState` → C/ControlPanel, QuickPage, AppearancePage, DisplayPage, SystemPage, B/StatusIndicators; `defaultAudioSink` → B/StatusIndicators, C/QuickPage, AudioPage; `defaultAudioSource`, `audioOutputDevices`, `audioInputDevices` → C/AudioPage; `sinkVolume`, `sinkMuted` → B/StatusIndicators; `bluetoothIcon`, `bluetoothLabel` → B/StatusIndicators; `bluetoothAdapter`, `bluetoothTooltip`, `networkStatus` → C/QuickPage; `displayBattery`, `batteryPercent`, `hasBattery` → B/StatusIndicators (percent/availability also C/QuickPage); `showLaptopBrightnessControl`, `ddcBrightnessState` → C/QuickPage, DisplayPage (DDC also ControlPanel, SystemPage); `laptopBrightnessState` → C/LaptopBrightnessControl, ControlPanel, DisplayPage, SystemPage; `spotifyVisible` → B/WorkspacePill, SpotifyPill; `spotifyDisplay`, `spotifyPlayer` → B/SpotifyPill; `notificationCount`, `notifications` → N/NotificationPanel. `networkState` is separately passed via B/RightPill to B/StatusIndicators (`icon`); QuickPage gets its tooltip through `networkStatus`. |
| System actions | `runCommand` → B/ClockPill, StatusIndicators, C/ControlPanel, QuickPage, AppearancePage; `runHyprScript` → C/AppearancePage; `launchTerminal`, `launchTerminalShell` → C/SystemPage; `launchNetworkTui` → B/StatusIndicators, C/QuickPage; `setDdcBrightness` → C/DdcBrightnessControl; `setLaptopBrightness` → C/LaptopBrightnessControl; `audioNodeLabel`, `isDefaultAudioDevice`, `setDefaultAudioDevice`, `setAudioDeviceVolume`, `toggleAudioDeviceMute` → C/AudioDeviceControl (last two also QuickPage); `clearNotifications` → N/NotificationPanel. Audio label/default checks are service-dependent queries, not commands. B/StatusIndicators also directly mutates sink volume/mute; B/SpotifyPill calls player methods directly. |

**Other members and ownership.** `shell.qml` supplies `screen`, `notifications`, the three toggle generations, `desktopState`, `barVisible`, `focusedHyprMonitor`, and both brightness state objects; it handles `setBarVisible`. BarWindow internally owns `pillMargin`, `barReveal`, `barInteractive`, its mask, colors and clock; toggle generation handlers use `isFocusedMonitor`, update panel flags and emit `sessionRequested`. Its toast connections/timer use `showNotificationToast`, `notificationToastDuration`, `toastNotification` (also bound into N/NotificationToast), quiet state and overlay flags. `workspaceGlyphs` feeds `workspaceText`; `audioDevices` feeds device lists and `audioTrackedNodes` feeds the local `PwObjectTracker`; `bluetoothConnectedCount` feeds Bluetooth presentation; `normalizeBatteryPercent` feeds `batteryPercent`; `spotifyTextForPlayer` and `shorten` feed `spotifyDisplay`. `runShell` backs terminal helpers; `networkState.update`, the process and timer own network refresh. `sourceMuted`, `sourceVolume`, and `spotifyPlaying` were removed after no child or internal reads were found. Inherited PanelWindow members not listed are used for window composition, not a custom child contract.

| Candidate | Consumers and demonstrated cost | Decision and intended owner |
|---|---|---|
| Pure presentation helpers | Formatting above plus battery normalization, Spotify text and toast duration are embedded in a service-bound PanelWindow, so boundary/missing-data tests require a shell/window seam. | **proceed** — focused JS formatting module; inject enum values, palette and icon resolution as needed. `notificationIcon` calls `Quickshell.iconPath`, so keep resolution at the QML boundary rather than claim it is pure. No command execution. |
| Audio | B/StatusIndicators and C/QuickPage/AudioPage/AudioDeviceControl share devices and actions; status indicator duplicates mute and clamped volume policy rather than using existing methods. Tracker lifetime is currently owned by BarWindow. | **proceed** — one audio state/action owner with tracker ownership preserved; migrate both direct mutations and consumers. |
| Media | B/WorkspacePill and SpotifyPill share the existing Spotify-only selection; MusicPage intentionally has different richer policy. No duplicated selection or specific untestable behavior beyond formatting above demonstrated. | **not justified** — keep selection in BarWindow; formatting may move under QDS-020. |
| Power/brightness | B/StatusIndicators and C/QuickPage share battery values; brightness controls use existing shell-owned state and action wrappers. No duplicated policy or independent test seam demonstrated beyond normalization/icon formatting. | **not justified** — retain service ownership; QDS-020 can test pure battery formatting. |
| Bluetooth/network | B/StatusIndicators and C/QuickPage share status; `networkState.update` is embedded beside a live `nmcli` process and currently treats malformed output as disconnected, while failures become unavailable. Parsing distinct cases cannot be tested independently through the existing control fixture. Bluetooth alone has no comparable demonstrated cost. | **proceed** for a focused injectable network parsing/state seam; retain Bluetooth in BarWindow unless independent evidence justifies moving it. Preserve existing visible fallbacks; do not silently claim malformed output already has a distinct state. Keep `nmtui` explicit. |
| Overlay coordination | `BarWindow.qml:121–149` already owns per-monitor toggle handling and panel-open mutual exclusion; indicator/page flag writes request a panel transition or close their own panel, not independently implement sibling exclusion. `notifications/NotificationToast.qml:52–55` alone redundantly clears its own toast before opening history, whose BarWindow handler already clears it. `control/ControlPanel.qml:114–117` owns detail-first Escape and its local focus targets; `notifications/NotificationPanel.qml:32–45` focuses Close and handles its own Escape. Different local detail policies do not demonstrate a shared focus helper. | **proceed narrowly** — preserve BarWindow as owner and propose only removing the redundant toast-click clear, subject to safe production-path verification; no separate coordinator or focus extraction justified. This is a demonstrated duplicate write, not proof of a user-visible bug or that it causes the reported hang. Full native acceptance remains blocked by QDS-030. |

**QDS-026 gate reassessment.** QDS-020's pure JS helpers do not provide a page state owner: QuickPage and AudioDeviceControl still need audio state and actions. QDS-024's network object is passed to StatusIndicators, but QuickPage only reads `bar.networkStatus` and calls `bar.launchNetworkTui`; passing the object plus the action would replace one fixture string with an object without removing the bar dependency or shrinking the shared fixture. QuickPage also needs battery, Bluetooth, desktop, audio and brightness; Appearance, Display and System need desktop plus separate actions or brightness; AudioPage forwards the bar to AudioDeviceControl. ControlPanel itself needs window coordination and loads all these pages, so per-page property lists alone would not eliminate the fixture's union of members. MusicPage already has no bar dependency. No narrow migration from the actual QDS-020/024 extractions is justified now; revisit the audio family after QDS-021 supplies a real owner, and overlay only if QDS-025 changes ownership. QDS-024 still awaits human live verification.

**QDS-027 gate reassessment.** Repository-wide references found no reads of `sourceMuted`, `sourceVolume` or `spotifyPlaying`; remove those independent derived properties, not the still-used source, player, `PwObjectTracker`, formatting wrappers, network process or timer. QDS-021 remains unimplemented and QDS-025 blocked, so their possible dead members and the broader composition/coordination acceptance cannot yet be assessed as complete. Existing service state remains in BarWindow by the QDS-022/023 decisions and pending audio work.

**QDS-025 gate reassessment.** Toast behavior is subtler than three mutually exclusive booleans: `BarWindow.qml:407–417` can set `toastVisible` and restart its timer while a panel is open; `NotificationToast.qml:16,29–33` suppresses the actual window and stops its timer when it becomes invisible. Do not replace this with a single exclusive enum or silently change notification arrival, quiet/critical handling, hidden-bar behavior, timer ordering, category/session requests, or per-monitor fallback. Opening a panel clears the toast flag, but a subsequent notification can set it while suppressed; preserve and test the current transitions rather than assume the flag is always false. On hiding the bar, BarWindow closes notification history and toast but leaves controls available. Local focus on panel opening is not restoration to the originating application or proof of active Wayland focus.

The smallest proposed edit relies on the synchronous QML change handler when history changes from closed to open; validate the real click path and repeated/open-state cases before changing it. A focused test must distinguish the real BarWindow handler from the synthetic bar in `tests/ControlCenterFixture.qml`; the fixture calls `dismissDetails()` directly (lines 328–329), and its reversal assertion (lines 361–368) is not real Escape or cross-overlay coverage. The historical QDS-030 diagnosis reproduced inactive/null focus in 6/8 runs and 3/6 with only one reopen; one later pass and QDS-033's pass do not resolve it. Real key delivery, production BarWindow isolation and safe containment remain open, and the reported rapid-toggle live hang must not be reproduced on the user's desktop.

## Verification commands

Run from the repository root, `/home/athe/.local/share/chezmoi`. The offscreen runner prints nothing and exits 1 from any other directory.

```bash
QT_QPA_PLATFORM=offscreen QT_QUICK_CONTROLS_STYLE=Basic \
  /usr/lib/qt6/bin/qmltestrunner -input tests/tst_shell-material.qml

bash tests/workspace-effects.sh    # offscreen Quickshell workspace delegate fixture

bash tests/control-center.sh      # needs an unlocked Wayland session; skips otherwise
bash tests/desktop-settings.sh
bash tests/session-preferences.sh
hyprctl configerrors              # live session only
```

After applying QML changes:

```bash
chezmoi apply
~/.config/hypr/scripts/quickshell-reload.sh
```

Offscreen tests are proxies. Final verification is the live shell (QDS-034).

## Risks

- **Token overreach:** tokenize semantic repetition only; incidental equal numbers stay local.
- **Generic-component overreach:** two focused components beat one with many flags; the gates exist to stop this.
- **Visual drift during migration:** preserve values exactly; appearance changes are separate, explicit tasks.
- **Service lifetime:** Quickshell trackers (`PwObjectTracker`, MPRIS, UPower) need stable ownership; verify live after any state extraction.
- **Focus regressions:** component moves can change focus scopes and Escape handling; keep native tests attached to each migration.
- **Generated-file confusion:** Wallust owns generated colors; tokens are hand-maintained and unaffected by wallpaper refresh.
- **Plan staleness:** contracts and the Completion log must be updated whenever evidence changes a boundary.

## Completion definition

1. The existing notification action composition demonstrates shared tokens and the shell-wide button without importing control-center-specific components; this is evidence for an extension path, not a requirement to add new UI.
2. QDS-013's existing demonstration and its bespoke-versus-composed assessment are documented; relevant tests and their limits are identified.
3. Every Milestone 3 candidate is either implemented with its consumers migrated and the old code deleted, or closed as "not justified" with evidence.
4. Focus and selected states are provably visible at every control opacity; low-effects and reversal behavior are tested.
5. The user has recorded the live matrix results.
6. Documentation identifies the supported extension path.

## Completion log

Add one entry per completed task: date, task ID, what was verified, what was skipped and why, deviations from the plan.

- 2026-10-27 — QDS-033 final automated run: offscreen material 38 passed, 0 failed, 0 skipped; workspace effects, native control-center, desktop-settings and session-preferences all passed (exit 0); read-only `hyprctl configerrors` returned no errors and `git diff --check` passed. Expected mocked failure/rollback and usage messages appeared in the settings suites. Tests used disposable HOME/XDG and invalid D-Bus addresses; offscreen/session fixtures had no live display, and native used the unlocked Wayland connection with mocked actions. This run had no observed intermittency, but historical native focus failures remain unresolved (QDS-030); a single pass does not establish reliable focus or production BarWindow behavior. Fixtures are proxies; real radios, audio, menus, multi-monitor behavior and live visual checks remain for the human checklist. No apply, reload or real radio actions; no code changes.

- Session-preferences exit 255 diagnosis: reproduced with empty environment, offscreen Qt, disposable HOME/XDG and invalid session/system buses; retained trace and Quickshell log at `/tmp/session-diagnose.rrN4iU`. The `write` fixture failed to load: `RadioState is not a type`. The extracted inhibitor block inadvertently included the newer unrelated RadioState; this is not the expected simulated night-light failure or an 8-second timeout. Extracted DesktopState and the actual inhibitor block separately, and report Quickshell logs on nonzero exit. Three retained-log isolated runs and the original test path passed; expected mocked failure messages remain. The fixture still uses fixed timing and inherited environment unless externally isolated; logs do not prove the historical run had the same cause. No real services/devices, native session, deployment or reload; QDS-033 remains open pending its full suite.

- 2026-10-27 — QDS-033 current run (incomplete): from the repository root, offscreen material returned 38 passed, 0 failed, 0 skipped (exit 0); workspace effects passed (exit 0); desktop-settings passed (exit 0, with expected simulated rollback/usage messages); native control-center passed (exit 0, unlocked Wayland, mocked radio actions); read-only `hyprctl configerrors` produced no output (exit 0); `git diff --check` passed (exit 0). Session-preferences failed (exit 255): output ended with `hyprsunset failed to start` and `Could not apply night-light; restored previous preference.` These messages also occur in an intentional failure test; the failing stage and cause are unknown because the script removes its fixture logs on exit. It ran with an empty inherited environment, disposable HOME/XDG runtime/config/cache/data, and invalid session/system bus addresses; its own mocked commands and disposable state remained in use. Native fixture used disposable HOME/XDG config/cache/data/state and invalid buses, retaining the live Wayland connection; it does not establish real radio or BarWindow behavior. No live radio actions, deploy or reload. The failure is not explained or ignored; QDS-033 remains unchecked. QDS-030 focus and live verification remain open regardless of this native pass.

- Radio and night-light documentation review (partial): compared QuickPage, RadioState, bar indicators, radio fixtures and night-light scripts by inspection. Recorded actual menu, timeout and verification boundaries, and distinguished existing same-UID process risks from proposed temperature-update risks. No tests, fixture launches, apply, reload or live actions; real backend and menu delivery remain unverified.

- Night-light backend security review (blocked, not complete; clarification): current `hyprsunset.sh` detects and signals all same-UID daemons; another session's daemon may be stopped. It does not currently update an existing daemon's temperature: the proposed `hyprctl` update would target the current Hyprland session, and a proposed 4000 K import default applied at startup could silently change an existing daemon. These are risks of the proposed feature, not behavior in the current tree. Rollback suppresses runtime reapply errors, so restoring the file does not prove restoration of runtime state. A safe session-identity and existing-daemon migration policy is not established; do not deploy or claim these issues fixed. `tests/session-preferences.sh` mocks process commands but its Quickshell fixture inherits real display and D-Bus environment, unlike `tests/workspace-effects.sh`; its fixed 1600 ms assertion and 8 s timeout can also obscure slow startup versus a hang. Timeout cause is unconfirmed: no fixture was launched because its current containment is insufficient for the no-live-actions constraint. Next isolate all display/bus/XDG inputs and retain failure logs, then reproduce with bounded runs and design tests for multiple sessions, imported temperatures and failed rollback before implementing. No live commands, tests, apply or reload were run.

- QDS-026/027 reassessment (partial): inspected actual page bindings, panel loading, shared fixture, BarWindow and repository references. No current narrow dependency reduces the fixture or removes the bar; audio/overlay prerequisites remain open. Removed three unreferenced derived properties; no tracker or service ownership changed. Static reference review and diff check only; no production BarWindow or live verification, apply, reload or compositor interaction.

- QDS-025 gate reassessment (plan only, incomplete): inspected current BarWindow, toast, panel and fixture sources and prior QDS-030/QDS-033 evidence. Narrowed proceed to the redundant toast-click write; existing BarWindow already owns exclusion, while local Escape/focus does not justify a new coordinator or common helper. Identified suppressed-toast/timer and hidden-bar semantics and the unresolved safe native verification prerequisite. No tests run, implementation, apply, reload, compositor command or live-shell interaction; historical test results are evidence, not a new run. QDS-025 remains unchecked.

- 2026-10-27 — QDS-033: user confirmed the deployed scroll fix works live; this is not confirmation of the full QDS-034 matrix. From the repository root: offscreen material 34 passed, 0 failed, 0 skipped (exit 0); workspace effects passed (exit 0); native control-center fixture passed (exit 0) with an active, unlocked Wayland session; desktop-settings passed (exit 0); session-preferences passed (exit 0); `hyprctl configerrors` produced no errors (exit 0); `git diff --check` passed (exit 0). Desktop-settings and session-preferences printed expected simulated failure/rollback and usage messages from their isolated tests, not suite failures. No unexplained failure in this run; the previously intermittent native focus failure is not resolved by one passing run, and QDS-029 review and QDS-030 remain open. Fixtures are proxies, not full live integration. No apply, reload, or deliberate rapid toggling of the live shell; QDS-033 complete, broader plan and human matrix remain incomplete.

- QDS-029 bar reveal review (incomplete): inspected the production Behavior, `barInteractive`, mask and exclusive-zone bindings against the workspace Binding/Behavior workaround. A disposable, bus-isolated offscreen Quickshell probe of production BarWindow failed to load because no PanelWindow backend is available. No reveal fix or copied-behavior test was added without a reliable mask/exclusive-zone seam; no compositor contacted. Material suite 38 passed; workspace fixture passed; native control-center deliberately skipped with Wayland unset; `git diff --check` passed. These tests do not cover bar reveal.

- 2026-10-27 — QDS-029 review (partial): applied the existing status Binding/Behavior fix to tray hover. Material suite 33 passed, including status hover reversal and re-enable; workspace fixture passed; `git diff --check` passed. These are proxies, not a tray delegate regression test. A model seam alone cannot deliver pointer events in the isolated Quickshell fixture; a safe, maintainable production-path fixture was not established, so no seam was added and tray verification remains open. The five status backgrounds retain their local IDs and markup: extracting a component solely for this pattern would add an API/file and obscure local bindings. Bar reveal and native/live checks remain untouched; no apply, reload, or live interaction.

- QDS-029 review: reproduced status hover remaining mid-animation after low-effects; fixed all five indicators using the existing Binding/Behavior pattern and added real pointer-based offscreen coverage, including re-enabling. Workspace runner now uses an empty environment, disposable HOME/XDG directories and invalid bus addresses; its fixture retries missed intermediate frames with a bounded limit. Material suite 33 passed; workspace passed three runs with hostile inherited bus/Hyprland variables; desktop-settings and session-preferences passed; `git diff --check` passed. Native control-center intentionally skipped with Wayland unset; `hyprctl` skipped. Tray and bar reveal remain open as described above: service-bound tray needs a model seam; testing the real BarWindow safely needs the QDS-030 isolation work. No live session, compositor, apply or reload.

- Date not recorded — QDS-031: documented actual token, typography, palette and primitive ownership, interaction expectations and the existing notification composition in `docs/hyprland-desktop.md`. Checked against source and existing contracts by inspection; automated and live checks skipped under the no-shell constraint. No apply/reload; no scope deviation.
- Date not recorded — QDS-032: documented fixture-specific commands, coverage limits, open QDS-029/030 failures and the QDS-034 live boundary in `docs/hyprland-desktop.md`. Checked fixture names and runner by inspection; commands and live checks not run under the no-shell constraint. No apply/reload; no scope deviation.

- QDS-030 isolated reproduction safety assessment (incomplete): no compositor or shell launched, and no toggle attempted. Production Hyprland autostart/shutdown starts user services and uses broad `pkill`; exclude that config entirely. Shell startup runs DDC/backlight discovery; `DesktopState` status initializes preference files, invokes `hyprctl`, then restores night light via a helper that can signal same-UID `hyprsunset`. BarWindow connects PipeWire and system-bus services; a private session bus and disposable HOME/XDG alone do not isolate these or hardware. A bounded `timeout 5 unshare --user --map-root-user --pid --fork /bin/true` and `timeout 5 bwrap --unshare-user --unshare-pid --ro-bind / / --proc /proc --dev /dev /bin/true` both exited 0; this proves namespace availability only, not safe nesting, socket isolation, process cleanup or reproduction. Stopped before launch: no verified containment design yet for the outer Wayland connection, system bus/PipeWire, hardware discovery, compositor sockets and descendant cleanup together. Next establish and independently verify those boundaries with a disposable config and non-production service substitutes before testing; preserve the actual toggle path and label any substituted behavior. No apply/reload, live socket command, service action, hardware change or real settings change.

- QDS-030 live investigation (incomplete): user reported Quickshell stuck and bar missing after rapid control-center toggling; bar returned after restart, and normal Tab and Escape worked. Historical logs show repeated Wayland text-input focus warnings but do not establish causation. Later logs no longer showed earlier undefined token assignments. Do not repeat rapid toggles on the live desktop; investigate in an isolated session if possible.

- 2026-10-27 — QDS-013 and QDS-014–018 gate reassessment: with user approval, replaced the new-element requirement with the existing notification action composition; documented the shared/bespoke boundaries in `docs/hyprland-desktop.md`. Source and existing fixtures inspected: button state/input tests pass in both themes and typography isolation passes, but they instantiate a standalone button, not NotificationCard or action invocation. Slider and toggle remain control-only and are not needed by the demonstration; card, heading and row evidence remains insufficient, so QDS-014–018 close as not justified. Full offscreen suite: 28 passed, 2 failed (QDS-029 glass reversal in both themes); workspace fixture also failed its low-effects width check. Those failures remain open. No notification end-to-end, hidden-bar, missing-service or live visual verification; no apply/reload.

- 2026-10-27 — QDS-030 diagnosis (still incomplete): native fixture reproduced intermittent inactive-window/null-focus failures in 6 of 8 consecutive runs; a sandbox variant with only one reopen (no rapid reversal) also failed 3 of 6, so reversal alone is not the cause. An exclusive-keyboard-focus fixture variant still failed 1 of 6. Temporary tracing in successful runs showed the panel selects the close button before the Wayland window becomes active; tracing changed timing and did not reproduce the failure in 12 runs. The evidence does not distinguish compositor/fixture focus timing or interference from a production window-lifecycle defect; no speculative fix or weaker assertion was applied. A later original native run passed. Offscreen QtTest: 28 passed, 2 failed in the independent QDS-029 color checks; workspace fixture failed its low-effects width check. Desktop settings and session preferences passed; `hyprctl configerrors` was empty and `git diff --check` passed. Bar mask/exclusive-zone and real Escape remain untested; no apply/reload. Further diagnosis needs a controlled Wayland session and focus/Wayland event trace capturing a failure.

- 2026-10-27 — QDS-030 (incomplete): added a native panel visibility reversal check requiring an enabled, visible actively focused control without subsequently forcing focus. On the unlocked Wayland session the existing fixture passed before the change; the new check fails with null focus and an inactive window after reversal. The fixture uses a bar stub, so it cannot test the real bar mask/exclusive zone; Escape needs real key delivery (no wtype or ydotool available), not direct invocation of the handler. Those cases remain unimplemented, and QDS-029 failures remain independent and untouched. `git diff --check` passed; no apply/reload.

- 2026-10-27 — QDS-029: added an injectable workspace model defaulting to Hyprland and offscreen low-effects/reversal checks for glass, button, toggle and the real workspace delegate. QtTest: 30 passed, 0 failed, 0 skipped; separate offscreen Quickshell workspace fixture passed; native control-center fixture passed; `git diff --check` passed. Quickshell embeds its plugins, so qmltestrunner cannot load WorkspacePill here; the separate sandboxed fixture is necessary. Tests use a workspace double and do not verify live Hyprland integration or appearance; live checks skipped, no apply/reload.

- 2026-10-27 — QDS-022: closed as not justified per State contract: WorkspacePill and SpotifyPill share existing Spotify selection, MusicPage has a distinct richer policy, and no duplicated selection or independent test seam beyond QDS-020 formatting is demonstrated. Plan/contract review only; implementation, tests and live checks skipped; no apply/reload.
- 2026-10-27 — QDS-023: closed as not justified per State contract: StatusIndicators and QuickPage share battery values, brightness already uses shell-owned state/actions, and no duplicated policy or test seam beyond QDS-020 formatting is demonstrated. Plan/contract review only; implementation, tests and live checks skipped; no apply/reload.
- QDS-024 simplifier follow-up: removed the presentation-object launch roundtrip; offscreen Quick button mouse test dispatches to a bar double and checks the busy guard. Malformed is a field-count check only; inherited nmcli escaping limitation documented. Full offscreen suite: 30 passed, 2 failed (known glass reversal failures); `git diff --check` passed. No native or live shell test, apply, or reload. Live checklist above remains pending.
- 2026-10-27 — QDS-024 (implementation pending live verification): extracted network presentation into an injectable state object; Bluetooth remains in BarWindow per gate. Malformed-only output is identified internally but retains the disconnected display; mixed valid/malformed output follows the existing parser. Process, refresh timer and explicit nmtui command remain in BarWindow. Focused offscreen network test passed (3 including setup/cleanup); full material suite: 29 passed, 2 failed, the previously documented glass reversal failures. `git diff --check` passed. No real commands, live refresh check, native test, apply or reload; task remains unchecked until live integration is verified.
- 2026-10-27 — QDS-025 evaluation: skipped closure and implementation; State contract says proceed because overlay transitions and focus/Escape policy span multiple owners. No tests or live checks; no apply/reload.
- 2026-10-27 — QDS-026 evaluation: skipped closure and implementation; State contract has no explicit not-justified decision for narrow page dependencies, which depend on proceeding extractions. No tests or live checks; no apply/reload.
- 2026-10-27 — QDS-034 preparation only: added the requested human checklist, including QDS-020 integration and per-monitor indicator checks; task remains unchecked pending user-recorded live results. Automated tests, deployment and live checks skipped for plan-only work; no apply/reload.

- 2026-10-27 — QDS-021 investigation (incomplete): the gate says proceed, but moving the PipeWire tracker and its reactive node list changes service lifetime for bar and control-center consumers. Its acceptance requires live selection, mute, volume, missing-device and indicator verification; existing fixture uses a synthetic bar, and the requested no-apply/no-reload constraint prevents verifying the changed live integration. Stopped before implementation for this major risk; no candidate closed or marked complete. Source inspection only; tests and live checks skipped, no apply/reload. Added QDS-020 actual BarWindow binding/integration checks to QDS-034's human matrix.

- 2026-10-27 — QDS-020: extracted formatting into `components/Presentation.js`, retaining the existing child-facing BarWindow methods and service/command ownership. Enum values, palette and icon resolver are injected; Quickshell icon lookup stays at the QML boundary. Boundary and missing-data tests plus offscreen suite: 28 passed, 0 failed, 0 skipped; native control-center fixture passed; `hyprctl configerrors` empty; `git diff --check` passed. Tests exercise the real helper module but the native fixture uses a synthetic bar and does not instantiate BarWindow; these are proxies, not proof of live bindings or appearance. Live verification skipped because source was not applied or reloaded. No apply/reload; no scope deviation.

- 2026-10-27 — QDS-036 review follow-up: category selection now reveals the selected tab using the existing navigation policy. The native mocked panel fixture passed narrow Quick→Audio and Audio→Quick visibility and scrolling, plus pending session-confirmation reset; offscreen 27 passed, 0 failed, 0 skipped; `hyprctl configerrors` empty. Indicator and panel tests remain separate proxies: no end-to-end live BarWindow click or multi-monitor compositor coverage. Added these to the human checklist; live checks skipped because source was not applied or reloaded. No apply/reload.

- 2026-10-27 — QDS-036: routed status left-clicks through the per-bar category signal and existing panel selection, retaining overlay coordination and placing focus on Close after a category request. Offscreen 27 passed, including real indicator pointer clicks, mute, wheel, Bluetooth right-click and absent audio/tool; native control-panel fixture passed category requests, session focus and existing navigation; `hyprctl configerrors` empty. Tests use a bar double and exercise the production indicator and panel separately, not an end-to-end live BarWindow click or multi-monitor compositor behavior. Live checks skipped because source was not applied or reloaded; no apply/reload.

- 2026-10-27 — QDS-028: added focused button visibility checks in both themes at all three control opacities, including transparent hover at zero and distinct hover/selected colors otherwise. Offscreen 26 passed, 0 failed, 0 skipped; native control-center fixture passed; `hyprctl configerrors` empty; desktop-settings and session-preferences checks passed. These are proxies, not live visual verification; no apply/reload. No production changes.
- QDS-029 continuation: Qt 6.12 disposable number and color probes showed that a `Binding` element survives an imperative target write, including subsequent changes, reversals and re-enabling; Qt's binding-removal diagnostic explicitly confirms this. A low-effects signal handler can run before `Behavior.enabled` updates (observed in the workspace fixture), so the production behaviors instead write their `targetValue` from `onEnabledChanged` after disabling. Added this to glass, button, toggle and workspace width/color; expanded both fixtures for repeated reversals and re-enabling. Offscreen material: 32 passed, 0 failed; sandboxed workspace: passed; `git diff --check` passed. These are Qt 6.12/offscreen proxies, not live verification; other bar behaviors are outside this task's fixture coverage. No live shell, apply or reload.

- QDS-029 diagnostic continuation (incomplete): in a disposable HOME and XDG runtime, with display, session bus and Hyprland environment unset, reproduced 28 passed/2 failed in the offscreen material suite and the workspace width failure. A minimal Qt 6.12 Behavior probe showed that disabling the Behavior mid-flight leaves its animation running: width progressed from 20 to 40 after 50 ms, then reached 100 normally; a later state change while disabled jumped to 0. Calling the animation's `complete()` after disabling did not stop or finish the Behavior-controlled animation; assigning its target did stop it in the probe, but binding preservation and production integration were not established. This supports a real mid-flight gap rather than an incorrect 40–50 ms expectation under the task's contract; no production fix or test weakening. QDS-029 remains open; no live shell, apply, reload, or live verification.

- 2026-10-27 — QDS-029 diagnostic (incomplete): reproduced 28 passed/2 failed offscreen and workspace width failure at 40 ms. Temporarily isolated assertions: button color and toggle thumb also miss their 50 ms targets in both themes, so the failure is not glass-specific; reversal before enabling low-effects succeeds. Replacing Behavior guards with zero-duration bindings and calling the animation's `complete()` on low-effects did not fix glass or workspace; removed the experiment and restored tests. No reliable fix established; keep QDS-029 open. Control-center, desktop-settings and session-preferences suites passed; `git diff --check` passed and `hyprctl configerrors` returned empty. Fixtures are proxies; live source verification skipped, no apply/reload.
- 2026-10-27 — QDS-029 simplifier follow-up (incomplete): added intermediate-state and bounded low-effects checks with stale-update checks, including the separate workspace fixture; documented its command and Quickshell prerequisite. Offscreen QtTest: 28 passed, 2 failed (glass color remains mid-animation after low-effects); workspace fixture fails because width remains mid-animation after 40 ms. Disabling a QML Behavior does not finish an in-flight animation. Attempted completion and binding reevaluation did not fix it and were removed; production fix still needed. `git diff --check` passed. No apply or reload; no live verification.
- 2026-10-27 — QDS-029 investigation (incomplete): `WorkspacePill.qml` binds its repeater directly to `Hyprland.workspaces`; an offscreen test cannot independently create or reverse a real delegate without a controllable model seam or compositor-dependent state. A copied delegate would not test the production path. Stop for a decision on introducing an injectable model/test seam or changing the acceptance scope; no QDS-029 test or production change made.

- 2026-10-27 — QDS-019: mapped BarWindow child and internal consumers, shell inputs, tracker and network ownership; recorded candidate decisions and the malformed-network and icon-resolution boundaries. QDS-013 remains blocked; this independent gate does not resolve demonstration-dependent primitive decisions. Verified by source and fixture inspection/search; no tests, native session or hyprctl run for plan-only work, no apply/reload or source edits.

- QDS-013 investigation (incomplete): inspected Quick, Audio, Display, System, control-panel navigation and notification history. Quick already exposes network/Bluetooth status and settings, audio, battery percentage and display shortcuts; Display and System already offer refresh actions, and the notification panel has clear/close actions. No small new interactive element with an established unmet need emerged. Deferred bar tooltips and tentative proposals are recorded under Improvements; slider/toggle gates remain provisional. No source changes or tests; no apply, reload, or live verification.

- 2026-10-27 — QDS-001: user-provided just-verified baseline, offscreen 17 passed, 0 failed, 0 skipped; `bash tests/control-center.sh` reported checks passed, exit 0 (script does not report individual counts). Not rerun; `hyprctl configerrors` and other suites skipped because no source changed. Offscreen and mocked native checks are proxies, not live visual verification.
- 2026-10-27 — QDS-002: independently inspected QML constants and semantic consumers; recorded shared roles and local exceptions. No tests rerun for plan-only inventory; live/hyprctl skipped, no source changed. QDS-004 amended to migrate all initial consumers and exclude singleton motion roles.
- 2026-10-27 — QDS-003: independently searched component uses, read primitive implementations and fixture; documented states, overrides, consumers and decisions. Slider/toggle decisions remain provisional until QDS-013. No tests rerun for plan-only inventory; live/hyprctl skipped, no source changed.
- 2026-10-27 — QDS-004: added the contracted token singleton and migrated all listed initial consumers, preserving motion guards and values. Offscreen: 17 passed, 0 failed, 0 skipped; native control-center checks passed; `hyprctl configerrors` returned no errors. These checks are proxies; live shell visual verification skipped because changes were not applied or reloaded as requested. Follow-up review: bound reserved bar height to pill height, restored local notification action widths, and renamed bar color motion to include selection; QDS-006 revised to reassess evidence rather than presume extra tokens.
- 2026-10-27 — QDS-005: offscreen 18 passed, 0 failed, 0 skipped; native control-center checks passed. Tests cover all named token values and clock pill height, not every consumer typo or binding; clock pill used instead of a button radius because that radius is local. Checks are proxies; live shell and visual verification skipped, no apply or reload.
- 2026-10-27 — QDS-006: checked all component radii against the contract: overlay, bar-indicator and device-card roles are already migrated; 18px glass, notification card/empty state and music artwork have different roles, 16px Quick/Appearance cards have different state treatments, and button, slider, toggle and workspace radii are local or geometry-derived. No further shared role justified; no geometry changed. Offscreen 18 passed, 0 failed, 0 skipped (proxy); native and hyprctl skipped for plan-only change, live visual check skipped, no apply or reload.
- 2026-10-27 — QDS-007: inspected glass, control and notification panel chrome and bar pills/indicators. Contracted bar gaps/heights and notification icon/action dimensions already use tokens; glass has no matching spacing token. Panel content insets differ (control 20 horizontal/16 vertical, notification panel 20, toast 16); pill horizontal insets differ (workspace 8, right 12). Equal literals for other roles are not grounds to use unrelated tokens. No code changes or new tokens; acceptance interpreted within the existing contract, not as requiring uniform insets. Offscreen prerequisite check above passed; native and hyprctl skipped for plan-only change, live visual check skipped, no apply or reload.
- 2026-10-27 — QDS-008: inspected control page spacing and device controls: the five contracted page gaps and all three device-card insets are already tokenized. Music's 18px page gap, Quick's sound-card inset and Appearance's slider insets have distinct content roles; left local instead of applying equal-valued unrelated tokens. No code changes or new tokens. Offscreen prerequisite check above: 18 passed; native control-center fixture passed including narrow layout, and `hyprctl configerrors` returned no errors. These are proxies, not live visual proof; default and narrow geometry unchanged in source. Live visual checks skipped; no apply or reload.
- 2026-10-27 — QDS-009 review follow-up: added pointer, checkable/checked, accessible naming/override, custom content, and disabled input checks in both themes. Default accessible name was empty; bound it to text while retaining caller overrides. Offscreen 20 passed; low-effects transition reversal is explicitly deferred to QDS-029. No live verification or apply/reload.
- 2026-10-27 — QDS-012: deleted the old component and migrated the remaining material fixture; no wrappers or references remain under `dot_config/quickshell`, `tests`, or `docs`. Offscreen 20 passed; native control-center fixture passed; `hyprctl configerrors` empty. These are proxies; live visual check skipped, no apply/reload.
- 2026-10-27 — QDS-011: migrated notification buttons and the notification-font fixture, retaining explicit typography roles. Offscreen 20 passed, including typography isolation; native control-center fixture passed; `hyprctl configerrors` empty. These are proxies; notification surfaces not live-tested, no apply/reload.
- 2026-10-27 — QDS-010: migrated control-center buttons without changing caller properties. Offscreen 20 passed; native control-center fixture passed including narrow layout; `hyprctl configerrors` empty. These are proxies; live visual check skipped, no apply/reload.
- 2026-10-27 — QDS-009: added `components/ActionButton.qml` with the existing button contract, leaving all consumers on `ControlButton` for later migrations. Offscreen: 20 passed, 0 failed, 0 skipped, including both themes and keyboard/state checks; native control-center checks passed; `hyprctl configerrors` returned no errors. These are proxies; the new component is not yet used by the live shell. Live visual verification skipped; no apply or reload. Temporary implementation duplication is required until QDS-010–012; no deviation.
