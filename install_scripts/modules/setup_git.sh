#!/usr/bin/env bash

# set -x
#^ Debug
read -rp "Enter your name: " varName
read -rp "Enter your email: " varEmail
read -rp "Enter default branch name (main/master): " varBranchName
read -rp 'Are you using MacOS, Linux, or Windows? (M/L/W): ' varOS
read -rp 'Enter path to default editor $(echo $VISUAL): ' varEditorPath
read -rp "Change difftool to nvimdiff? (y/n): " varDiffAnswer

varNvd="nvimdiff"

# Setup auto CRLF
if [ "$varOS" = "M" ] || [ "$varOS" = "m" ]; then
    git config --global core.autocrlf input
elif [ "$varOS" = "L" ] || [ "$varOS" = "l" ]; then
    git config --global core.autocrlf input
elif [ "$varOS" = "W" ] || [ "$varOS" = "w" ]; then
    git config --global core.autocrlf true
else
    echo "No OS provided"
fi

# Setup username
if [[ $varName = "" ]]; then
    echo "No name provided"
else
    git config --global user.name "$varName"
fi

# Setup email
if [[ $varEmail = "" ]]; then
    echo "No email provided"
else
    git config --global user.email "$varEmail"
fi

# Setup default branch name
if [[ $varBranchName = "" ]]; then
    echo "No branch name provided"
else
    git config --global init.defaultBranch "$varBranchName"
fi

# Setup default editor
if [[ $varEditorPath = "" ]]; then
    echo "No editor path provided"
else
    git config --global core.editor "$varEditorPath"
fi

# Setup nvimdiff
if [[ $varDiffAnswer = "" ]] || [[ $varDiffAnswer = "n" ]]; then
    echo "Git diff tool using default."
else
    git config --global diff.tool "$varNvd"
    git config --global --add difftool.prompt false
fi
