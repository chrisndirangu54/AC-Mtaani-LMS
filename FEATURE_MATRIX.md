# Feature coverage and deployment gates

All learner courses and core learning activities remain free. The 12 Learning Hub categories are wired to Firestore collections and staff publication APIs. That is a **content-management foundation**, not an assertion that every external platform integration is complete.

| Feature | Committed implementation | Remaining before production |
|---|---|---|
| Quests, XP, levels | Hub UI and transaction-based completion/XP; single award per quest | Admin quest builder, instructor assessment-based XP, badges, balanced reward design |
| AI tutor | Course-grounded callable in functions/index.js | Configure secret, approved lessons, retrieval evals, privacy safeguards |
| Adaptive study, flashcards, spaced repetition | Content categories | Scheduling algorithm, learner mastery model, review UI |
| Coding, SQL, cybersecurity labs | Instructor-published lab content | Sandboxed execution infrastructure; no untrusted code execution in Cloud Functions |
| H5P, SCORM/xAPI | Content placeholders | License review and separate interoperable content player/LRS |
| Portfolio, skills passport | Published content categories and learner evidence submission | Student-owned portfolio CRUD, credential issuance and public consent controls |
| Mentor circles, discussions | Moderated content categories | Membership, messaging, moderation and safeguarding |
| Career support and English speaking | Career content surface | CV review, speech service, safety and evaluation |
| Live classes | Session listings | Video provider, secure attendance and consent-based recordings |
| Maker-space booking | Equipment listings | Booking conflicts, waitlist, staff approval |
| 3D/VR/AR | Experience listings | Embedded viewer, optimized assets and accessible 2D fallback |
| Scholarships and opportunities | Curated opportunity listings | Source verification, expiry checks, application workflow |
| Instructor/admin | Staff-authenticated content creation/publishing APIs | Full dashboards, role provisioning, audit trail |
| Offline access | Not yet implemented | Storage caching and conflict-safe sync |
| Learning analytics | XP profile | Cohort and assessment insights, privacy review |
| Free animations & imagery | Brand guidelines / asset directory | License-cleared SVG/Lottie assets and animation playback; do not assume all third-party gallery assets are open source |

## Security & governance
- Firestore clients cannot write XP totals, assessments or published activities directly.
- Role permissions depend on **server-issued custom claims**, never client-set role fields.
- Submitted evidence requires staff approval; self-certified quests have capped XP and cannot award certificates.
- Never store provider secrets in Flutter source or GitHub.
- Protect learners' personal data; require consent for media and public portfolios.
- Institutional brand/partner logos require authorization before public release.
- AI must use reviewed learning materials and not fabricate course completion.

## Recommended validation
1. Configure Flutter and Firebase; generate platform code, run `flutter pub get`, `flutter analyze`, `flutter test`.
2. Run `npm install` and `node --check index.js` and `node --check learning_features.js` in `functions`.
3. Test Firestore emulator rules for anonymous, learner, instructor, and admin roles.
4. Test replay of quest submissions, unapproved activities, privilege escalation and concurrent XP calls.
5. Populate and approve content, deploy to staging, conduct accessibility and low-bandwidth tests.
6. Add and review approved organization logos and media licenses.

## External sources
- Flutter: https://flutter.dev
- Firebase: https://firebase.google.com
- Lottie Flutter player: https://pub.dev/packages/lottie
- flutter_svg: https://pub.dev/packages/flutter_svg
- H5P: https://h5p.org
- unDraw license: https://undraw.co/license

Third-party media licenses vary per asset; obtain and record permission where necessary.
