# Hacks, Errors and Refactoring Opportunities

Might be worth refactoring at a later date.

**Search 'TODO' for more**

## Preloads

Member and MemberProfile are preloading each other which isn't really required
but just there to keep tests happy!


## MemberProfile 

- Placeholder
  - Put placeholder invalid profile as Member association with `:is_ready` flag.
  - Only allow next step once MemberProfile filled in and `:is_ready` set to true.

- Age
  - Make this based on dob

- Location and Times
  - Add when and where member can meet up with others

## General Errors

- MemberProfile form doesn't show error when there is no wanted genders selected!
  - It does have the error in the changeset!

## BrowserLive demo code

- Added random mutual liking for demo purposes.