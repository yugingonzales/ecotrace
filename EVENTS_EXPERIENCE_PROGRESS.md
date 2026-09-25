# Events experience progress

The Events tab now gets out of the way while the user reads: the calendar strip
collapses as the schedule is scrolled and comes back only at the top, and a
confirmed check-in is acknowledged with a short-lived participation receipt
instead of silently flipping a button.

## Where it lives

- `lib/features/home/presentation/screens/events/events_screen.dart` — the
  collapse controller, the scroll listener, the shared participation flow and
  the confirmation dialog.
- `lib/features/home/presentation/widgets/events/participation_receipt.dart` —
  the confirmation overlay, its fade-and-scale entry, countdown bar and
  three-second auto-dismissal.
- `lib/features/home/presentation/widgets/events/calendar_strip.dart`,
  `event_card.dart`, `event_details_sheet.dart` — unchanged. The behaviour is
  additive and driven entirely from the screen, so these keep their public API.

## Collapsing the calendar strip

The strip sits in a fixed header above the event list, so on a tall day it used
to steal roughly 96px from the cards permanently. It now animates out of the way
while scrolling and is restored at the top.

The behaviour is deliberately **one-way per scroll direction**:

| Condition | Result |
| --- | --- |
| `pixels <= 8` | Always revealed, regardless of the last scroll direction |
| downward travel past `28` | Collapses |
| any other upward scroll | **Stays collapsed** |

Revealing the strip on every upward scroll was explicitly ruled out: when a user
scrolls back up through a long list they are still reading cards, so the space
they reclaimed must stay reclaimed. The strip only returns once they have
actually reached the top.

Two thresholds are used rather than one, creating a 20px dead zone
(`8 < pixels <= 28`). Without it, the overscroll bounce at the top of the list
would flip the header on and off while the finger was still down.

### Implementation notes

- `_stripCollapse` is an `AnimationController` that starts at `value: 1`.
  An `AnimationController` defaults to its lower bound, so without the explicit
  initial value the strip would begin life collapsed.
- The strip is wrapped in an `AnimatedBuilder`. Reading `_stripCollapse.value`
  directly in `build` is not enough: `setState` rebuilds once, *before* the
  controller has advanced, so the header would snap rather than animate.
- The listener returns `false` from `onNotification` so the notification keeps
  bubbling to ancestors.
- The `ScrollNotification` depth check that an earlier draft used was removed.
  `Scrollable` increments `depth` on every notification passing through it, so a
  listener placed outside the `ListView` sees depth `1`, not `0` — the guard
  rejected every update. It was also unnecessary: the horizontal calendar strip
  is a *sibling* of the list, so its notifications can never reach this listener
  in the first place.
- The list is attached to `_listController`, and `_selectDay` animates it back to
  the top when the day changes, which also brings the strip back into view.
- **The 18px gap above the strip lives inside the collapsed child, not beside
  it.** This was a real bug. As a sibling of the `AnimatedBuilder` the gap never
  animated away, so hiding the strip still left `18 + 16` = 34px of dead green
  under the title, which read as a thick bottom padding. Collapsing the gap with
  the strip leaves the intended 16px. The collapse test asserts the header
  reclaims at least 10px more than the bare `CalendarStrip` height, so a gap that
  drifts back outside the collapse region fails the build.

## Participation confirmation

Joining used to be an immediate toggle. `_toggleJoined` was replaced by
`_requestParticipation`, which both the event card and the details sheet call, so
the two entry points cannot drift apart:

1. If the event is already joined, it is withdrawn silently — a withdrawal is
   not a check-in and needs no ceremony or receipt.
2. Otherwise a confirmation dialog appears, summarising the event's title, time
   and location.
3. On **Not now** the dialog is dismissed and participation is left unchanged.
   No receipt is shown and the card still reads `Confirm`.
4. On **Enter event** the event is added to `_joinedEvents` exactly once and the
   receipt is displayed.

The details sheet now returns `true` when its button is pressed rather than
performing the join itself, and the screen runs the shared flow afterwards, so
the sheet and the card produce identical behaviour.

## The participation receipt

`showParticipationReceipt(context, event)` pushes a confirmation overlay on the
root navigator, so it is not confined to the Events tab's subtree. It goes
through `showGeneralDialog` with `barrierDismissible: true`, so a tap anywhere
on the scrim dismisses it, and it enters with a fade plus a `.92` → `1` scale on
`easeOutBack` over 280ms.

- The overlay is announced as a **live region**, so screen readers report the
  confirmation instead of it appearing silently. The label is
  `Participation confirmed for <title>`.
- A countdown bar communicates the remaining window.
- It dismisses on tap, and **auto-dismisses after three seconds**. The
  three-second duration is exported as `kParticipationReceiptDuration` so tests
  can `pump` it deterministically instead of waiting in real time.
- The dismissal `Timer` is cancelled in `dispose` and the pop is guarded by
  `mounted`, so a receipt dismissed early cannot fire a pop against a disposed
  `State`.
- The card sits in a `SingleChildScrollView` inside 24px of padding, so an
  unusually long title degrades into a scroll rather than an overflow.

### Receipt design

The card is six bands, ordered so the most useful information is read first: a
gradient header carrying the confirmation, the **event title as the hero**, the
detail rows, and the countdown bar closing the bottom edge.

- The **header** is a `0xFF167A58` → `0xFF05291D` gradient carrying a 48px lemon
  check badge, the lemon `PARTICIPATION CONFIRMED` eyebrow, the 24px
  `You're in!`, and a `Your place on the team is saved.` subtitle. A `READY`
  pill sits inline on the right, with a 96px leaf behind everything at 8%
  white. The 24px line is the header's own headline — **the event title is not
  in the header.**
- The **title is the hero of the body**: 17px w900 at `height: 1.3`, against
  12px for every detail row. It carries **no `maxLines`** and wraps to whatever
  height it needs, so a long event name is never truncated.
- The **time is a lemon pill** rather than one more muted icon row, because it
  is the field a user actually needs at a glance. It keeps `_ReceiptRow`'s 10px
  bottom padding so the detail block stays rhythmically aligned.
- The **attendee count adds one**, because the user has just joined.
- The **countdown bar is optional**: `remaining` is nullable and the bar is
  omitted outright when it is null. That is what lets a test pump
  `ParticipationReceiptCard` bare.
- **There is no pass id, barcode, perforation, or stub.** The ticket metaphor
  only ever existed to carry a credential, and nothing scanned the code or
  checked anyone in against it — so it was a false affordance. Removing the
  credential removed the reason for the stub, and with the stub empty the
  perforation had no referent, so all three went together. Measured, the card
  went from **332px to 269px — 63px shorter** — with the countdown bar acting
  as its bottom edge.
- That also retired `participationCode()`, which existed only to derive a
  stable id for tests to assert on. With no id on screen, the determinism
  rationale went with it.

## Limitations

- **State is local and in-memory.** `_joinedEvents` lives on the `State` and is
  not persisted, so a join is lost on app restart. No repository or storage was
  added.
- **The receipt is informational.** It confirms the join and echoes the event's
  date, time, location and attendee count, but it is not a credential — there
  is nothing to scan or check in against, and no server-side check-in.
- **No undo.** Dismissing a receipt dismisses only the receipt; there is no
  action to revert the join.
- **The collapse is a heuristic, not a coordinator.** It reads scroll deltas
  rather than using a `ScrollController` + `NotificationListener` pairing, and it
  does not react to programmatic scrolls, so a `ListView` scrolled by other code
  would not move the header.
- **One receipt at a time.** Confirming a second event replaces the first
  receipt rather than queueing it.
- **Search and filter still reset nothing.** Changing the query or the
  "joined only" filter does not scroll the list back to the top; only changing
  the day does.

## Verification

```powershell
cd C:\flutter_workspace\ecotrace
dart format --output=none --set-exit-if-changed lib/features/home/presentation/screens/events test/widget_test.dart
flutter analyze
flutter test
```

`test/widget_test.dart` adds five cases covering the new behaviour:

- `collapses the calendar strip while scrolling down and restores it at the top`
  asserts the strip has height at rest, collapses to exactly `0` after a
  downward drag, **stays** at `0` while scrolling back up short of the top, and
  is restored after returning to the top. It also checks the top bar and the
  event cards are unaffected by the collapse, and that the green header reclaims
  more than the strip alone — the regression guard for the stray 18px gap.
- `cancelling the participation confirmation leaves the event unjoined` asserts
  cancellation shows no receipt and leaves the card's action as `Confirm`.
- `confirmed participation shows a receipt that auto-dismisses` asserts the
  receipt is issued once, carries the event title and date, updates the card to
  `Joined`, and clears itself after `kParticipationReceiptDuration` **without**
  reverting the join.
- `participation receipt can be dismissed early by tapping it` asserts tap
  dismissal before the window elapses.
- `participation receipt renders a long event title in full` pumps
  `ParticipationReceiptCard` directly — with `remaining` omitted, so the
  countdown bar is absent — using an over-long title, and asserts it is laid
  out in full with no ellipsis and no layout exception. Note this guards a
  hypothetical: the title has no `maxLines` and was never actually clipped.

Two testing constraints are worth recording, since both produced false failures
while this was built:

- **`pumpAndSettle` waits out the receipt.** Because the receipt stays on screen
  for three seconds, settling after confirming would advance past the
  auto-dismissal and the receipt would be gone by the time it is asserted. These
  tests use bounded `pump` calls for the visible state and pump the exported
  duration explicitly to test dismissal.
- **Assertions must use what is actually on screen.** A list header that scrolls
  away is legitimately absent, and text such as the event location legitimately
  appears both in the dialog and on the card behind it, so those assertions use
  `findsNothing` / `findsWidgets` rather than `findsOneWidget`.
