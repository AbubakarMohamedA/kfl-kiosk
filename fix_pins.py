import re

file_path = "/home/abubakar/kflkiosk/.github/workflows/auto-build-installers.yml"
with open(file_path, "r") as f:
    content = f.read()

# Fix the pins-branch checkout
pins_checkout_pattern = r'      - name: Checkout pins branch\n        uses: actions/checkout@v4\n        with:\n          ref: pins-branch\n          fetch-depth: 1'
pins_checkout_replacement = r'''      - name: Checkout pins branch
        uses: actions/checkout@v4
        continue-on-error: true
        id: checkout-pins
        with:
          ref: pins-branch
          path: pins-repo
          fetch-depth: 1

      - name: Initialize pins branch if missing
        if: steps.checkout-pins.outcome == 'failure'
        run: |
          mkdir -p pins-repo
          cd pins-repo
          git init
          git checkout -b pins-branch
          echo "{}" > latest.json
          git config --global user.name "GitHub Actions"
          git config --global user.email "actions@github.com"
          git add latest.json
          git commit -m "Initial pins file"
          git remote add origin https://x-access-token:${{ secrets.GITHUB_TOKEN }}@github.com/${{ github.repository }}.git
          git push -u origin pins-branch
          cd ..'''

content = re.sub(pins_checkout_pattern, pins_checkout_replacement, content)

with open(file_path, "w") as f:
    f.write(content)

print("Pins checkout fixed.")
