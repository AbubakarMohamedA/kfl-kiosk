import re

file_path = "/home/abubakar/kflkiosk/.github/workflows/auto-build-installers.yml"
with open(file_path, "r") as f:
    content = f.read()

# The pins issue is because the initial fetch in the github action checks out the repository.
# But when creating a new branch and pushing it, we need to make sure the token and permissions are all set correctly.
# The error "The process '/usr/bin/git' failed with exit code 1" during fetch means the branch doesn't exist remotely,
# and it tried to fetch it. The checkout action with `continue-on-error: true` should have caught that, but it didn't seem to work,
# or it failed during the `actions/checkout` initialization.
# Better approach: Check out the main branch, then create the orphan pins branch.

pins_checkout_pattern = r'''    steps:\n      - name: Checkout pins branch\n        uses: actions/checkout@v4\n        continue-on-error: true\n        id: checkout-pins\n        with:\n          ref: pins-branch\n          path: pins-repo\n          fetch-depth: 1\n\n      - name: Initialize pins branch if missing\n        if: steps.checkout-pins.outcome == 'failure'\n        run: \|\n          mkdir -p pins-repo\n          cd pins-repo\n          git init\n          git checkout -b pins-branch\n          echo "\{\}" > latest.json\n          git config --global user.name "GitHub Actions"\n          git config --global user.email "actions@github.com"\n          git add latest.json\n          git commit -m "Initial pins file"\n          git remote add origin https://x-access-token:\$\{\{ secrets.GITHUB_TOKEN \}\}@github.com/\$\{\{ github.repository \}\}.git\n          git push -u origin pins-branch\n          cd ..\n'''

pins_checkout_replacement = r'''    steps:
      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20

      - name: Checkout pins branch or initialize
        run: |
          mkdir -p pins-repo
          cd pins-repo
          git init
          git config --global user.name "GitHub Actions"
          git config --global user.email "actions@github.com"
          git remote add origin https://x-access-token:${{ secrets.GITHUB_TOKEN }}@github.com/${{ github.repository }}.git
          
          # Try to fetch the branch
          if git fetch origin pins-branch; then
            echo "Branch exists, checking out..."
            git checkout -b pins-branch FETCH_HEAD
          else
            echo "Branch does not exist, initializing..."
            git checkout --orphan pins-branch
            git rm -rf . || true
            echo "{}" > latest.json
            git add latest.json
            git commit -m "Initial pins file"
            git push -u origin pins-branch
          fi
          cd ..
'''

if pins_checkout_pattern in content:
    content = content.replace(pins_checkout_pattern, pins_checkout_replacement)
    print("Pins checkout logic updated completely.")
else:
    # Try regex if exact literal replace fails
    if re.search(r'Checkout pins branch.*?Initialize pins branch if missing.*?cd \.\.', content, re.DOTALL):
        content = re.sub(r'      - name: Checkout pins branch.*?cd \.\.', pins_checkout_replacement.strip(), content, flags=re.DOTALL)
        print("Pins checkout logic updated via regex.")
    else:
        print("Pins checkout pattern not found!")

with open(file_path, "w") as f:
    f.write(content)

