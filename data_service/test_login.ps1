$ErrorActionPreference = "Stop"

$loginBody = @{ username = "admin"; password = "Ngocanh@admin1" } | ConvertTo-Json
try {
    $loginRes = Invoke-RestMethod -Uri http://localhost:5169/api/auth/login -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host "Success! Token: $($loginRes.token)"
} catch {
    Write-Host "Failed: $($_.Exception.Message)"
}
