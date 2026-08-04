import asyncio
import os

from app.auth.service import provision_review_account
from app.config import get_settings
from app.database import get_session_factory


async def main() -> None:
    username = os.environ.get("REVIEW_ACCOUNT_USERNAME", "")
    password = os.environ.get("REVIEW_ACCOUNT_PASSWORD", "")
    if len(username) < 3 or len(password) < 12:
        raise SystemExit("Review credentials must be provided through environment variables")
    async with get_session_factory()() as session:
        await provision_review_account(
            session, username=username, password=password, settings=get_settings()
        )
    print("Review account provisioned or rotated successfully")


if __name__ == "__main__":
    asyncio.run(main())
