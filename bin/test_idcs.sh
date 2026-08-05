#! /usr/bin/env bash

# DOC: Automated UI login and verification test for Seattle CiviForm via Playwright

pushd "$(git rev-parse --show-toplevel)" > /dev/null

set -e
set +x

# Define colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "Checking environment dependencies..."
if ! command -v npx &> /dev/null; then
    printf "${RED}Node.js / npx is required but not installed.${NC}\n"
    exit 1
fi

echo "Running CiviForm Login and Verification Test..."

# Using Node.js with Playwright 
node -e '
const { chromium } = require("playwright");

(async () => {
  // headless: true is REQUIRED for GitHub Actions
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext();
  let page = await context.newPage();

  const username = process.env.SEATTLE_LOGIN_USERNAME;
  const password = process.env.SEATTLE_LOGIN_PASSWORD;

  if (!username || !password) {
    console.error("Error: SEATTLE_LOGIN_USERNAME and SEATTLE_LOGIN_PASSWORD environment variables must be set.");
    process.exit(1);
  }

  try {
    // 1. Start at the CiviForm Programs page
    console.log("Navigating to CiviForm programs page...");
    await page.goto("https://civiform.seattle.gov/programs", { waitUntil: "networkidle" });

    // 2. Click the initial "Log in" button on the CiviForm site
    console.log("Clicking the Log in button...");
    const initialLoginBtn = page.locator("#login-button");
    await initialLoginBtn.waitFor({ state: "visible", timeout: 15000 });
    await initialLoginBtn.click();

    // 3. Wait for the redirect to the Seattle SSO login page
    console.log("Waiting for SSO login page to load...");
    const usernameInput = page.getByRole("textbox", { name: "Username *" });
    await usernameInput.waitFor({ state: "visible", timeout: 15000 });

    // 4. Fill Credentials
    console.log("Filling username...");
    await usernameInput.fill(username);

    console.log("Filling password...");
    const passwordInput = page.getByRole("textbox", { name: "Password" });
    await passwordInput.fill(password);

    console.log("Clicking SSO login button...");
    const loginButton = page.getByRole("button", { name: "Login" });
    await loginButton.click();

    // 5. Check for intermediate "Continue" screen (just in case it still pops up)
    console.log("Checking for App Selection (Continue) screen...");
    try {
      const continueLocator = page.locator("button:has-text(\"Continue\")").first();
      await continueLocator.waitFor({ state: "visible", timeout: 10000 });
      console.log("Found Continue button! Clicking it...");
      await continueLocator.click({ force: true });
      await page.waitForTimeout(3000); 
    } catch (err) {
      console.log("No Continue button appeared. Moving forward to dashboard...");
    }

    // Handle new tabs if clicking continue spawned one
    const pages = context.pages();
    if (pages.length > 1) {
        console.log("A new tab was opened! Switching context...");
        page = pages[pages.length - 1];
    }

    // 6. Verify successful login on CiviForm
    console.log("Waiting for landing page to show logged in as...");
    await page.waitForSelector("text=/Logged in as/i", { timeout: 30000 });
    
    console.log("\u001b[32mSuccessfully authenticated and verified user session element!\u001b[0m");
  } catch (error) {
    console.error("\u001b[31mLogin automation or verification failed:\u001b[0m", error);
    process.exit(1);
  } finally {
    await browser.close();
  }
})();
'

printf "${GREEN}CiviForm login and verification test completed successfully${NC}\n"
echo ""