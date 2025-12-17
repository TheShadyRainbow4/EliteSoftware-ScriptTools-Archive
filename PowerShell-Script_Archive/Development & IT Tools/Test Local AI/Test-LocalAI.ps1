# --- Local AI Test Script v1.1 ---
# Description: Sends a prompt to the user's specific local AI model hosted by LM Studio.
# Updated with correct IP Address and Model Name.

# 1. Define the server address from your LM Studio setup
$apiUrl = "http://192.168.10.100:1234/v1/chat/completions"

# 2. Define the headers for our web request
$headers = @{
    "Content-Type" = "application/json"
}

# 3. Create the payload (the data we send to the AI)
# This structure is based on the OpenAI API standard.
$body = @{
    # Updated to use the model identifier from your screenshot
    model = "google/gemma-3-12b" 
    messages = @(
        @{
            role = "system"
            content = "You are a helpful assistant for an 'Elite' software utility developer."
        },
        @{
            role = "user"
            content = "In three sentences, what makes PowerShell a powerful tool for Windows administration?"
        }
    )
    temperature = 0.7 
} | ConvertTo-Json -Depth 5 

# 4. Make the API Call
Write-Host "Sending prompt to your Gemma 3 12B model at $($apiUrl)..." -ForegroundColor Yellow
try {
    # Increased timeout for larger models
    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body -TimeoutSec 300

    # 5. Process and Display the Response
    $aiMessage = $response.choices[0].message.content
    
    Write-Host "`n--- AI Response ---" -ForegroundColor Green
    Write-Host $aiMessage
    Write-Host "-------------------" -ForegroundColor Green

}
catch {
    Write-Host "`nAn error occurred!" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)"
    Write-Host "Please ensure your LM Studio server is running and reachable at the specified address."
}