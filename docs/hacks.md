# Hacks

Might be worth refactoring at a later date.

## Preloads

Member and MemberProfile are preloading each other which isn't really required
but just there to keep tests happy!


## MemberProfile Placeholder

Put placeholder invalid profile as Member association with `:is_ready` flag.
Only allow next step once MemberProfile filled in and `:is_ready` set to true.