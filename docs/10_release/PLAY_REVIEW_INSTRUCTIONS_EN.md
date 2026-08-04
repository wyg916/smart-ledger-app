# Store Review Access Instructions (English)

App: Smart Ledger (`com.wyg916.smartledger`)

1. Launch the app while connected to the internet.
2. On the mandatory sign-in screen, tap **Other sign-in methods**.
3. Enter the reusable review username and password supplied privately in the store review console.
4. Tap **Review sign in**. No SIM card, WeChat installation, OTP, or regional phone service is required.
5. The review user can access transactions, budgets, analytics, Kimi chat/image analysis, app lock, and account deletion. It has no administrative access.

Credentials are intentionally omitted from Git and the APK. Provision or rotate them with `services/api/scripts/provision_review_account.py`, set `REVIEW_LOGIN_ENABLED=true`, and deliver them only through the store console. If access fails, verify the production API and review-user enabled state; do not enable a guest bypass.

Data note: financial records created during review remain in the review device's user-isolated local SQLite database and are not synchronized to the server.
