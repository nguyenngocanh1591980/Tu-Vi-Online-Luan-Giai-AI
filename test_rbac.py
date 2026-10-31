import requests

BASE_URL = 'http://localhost:5000/api'

# 1. Login as Admin
print("--- Login as Admin ---")
r_admin = requests.post(f"{BASE_URL}/auth/login", json={"username": "Admin", "password": "password"})
admin_token = r_admin.json()['token']
print("Admin token:", admin_token)

# 2. Login as User
print("--- Login as User (testuser) ---")
r_user = requests.post(f"{BASE_URL}/auth/login", json={"username": "testuser", "password": "password"})
user_token = r_user.json()['token']
print("User token:", user_token)

# 3. Admin creates topic
print("--- Admin creates topic ---")
headers_admin = {"Authorization": f"Bearer {admin_token}"}
r_topic = requests.post(f"{BASE_URL}/v1/forum/topics", json={"title": "Test Topic", "content": "Hello", "categoryId": 1}, headers=headers_admin)
topic_id = r_topic.json()['id']
print("Topic ID created by admin:", topic_id)

# 4. User tries to delete admin's topic
print("--- User tries to delete admin's topic (Should be 403 Forbidden) ---")
headers_user = {"Authorization": f"Bearer {user_token}"}
r_delete_user = requests.delete(f"{BASE_URL}/v1/forum/topics/{topic_id}", headers=headers_user)
print("User delete status:", r_delete_user.status_code)
assert r_delete_user.status_code == 403, "Failed: User should not be able to delete admin's topic"

# 5. User creates topic
print("--- User creates topic (Should be 403 because no category permissions setup for User) ---")
r_topic_user = requests.post(f"{BASE_URL}/v1/forum/topics", json={"title": "Test Topic User", "content": "Hello", "categoryId": 1}, headers=headers_user)
print("User create topic status:", r_topic_user.status_code)
assert r_topic_user.status_code == 403, "Failed: User should not be able to create topic by default"

print("ALL TESTS PASSED!")
