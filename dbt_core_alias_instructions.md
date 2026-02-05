# How to Set Up a `dbtcore` Alias

This lets you run `dbtcore run` instead of `dbt run` to use your local dbt Core installation.

### This is a bit of a pain to do but if you want to alias dbt core like I have done in the video follow the below instructions 

## Step 1: Find Your Shell Type

Run this command:
```bash
echo $SHELL
```

- If you see `/bin/zsh` → you use zsh (most Mac users)
- If you see `/bin/bash` → you use bash

## Step 2: Open Your Config File

**For zsh users (most common):**
```bash
open ~/.zshrc
```

**For bash users:**
```bash
open ~/.bashrc
```

## Step 3: Add These Lines

Add these 3 lines to the bottom of your file:

```bash
# dbt Core alias setup
export PATH=/Users/YOUR_USERNAME/dbtcore/bin:$PATH
alias dbtcore="/Users/YOUR_USERNAME/dbtcore/bin/dbt"
```

**Important:** Replace `YOUR_USERNAME` with your actual username!

## Step 4: Save and Reload

1. Save the file (Cmd+S)
2. Close the file
3. Run this command to reload:

**For zsh:**
```bash
source ~/.zshrc
```

**For bash:**
```bash
source ~/.bashrc
```

## Step 5: Test It

Run this to make sure it works:
```bash
dbtcore --version
```

You should see your dbt Core version info.

## Now You Can Use It!

Instead of `dbt run`, use:
```bash
dbtcore run
dbtcore test
dbtcore compile
```

## Need Help?

- **"Command not found"** → Make sure you replaced `YOUR_USERNAME` with your actual username
- **"Permission denied"** → Run: `chmod +x /Users/YOUR_USERNAME/dbtcore/bin/dbt`
- **Still not working?** → Check that `/Users/YOUR_USERNAME/dbtcore/bin/dbt` actually exists

That's it! 🎉
