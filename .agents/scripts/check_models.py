import os
import google.generativeai as genai
import sys

if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

api_key = os.environ.get("GEMINI_API_KEY")
genai.configure(api_key=api_key)

print("Checking available models for this API Key...")
try:
    for m in genai.list_models():
        if 'generateContent' in m.supported_generation_methods:
            print(f"- {m.name}")
except Exception as e:
    print(f"Error checking models: {e}")
