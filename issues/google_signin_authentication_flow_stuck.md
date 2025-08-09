### Google Sign-in: Authentication flow stuck on initial login

The Google sign-in process gets stuck during the initial login attempt. Users have to close and reopen the app for the authentication to complete successfully. This creates a poor user experience and needs to be addressed.

#### Steps to Reproduce:
1. Open app for first time
2. Click on Google Sign-in button
3. Observe sign-in process getting stuck
4. Close and reopen app
5. Auto-signs in successfully

#### Expected Behavior:
- Google sign-in should complete successfully on the first attempt
- User should be logged in immediately after authorizing Google account

#### Current Behavior:
- Sign-in process gets stuck on initial attempt
- Requires app restart to complete authentication
- Auto-signs in only after reopening the app