import requests

BASE_URL = 'http://localhost:5000/api'

# 1. Register/Login as Super_Admin
print("--- Login as Super_Admin ---")
r_admin = requests.post(f"{BASE_URL}/auth/login", json={"username": "Super_Admin", "password": "password"})
admin_token = r_admin.json().get('token')
print("Super_Admin token:", admin_token)

# 2. Register/Login as User
print("--- Login as User ---")
r_user = requests.post(f"{BASE_URL}/auth/login", json={"username": "testuser", "password": "password"})
user_token = r_user.json().get('token')
print("User token:", user_token)

# 3. User tries to get user list
print("--- User tries to get users list (Should be 403 Forbidden) ---")
headers_user = {"Authorization": f"Bearer {user_token}"}
r_get_users = requests.get(f"{BASE_URL}/v1/forum/users", headers=headers_user)
print("User get users status:", r_get_users.status_code)
assert r_get_users.status_code == 403, "Failed: User should not be able to get users list"

# 4. Super_Admin gets user list
print("--- Super_Admin gets users list (Should be 200 OK) ---")
headers_admin = {"Authorization": f"Bearer {admin_token}"}
r_get_users_admin = requests.get(f"{BASE_URL}/v1/forum/users", headers=headers_admin)
print("Super_Admin get users status:", r_get_users_admin.status_code)
assert r_get_users_admin.status_code == 200, "Failed: Super_Admin should be able to get users list"
users = r_get_users_admin.json()
print("Users:", users)
user_id = next(u['id'] for u in users if u['username'] == 'testuser')

# 5. Super_Admin updates User role to Moderator
print("--- Super_Admin updates testuser's role to Moderator ---")
r_put_role = requests.put(f"{BASE_URL}/v1/forum/users/{user_id}/role", json={"role": "Moderator"}, headers=headers_admin)
print("Super_Admin update role status:", r_put_role.status_code)
assert r_put_role.status_code == 200, "Failed: Super_Admin should be able to update role"

print("ALL TESTS PASSED!")
