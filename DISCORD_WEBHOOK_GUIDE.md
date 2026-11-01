# Discord Release Announcements Setup Guide

This guide explains how to automatically send an announcement to your Discord channel whenever you publish a new release of **Kwibus Random Things** on GitHub.

You have two simple ways to do this:
* **Option 1 (Custom Rich Embed via GitHub Actions)**: Beautiful ESO-themed gold embed with direct ZIP download link, version, author, and changelog. (*Recommended — workflow file already included in the repo!*)
* **Option 2 (Native GitHub Webhook)**: Fast 30-second setup directly in GitHub settings without any workflow runner.

---

## Step 1: Create a Discord Webhook URL

1. In Discord, open your server and navigate to the channel where you want release messages to appear.
2. Click the **Edit Channel** (gear icon) next to the channel name.
3. Select **Integrations** from the left sidebar.
4. Click **Webhooks** &rarr; **New Webhook**.
5. Give your webhook a name (e.g., `Kwibus Random Things`) and optionally upload an avatar.
6. Click **Copy Webhook URL**.  
   It will look like:  
   `https://discord.com/api/webhooks/123456789012345678/abcdefghijklmnopqrstuvwxyz...`

---

## Option 1: Custom Rich Embed (Recommended)

This repository already includes the workflow file [`.github/workflows/release-announcement.yml`](.github/workflows/release-announcement.yml). To activate it:

1. Go to your GitHub repository: [Kwibus-Random-Things-KRT](https://github.com/Kwiebe-Kwibus/Kwibus-Random-Things-KRT).
2. Click **Settings** (top tabs of the repository).
3. In the left sidebar, click **Secrets and variables** &rarr; **Actions**.
4. Click **New repository secret**.
5. Enter:
   * **Name**: `DISCORD_WEBHOOK_URL`
   * **Secret**: Paste your Discord Webhook URL from Step 1.
6. Click **Add secret**.

### What Happens:
Whenever you publish a new release on GitHub, the workflow automatically runs, generates a rich gold embed, and posts it to your Discord channel with:
* Release title & tag
* Formatted release notes
* Direct 1-click download link for `KwibusRandomThings.zip`
* Author name and timestamp

---

## Option 2: Native GitHub-to-Discord Webhook (30-Second Setup)

If you prefer not to use GitHub Actions, Discord has a built-in GitHub webhook listener:

1. Take your Discord Webhook URL from Step 1:  
   `https://discord.com/api/webhooks/123456789/abcdef...`
2. **Append `/github` to the very end of the URL**:  
   `https://discord.com/api/webhooks/123456789/abcdef.../github`
3. In your GitHub repository, go to **Settings** &rarr; **Webhooks** &rarr; **Add webhook**.
4. Fill in the form:
   * **Payload URL**: Paste the URL ending in `/github`.
   * **Content type**: `application/json`.
   * **Which events would you like to trigger this webhook?**: Choose **Let me select individual events**, uncheck *Pushes*, and check **Releases**.
5. Click **Add webhook**.

---

## Summary Comparison

| Feature | Option 1 (GitHub Actions Embed) | Option 2 (Native Webhook) |
| :--- | :--- | :--- |
| **Setup Time** | 1 minute (add 1 secret) | 30 seconds |
| **Visual Style** | Custom ESO-gold rich embed | Standard generic GitHub embed |
| **Direct ZIP Download Link** | Included (`KwibusRandomThings.zip`) | Link to release page only |
| **Changelog Formatting** | Cleanly truncated & sanitized | Raw text |
