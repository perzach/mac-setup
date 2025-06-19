#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Good morning
# @raycast.mode compact

# Optional parameters:
# @raycast.icon ☕️

open -a "Google Chrome" --args --profile-directory="Profile 1"
open -a "Slack"
open -a "Microsoft Teams"
open -a "Microsoft Outlook"
open -a "IntelliJ IDEA Ultimate"
open -a "iTerm"
open -a "Notes"

# Open news pages
sleep 5
open -na "Google Chrome" --args --new-window \
"https://www.tek.no/" \
"https://www.nrk.no/" \
"https://www.tv2.no/" \
"https://www.e24.no/" \
"https://bt.no/"