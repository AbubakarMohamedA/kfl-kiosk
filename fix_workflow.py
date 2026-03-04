import re

file_path = "/home/abubakar/kflkiosk/.github/workflows/auto-build-installers.yml"
with open(file_path, "r") as f:
    content = f.read()

# Fix 1: Trivy step error handling
trivy_pattern = r'trivy fs --format table --output security-report\.txt \. \|\| echo "Trivy scan completed with warnings"'
trivy_replacement = r'trivy fs --format table --output security-report.txt . || echo "Trivy scan failed or completed with warnings, continuing..."'
content = re.sub(trivy_pattern, trivy_replacement, content)

# Also fix the CycloneDX missing package issue by downloading the binary directly if apt fails
cyclonedx_pattern = r'sudo apt-get install -y cyclonedx-cli \|\| echo "CycloneDX not available"'
cyclonedx_replacement = r'''sudo apt-get install -y cyclonedx-cli || {
            echo "CycloneDX apt package not found, downloading binary..."
            wget -q https://github.com/CycloneDX/cyclonedx-cli/releases/download/v0.25.0/cyclonedx-linux-x64
            sudo mv cyclonedx-linux-x64 /usr/local/bin/cyclonedx
            sudo chmod +x /usr/local/bin/cyclonedx
          }'''
content = re.sub(cyclonedx_pattern, cyclonedx_replacement, content)

# Fix 2: pins-branch checkout failure
# We need to create the branch if it doesn't exist, rather than failing the checkout
pins_checkout_pattern = r'      - name: Checkout pins branch\n        uses: actions/checkout@v4\n        with:\n          ref: pins-branch\n          path: pins-repo\n          fetch-depth: 1'
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
'''
content = re.sub(pins_checkout_pattern, pins_checkout_replacement, content)

with open(file_path, "w") as f:
    f.write(content)

print("Workflow fixed.")
