#!/usr/bin/env node
/**
 * Hey - Move emails to The Feed
 * Usage: node hey-move-to-feed.js [--dry-run] [--verbose]
 * 
 * Connects to existing Chrome via CDP and moves newsletter emails to The Feed
 */

const { chromium } = require('playwright');

const FEED_SENDERS = [
  'Semaphore',
  'Microsoft Store',
  'Microsoft Rewards',
  'GoRails',
  'Nexus Mods',
  'マルツエレック',
  'メルカリ',
  'BrowserStack',
  'LinkedIn Research',
  'CodeRabbit',
  'Ploom CLUB',
  'Base44',
  'Michafrar',
  'AthleteBody',
  'カクヨム',
  'Medium Newsletter',
  'Midokura',
];

const CDP_URL = 'http://127.0.0.1:18792';

async function main() {
  const dryRun = process.argv.includes('--dry-run');
  const verbose = process.argv.includes('--verbose');
  
  const log = (...args) => verbose && console.log(...args);
  
  console.log(`Hey Feed Mover ${dryRun ? '(DRY RUN)' : ''}`);
  console.log('Connecting to Chrome via CDP...');
  
  let browser;
  try {
    browser = await chromium.connectOverCDP(CDP_URL);
  } catch (err) {
    console.error(`Failed to connect to CDP at ${CDP_URL}`);
    console.error('Make sure Chrome is running with --remote-debugging-port=18792');
    process.exit(1);
  }
  
  const contexts = browser.contexts();
  if (contexts.length === 0) {
    console.error('No browser contexts found');
    process.exit(1);
  }
  
  const context = contexts[0];
  const pages = context.pages();
  log(`Found ${pages.length} pages`);
  
  // Find Hey tab or open one
  let page = pages.find(p => p.url().includes('hey.com'));
  if (!page) {
    console.log('No Hey tab found, opening one...');
    page = await context.newPage();
  }
  
  let movedCount = 0;
  
  while (true) {
    // Navigate to Imbox
    log('Navigating to Imbox...');
    await page.goto('https://app.hey.com/');
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(1000);
    
    // Get email links from "New for you" section only (not Previously Seen, not Set Aside)
    // Look for links within the main content area before "Toggle Previously Seen"
    const emailLinks = await page.locator('main h2:has-text("New for you") ~ a[href*="/topics/"]').all();
    log(`Found ${emailLinks.length} emails in "New for you"`);
    
    if (emailLinks.length === 0) {
      // Fallback: try getting all links in main before "Previously Seen"
      const allLinks = await page.locator('main a[href*="/topics/"]').all();
      log(`Fallback: Found ${allLinks.length} total email links`);
    }
    
    let foundNewsletter = false;
    
    for (const link of emailLinks) {
      const text = await link.textContent();
      const cleanText = text.replace(/\s+/g, ' ').trim();
      
      // Check if this is a newsletter
      const matchedSender = FEED_SENDERS.find(sender => 
        cleanText.toLowerCase().includes(sender.toLowerCase())
      );
      
      if (matchedSender) {
        const shortText = cleanText.substring(0, 60);
        console.log(`[${matchedSender}] ${shortText}...`);
        
        if (dryRun) {
          console.log('  → Would move to The Feed (dry run)');
          movedCount++;
          continue;
        }
        
        try {
          // Click the email to open it
          log('  Opening email...');
          await link.click();
          await page.waitForLoadState('networkidle');
          await page.waitForTimeout(1200);
          
          // Wait for action buttons to appear
          const moreBtn = page.locator('button').filter({ hasText: /More Options/ }).first();
          log('  Looking for More Options button...');
          
          const btnVisible = await moreBtn.isVisible({ timeout: 5000 }).catch(() => false);
          if (btnVisible) {
            log('  Clicking More Options...');
            await moreBtn.click();
            await page.waitForTimeout(500);
            
            // Click "Move…" menu item
            const moveItem = page.locator('[role="menuitem"]').filter({ hasText: /^Move/ }).first();
            if (await moveItem.isVisible({ timeout: 3000 }).catch(() => false)) {
              log('  Clicking Move...');
              await moveItem.click();
              await page.waitForTimeout(500);
              
              // Click "The Feed" menu item
              const feedItem = page.locator('[role="menuitem"]').filter({ hasText: 'The Feed' }).first();
              if (await feedItem.isVisible({ timeout: 3000 }).catch(() => false)) {
                log('  Clicking The Feed...');
                await feedItem.click();
                await page.waitForTimeout(1000);
                
                console.log('  ✓ Moved to The Feed');
                movedCount++;
                foundNewsletter = true;
                break;
              } else {
                console.log('  ✗ The Feed item not found');
              }
            } else {
              console.log('  ✗ Move menu item not found');
            }
          } else {
            // Try clicking "Move to The Feed" button directly (visible when email is open)
            const directFeedBtn = page.locator('button:has-text("Move to The Feed")').first();
            if (await directFeedBtn.isVisible({ timeout: 2000 }).catch(() => false)) {
              log('  Found direct "Move to The Feed" button');
              await directFeedBtn.click();
              await page.waitForTimeout(1000);
              console.log('  ✓ Moved to The Feed');
              movedCount++;
              foundNewsletter = true;
              break;
            }
            console.log('  ✗ More Options button not found');
          }
        } catch (err) {
          console.log(`  ✗ Error: ${err.message}`);
        }
        
        foundNewsletter = true;
        break;
      }
    }
    
    if (!foundNewsletter) {
      log('No more newsletters found in Imbox');
      break;
    }
  }
  
  console.log(`\nDone! ${dryRun ? 'Would move' : 'Moved'} ${movedCount} emails.`);
  
  await browser.close();
}

main().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
