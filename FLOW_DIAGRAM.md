# Flow Diagram - Mouse Drag Bug Fix

## Before Fix (Problem Flow)

```
User drags mouse without selecting text
              ↓
Accessibility API fails to get selection
              ↓
Chrome method fails (not Chrome browser)
              ↓
Forced copy method triggered
              ↓
Simulates Cmd+C
              ↓
Reads clipboard content
              ↓
Returns old clipboard content ("old text")
              ↓
❌ Toolbar appears incorrectly with old text
```

## After Fix (Correct Flow)

```
User drags mouse without selecting text
              ↓
Accessibility API fails to get selection
              ↓
Chrome method fails (not Chrome browser)
              ↓
Forced copy method triggered
              ↓
Step 1: Read clipboard → "old text"
              ↓
Step 2: Simulate Cmd+C
              ↓
Step 3: Read clipboard → "old text"
              ↓
Step 4: Compare → "old text" == "old text"
              ↓
Step 5: Return nil (no new selection)
              ↓
✓ Toolbar does not appear
```

## When User Actually Selects Text

```
User selects text "hello"
              ↓
Accessibility API fails to get selection
              ↓
Chrome method fails (not Chrome browser)
              ↓
Forced copy method triggered
              ↓
Step 1: Read clipboard → "old text"
              ↓
Step 2: Simulate Cmd+C (copies "hello")
              ↓
Step 3: Read clipboard → "hello"
              ↓
Step 4: Compare → "old text" != "hello"
              ↓
Step 5: Return "hello"
              ↓
Step 6: Restore clipboard → "old text"
              ↓
✓ Toolbar appears with selected text "hello"
```

## Code Changes Summary

### AppleScript Changes
```applescript
# Before
return selectedText

# After  
return {previousText, selectedText}
```

### Swift Changes
```swift
// Before
guard let textValue = descriptor.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
      !textValue.isEmpty else {
    return nil
}
return (textValue, fallbackBounds, .appKit)

// After
guard descriptor.numberOfItems == 2,
      let previousTextDescriptor = descriptor.atIndex(1),
      let selectedTextDescriptor = descriptor.atIndex(2) else {
    return nil
}

let previousText = previousTextDescriptor.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
let selectedText = selectedTextDescriptor.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

// Key fix: Compare before and after
if previousText == selectedText {
    return nil  // No new selection detected
}

return (selectedText, fallbackBounds, .appKit)
```

## Edge Cases Handled

| Scenario | Before Fix | After Fix |
|----------|-----------|-----------|
| Empty clipboard + no selection | ❌ Might fail | ✓ Returns nil |
| Text in clipboard + no selection | ❌ Shows old text | ✓ Returns nil |
| Empty clipboard + new selection | ✓ Works | ✓ Works |
| Text in clipboard + new selection | ✓ Works | ✓ Works |
| Non-text clipboard content | ❌ Might crash | ✓ Handled by try/catch |

## Performance Analysis

- **Additional time**: ~50ms (existing delay)
- **Additional operations**: 2 clipboard reads
- **Memory impact**: Minimal (two string comparisons)
- **User experience**: No noticeable difference

## Compatibility

- ✓ Backward compatible
- ✓ Only affects forced copy fallback
- ✓ No impact when forced selection is disabled
- ✓ Works on all macOS versions supported by the app
