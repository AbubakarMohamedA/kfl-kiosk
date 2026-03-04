import json
import copy

file_path = 'android/app/google-services.json'

with open(file_path, 'r') as f:
    data = json.load(f)

# The original client
base_client = data['client'][0]
base_package = base_client['client_info']['android_client_info']['package_name']

flavors = ['superadmin', 'manager', 'staff', 'warehouse', 'dashboard', 'kiosk']

new_clients = [base_client]

for flavor in flavors:
    new_client = copy.deepcopy(base_client)
    new_client['client_info']['android_client_info']['package_name'] = f"{base_package}.{flavor}"
    new_clients.append(new_client)

data['client'] = new_clients

with open(file_path, 'w') as f:
    json.dump(data, f, indent=2)

print("Updated google-services.json successfully!")
