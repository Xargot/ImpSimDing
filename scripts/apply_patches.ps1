# 1. Create a branch for the changes
git checkout -b automated/patches

# 2. Run the script that applies patches (example)
.\scripts\apply_patches.ps1

# 3. Inspect changes
git status
git diff

# 4. Stage and commit if everything looks good
git add -A
git commit -m "Apply automated patches: UI, minimap, options, CI, packaging"

# 5. Push branch
git push -u origin automated/patches
