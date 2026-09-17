# About this fork

`get` 5.x has only ever been published as release candidates
(`5.0.0-release-candidate-9.3.3`). This fork keeps that release candidate
and adds a small set of fixes for defects that surface in normal use.

Rule: **stay diffable against upstream.** Each fix is minimal, commented at
the point of change, and covered by a test in `test/regression/` that states
the mutation it guards against. No reformatting, no renames, no new APIs.

## Fixes (branch `rc-fixes`)

| Area | Defect | Origin |
|---|---|---|
| `rx` | An `Rx` stops delivering to `ever()`/`listen()` once its last stream subscriber cancels | ported from [SINT](https://github.com/Open-Neom/sint) 1.6.2 |
| lifecycle | `onReady()` runs after `onClose()` for a controller destroyed within its first frame | SINT 1.6.2 |
| queue | An `Error` thrown by a job freezes `GetQueue` permanently | SINT 1.3.1 |
| snackbar | `borderColor` without `borderWidth` crashes on a null check | jonataslaw/getx#3466 |
| `rx` | `assignAll` consumes a lazy iterable after clearing the list | SINT 1.6.2 |
| errors | Raw `throw 'string'` replaced by `Exception` | Aniketkhote/getx, jonataslaw/getx#3462 |
| navigation | `offAllNamed`/`offNamedUntil` never complete the futures of dropped pages | SINT 1.3.1 |
| navigation | `Get.back()` pops the page under an open dialog or bottom sheet instead of the overlay | devs-flutter-plugin/getx 28cb1bba (PopupRoute branch only) |
| `rx` | `RxList()`/`RxMap()`/`RxSet()` without argument throw on first mutation | devs-flutter-plugin/getx 28cb1bba, Aniketkhote/getxify b39db519, jonataslaw/getx#3411 |
| navigation | `GetPage.copyWith` loses `restorationId` and `preventDuplicateHandlingMode` | linpengteng/getx a6df1ffd |
| navigation | `popUntilOriginalRoute` pops nothing, or the original route itself | this fork |
| `rx` | `bindStream` outside a build is never cancelled, even by `close()` | getxify aa6f5e16, 610f9455, jonataslaw/getx#3000 |
| state | `GetBuilder(global: false)` never closes its controller | SleepySquash/getx 7b66f071, getxify, jonataslaw/getx#2123 |
| state | `GetX(global: false)` never closes its controller | same |
| workers | A disposed `debounce` worker still fires its pending callback | getxify f7104646 |
| workers | A disposed `interval` worker still fires its pending callback | this fork |

`git log master..rc-fixes` gives the mechanism of each fix.

### Visible behaviour changes

- `Get.back()` with a dialog or bottom sheet on top closes that overlay
  (also on the root page, and also with `canPop: false`) and completes its
  future with `result`. Open snackbars are still not closed by `Get.back()`.
- A `global: false` controller given to `GetBuilder`/`GetX` is closed when
  the widget is disposed, unless `autoRemove: false`.

### API additions required by a fix

- `GetPage.copyWith(preventDuplicateHandlingMode:)`.

## Not included

- **Conditional collection notifications** (SINT 1.6.0/1.6.1: notify only
  when contents change). It can silently drop notifications that code relies
  on, e.g. after mutating an element in place and reassigning it.
- **Type-keyed DI registry** (SINT 1.6.0). A deep rewrite of instance
  resolution for a gain that is negligible outside hot loops.
- **Formatting-only changes**, the `ObxError` file split and
  `Routing.args` retyping from Aniketkhote/getx.
- **`reportRouteWillDispose` in `GetObserver.didPop`** (Aniketkhote/getx): a
  behaviour change on the dependency disposal path, with a risk of disposing
  twice.
- **jonataslaw/getx#3464** (`MediaQuery.sizeOf`): the context extensions
  already use `MediaQuery.sizeOf`.
- **jonataslaw/getx#3463** (`GetBuilder.controllerBuilder`): a new API.
- **jonataslaw/getx#3472** (Flutter `material_ui`/`cupertino_ui`): see below.
- **Device locale change overriding the app's locale** (getxify b39db519,
  jonataslaw/getx#3357). A version was applied then reverted: telling an
  explicit choice apart from a locale passed to `GetMaterialApp(locale:)`
  is not reliable, and it stopped applications that drive the locale
  through that parameter (e.g. from a translation package following the
  device) from following device changes. A correct fix also needs
  `GetRoot` to apply a changed `locale:` after mount, which it currently
  ignores.

### About `material_ui` (#3472)

`material_ui` and `cupertino_ui` resolve on Flutter 3.44, so availability is
not the issue. Their Material types are **distinct** from those of
`package:flutter/material.dart` (`ThemeData`, `ThemeMode`... are not
assignable to each other; `Widget` is shared). Switching this package's
imports therefore breaks every application that still passes
`flutter/material` types to `GetMaterialApp`. It is a coordinated migration
for package and applications together, and cannot be made conditional
inside one source tree. The PR also declares `material_ui: any`.

When needed, regenerate it on a dedicated branch:

```sh
sd 'package:flutter/material\.dart'  'package:material_ui/material_ui.dart'  $(rg -l 'package:flutter/material.dart' lib test example)
sd 'package:flutter/cupertino\.dart' 'package:cupertino_ui/cupertino_ui.dart' $(rg -l 'package:flutter/cupertino.dart' lib test example)
# then pin real version constraints
```

## Updating

1. Rebase `rc-fixes` onto the new upstream.
2. `flutter test`: `test/regression/` is the contract.
3. Drop any fix that landed upstream.
