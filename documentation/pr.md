# Safe rollback: revert docs verification + respond permission fix + Firebase init guard + Firestore index + graceful fallback banner

## Summary
Implements a safe rollback of the documents verification feature while preserving necessary permission logic and hardening stability/performance:
1. Reverted prior documents verification commit (non-destructive history).
2. Restored & expanded respond eligibility (delivery or verified business; allow edit of existing response).
3. Guarded Firebase initialization to prevent duplicate-app errors.
4. Added required Firestore composite index (country + status + createdAt) for country-filtered active requests query (`whereNotIn` status).
5. Added runtime graceful fallback (drops status filter) while index builds.
6. Added UI banner indicating limited filtering when fallback is active; reduced noisy console logs.

## Rationale
Avoid force-push / history rewrite, restore stable baseline, and ensure app remains functional while Firestore index propagates. Improves user experience (no crash, clear indication of temporary limited filtering) and reduces log noise.

## Commits
- 6250a7c revert: remove documents verification feature (revert 8f0bd1f)
- 50ff050 feat: broaden respond eligibility for delivery and business roles
- 5af35b1 fix: guard firebase init and refine respond permission logic
- a63e25e chore: add composite index for country+status+createdAt
- 4478c19 feat: graceful fallback for missing Firestore composite index
- 4f4dd00 feat: fallback banner + quieter logs and duplicate init suppression

## Key Changes
| File | Change |
|------|--------|
| `lib/main.dart` | Duplicate Firebase init suppression & quieter logging |
| `lib/src/services/country_service.dart` | Fallback query handling for missing index |
| `lib/src/home/screens/home_screen.dart` | Fallback detection flag, banner UI, trimmed logs |
| `lib/src/screens/unified_request_response/unified_request_view_screen.dart` | Respond permission logic refined (earlier commit) |
| `firestore.indexes.json` | Added composite index definition |

## Behavior
Primary query (country + status whereNotIn + orderBy createdAt) succeeds once index is built; until then, app auto-falls back and shows a banner. After index readiness `_usingFallback` becomes false and banner disappears.

## Testing & Verification
- Hot reload no longer triggers unhandled duplicate-app crash.
- Fallback path exercised (FAILED_PRECONDITION caught; banner shows; retry works).
- Requests list loads (sample docs) in both fallback and standard modes.
- Respond button hidden when user is requester; visible otherwise per roles.

## Risk / Mitigation
- Fallback returns potentially more statuses (no status exclusion) temporarily: clearly indicated by banner.
- Index must be deployed (`firebase deploy --only firestore:indexes`) before banner naturally disappears.
- Changes are additive / low-risk; no schema migrations.

## Rollout Plan
1. Merge this PR.
2. Deploy Firestore indexes (if not already) and wait until status = Ready.
3. Verify banner no longer appears for country-filtered query.
4. (Optional) Later remove fallback/banner code if desired and clean up residual verbose logs elsewhere.

## Follow-ups (Not Included Here)
- Consolidate request fetching into a single service (pagination + caching).
- Add telemetry for fallback usage rate.
- Reduce remaining verbose debug logs in role/user services.

## Checklist
- [x] Safe revert without force-push
- [x] Permission logic restored
- [x] Firebase init guarded
- [x] Composite index defined
- [x] Runtime fallback
- [x] UI indicator + retry
- [ ] Index deployed (post-merge)
- [ ] Post-merge cleanup (optional)

## How to Create PR (CLI Option)
```
# From repository root (containing this pr.md)
gh pr create --base main --head revert-docs \
  --title "Safe rollback: revert docs verification + respond permission fix + Firebase init guard + Firestore index + graceful fallback banner" \
  --body-file pr.md
```

After merge:
```
git checkout main
git pull
# (optional) delete remote branch
git push origin --delete revert-docs
```

---
If anything needs to be trimmed for brevity, feel free to edit before creating the PR.
