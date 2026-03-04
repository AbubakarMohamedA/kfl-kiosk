import re

file_path = "/home/abubakar/kflkiosk/.github/workflows/auto-build-installers.yml"
with open(file_path, "r") as f:
    content = f.read()

# Make sure we checkout with the correct path
pins_checkout_pattern = r'      - name: Checkout pins branch\n        uses: actions/checkout@v4\n        continue-on-error: true\n        id: checkout-pins\n        with:\n          ref: pins-branch\n          path: pins-repo\n          fetch-depth: 1'
pins_checkout_replacement = r'''      - name: Checkout pins branch
        uses: actions/checkout@v4
        continue-on-error: true
        id: checkout-pins
        with:
          ref: pins-branch
          path: pins-repo
          fetch-depth: 1'''

content = re.sub(pins_checkout_pattern, pins_checkout_replacement, content)

with open(file_path, "w") as f:
    f.write(content)

print("Pins checkout path fixed.")
