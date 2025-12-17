
# EliteSoftware Local Backend Script
#
# INSTRUCTIONS:
# 1. Rename this file from "powershellscript.txt" to "backend.ps1".
# 2. Place it in the same folder as your index.html file.
# 3. Open PowerShell, navigate to this folder, and run: .\backend.ps1
# 4. Keep this PowerShell window running while you use the application.
# 5. Open your web browser and go to http://localhost:8080
#
# This script starts a local web server on http://localhost:8080.
# It serves the main application (index.html, etc.) and handles a data API
# that reads from and writes to a file named 'database.json' in the same directory.

$port = 8080
$ipAddress = "127.0.0.1"
$url = "http://$ipAddress`:$port/"
$databaseFile = Join-Path $PSScriptRoot "database.json"
$imagesPath = Join-Path $PSScriptRoot "images"
$postsPath = Join-Path $PSScriptRoot "posts"
$videosPath = Join-Path $PSScriptRoot "videos"

# --- Create required directories and database file ---
if (-not (Test-Path $imagesPath)) { New-Item -ItemType Directory -Path $imagesPath | Out-Null }
if (-not (Test-Path $postsPath)) { New-Item -ItemType Directory -Path $postsPath | Out-Null }
if (-not (Test-Path $videosPath)) { New-Item -ItemType Directory -Path $videosPath | Out-Null }

if (-not (Test-Path $databaseFile)) {
    Write-Host "Database file not found. Creating '$databaseFile' with default data..."
    $initialData = [PSCustomObject]@{
        "es_hosts" = @()
        "es_posts" = @()
        "es_users" = @([PSCustomObject]@{ id = 1; username = 'admin'; password = 'password'; role = 'admin'; registrationDate = [DateTime]::UtcNow.ToString("o") })
        "es_services" = @() # Services will now be managed under page content
        "es_page_content" = [PSCustomObject]@{
            "home" = @{
                "title" = "Welcome to the Southern Branch Corporate Portal";
                "p1" = "Welcome to the official intranet portal for the Southern Branch of EliteSoftware Co. Limited. This site provides internal access to company news, project portfolios, service catalogs, and advanced administrative tools.";
                "p2" = "Our commitment to excellence and innovation drives us to deliver cutting-edge software solutions. Here, you will find resources and information that reflect our core values and technological expertise.";
                "card1_title" = "Our Services";
                "card1_text" = "Explore our comprehensive software and network solutions.";
                "card2_title" = "Project Portfolio";
                "card2_text" = "View a showcase of our successful engineering accomplishments.";
                "card3_title" = "AI PowerShell Studio";
                "card3_text" = "Access advanced tools for script generation and modification.";
            };
            "about" = @{
                "title" = "About EliteSoftware Co. Limited";
                "p1" = "Founded on the principles of innovation and reliability, EliteSoftware Co. Limited provides bespoke software solutions for a variety of industries. The Southern Branch specializes in network infrastructure tools, legacy system modernization, and the development of high-performance administrative applications.";
                "mission_title" = "Our Mission";
                "mission_text" = "To empower businesses by engineering robust, efficient, and scalable software solutions that solve complex problems and drive growth. We are committed to delivering excellence and building long-lasting partnerships with our clients.";
                "values_title" = "Core Values";
                "value1" = "<strong>Innovation:</strong> We constantly explore new technologies to provide cutting-edge solutions.";
                "value2" = "<strong>Integrity:</strong> We operate with transparency and uphold the highest ethical standards.";
                "value3" = "<strong>Excellence:</strong> We are dedicated to quality, precision, and reliability in every project we undertake.";
                "value4" = "<strong>Collaboration:</strong> We work closely with our clients to ensure our solutions perfectly align with their vision.";
            };
            "services" = @{
                "title" = "Our Services";
                "intro" = "We offer a range of expert services tailored to meet the demands of modern digital infrastructure. Our team combines technical excellence with a deep understanding of business needs to deliver impactful solutions.";
                "list" = @(
                    @{ "id"="s1"; "title"="Custom Software Development"; "description"="We build tailor-made software applications from the ground up, designed specifically to address your unique business challenges and workflows."; "features"="Bespoke application architecture,Scalable and secure backends,API development and integration,Cross-platform compatibility" },
                    @{ "id"="s2"; "title"="Web & Mobile Applications"; "description"="From responsive corporate websites to powerful cross-platform mobile apps, we create digital experiences that prioritize information clarity, performance, and user engagement."; "features"="Responsive web design,Progressive Web Apps (PWA),Native iOS & Android development,UI/UX design and prototyping" },
                    @{ "id"="s3"; "title"="Legacy System Modernization"; "description"="Breathe new life into your outdated systems. We specialize in migrating and upgrading legacy software to modern, secure, and efficient platforms without disrupting your core business operations."; "features"="System analysis and re-engineering,Data migration and validation,Cloud integration (Azure, AWS),Performance optimization" },
                    @{ "id"="s4"; "title"="Network Administration Tools"; "description"="Leveraging deep expertise in systems administration, we develop custom PowerShell and Python-based tools to automate and simplify complex network management tasks."; "features"="Automated deployment scripts,Custom GUI-based management tools,Network monitoring solutions,Active Directory integration" }
                )
            };
            "projects" = @{
                "title" = "Project Portfolio";
                "intro" = "A showcase of our successful projects and engineering accomplishments. These projects highlight our capabilities in creating robust, user-friendly, and powerful administrative tools.";
                "list" = @(
                    @{ "id"="p1"; "title"="Project Phoenix: WebHosting Suite"; "description"="A comprehensive GUI application for managing local web, FTP, and email servers. Built with PowerShell and a Python backend, it provides a persistent, multi-service environment for local development and testing."; "tech"="PowerShell,WinForms,Python,pyftpdlib,SSL/TLS" },
                    @{ "id"="p2"; "title"="QuantumLeap: Node.js Launcher"; "description"="A simple yet powerful utility to streamline the setup and execution of Node.js projects. The tool provides a clean GUI to run install and development commands, abstracting away terminal usage for faster onboarding."; "tech"="PowerShell,Node.js,npm,GUI Automation" },
                    @{ "id"="p3"; "title"="AuraNet: Admin Suite v4.1"; "description"="The flagship all-in-one utility for local development and network management. This suite includes multi-server management, a self-signed Certificate Authority, a hosts file manager, and various network diagnostic tools."; "tech"="PowerShell,.NET,Python,WMI,REST API" }
                )
            }
        }
        "es_forum_topics" = @([PSCustomObject]@{id = 1; title = 'Welcome to the Community Forums!'; authorId = 1; authorName = 'admin'; date = '2025-08-24T10:00:00Z'})
        "es_forum_replies" = @([PSCustomObject]@{id = 1; topicId = 1; authorId = 1; authorName = 'admin'; date = '2025-08-24T10:00:00Z'; content = 'This is the first topic to get things started. Feel free to create your own topics or reply here!'})
        "es_currentUser" = $null
    }
    $initialData | ConvertTo-Json -Depth 10 | Set-Content -Path $databaseFile -Encoding UTF8
}

# --- Helper Function to Get MIME Type ---
function Get-MimeType {
    param($extension)
    switch ($extension) {
        ".html" { "text/html" }
        ".css" { "text/css" }
        ".js" { "application/javascript" }
        ".tsx" { "application/javascript" } # Serve tsx as javascript for the browser/babel
        ".png" { "image/png" }
        ".jpg" { "image/jpeg" }
        ".jpeg" { "image/jpeg" }
        ".gif" { "image/gif" }
        ".svg" { "image/svg+xml" }
        ".txt" { "text/plain" }
        ".md" { "text/markdown" }
        ".mp4" { "video/mp4" }
        ".webm" { "video/webm" }
        ".ogg" { "video/ogg" }
        default { "application/octet-stream" }
    }
}

# --- Helper function to parse multipart/form-data ---
function Parse-MultipartFormData {
    param($request)
    $boundary = $request.ContentType.Split('=')[1]
    $inputStream = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
    $content = $inputStream.ReadToEnd()
    $parts = $content.Split("--$boundary") | Where-Object { $_.Trim() -ne "" -and $_.Trim() -ne "--" }
    
    foreach ($part in $parts) {
        $headerEndIndex = $part.IndexOf("`r`n`r`n")
        if ($headerEndIndex -lt 0) { continue }
        
        $headers = $part.Substring(0, $headerEndIndex).Trim()
        $body = $part.Substring($headerEndIndex + 4)
        
        if ($headers -match 'filename="([^"]+)"') {
            $filename = $matches[1]
            # Remove the trailing CRLF
            $bodyBytes = $request.ContentEncoding.GetBytes($body.TrimEnd("`r`n"))
            return @{ "filename" = $filename; "content" = $bodyBytes }
        }
    }
    return $null
}

# --- Start HTTP Listener ---
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($url)
Write-Host "Starting local backend server on $url"
Write-Host "Database file: $databaseFile"
Write-Host "Serving application from: $PSScriptRoot"
Write-Host "Press CTRL+C to stop the server."
$listener.Start()

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $urlPath = $request.Url.AbsolutePath
        $httpMethod = $request.HttpMethod

        # --- Handle CORS ---
        $response.AddHeader("Access-Control-Allow-Origin", "*")
        if ($httpMethod -eq "OPTIONS") {
            $response.AddHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            $response.AddHeader("Access-Control-Allow-Headers", "Content-Type") # Corrected casing
            $response.StatusCode = 204
            $response.Close()
            continue
        }

        try {
            # --- API: GET /api/data ---
            if ($urlPath -eq "/api/data" -and $httpMethod -eq "GET") {
                # Load database from file
                $dbObject = Get-Content -Path $databaseFile -Raw | ConvertFrom-Json
                
                if (-not $dbObject.PSObject.Properties['es_posts']) {
                    $dbObject | Add-Member -MemberType NoteProperty -Name 'es_posts' -Value @()
                }

                # Dynamically load blog posts from /posts directory
                $filePosts = @()
                $postFiles = Get-ChildItem -Path $postsPath -Include *.txt, *.md
                foreach ($file in $postFiles) {
                    $contentLines = Get-Content $file.FullName
                    $title = $contentLines[0]
                    $content = $contentLines | Select-Object -Skip 1 | Out-String
                    $postId = ($file.Name.GetHashCode() -band 0x7FFFFFFF)
                    $format = if ($file.Extension -eq ".md") { "markdown" } else { "plaintext" }
                    
                    $filePosts += [PSCustomObject]@{
                        id = $postId; title = $title; content = $content; author = "System"
                        date = $file.LastWriteTime.ToString("dd-MMM-yyyy"); isFromFile = $true; format = $format
                    }
                }
                $dbObject.es_posts = @($dbObject.es_posts | Where-Object { -not $_.isFromFile }) + $filePosts
                
                $dbContent = $dbObject | ConvertTo-Json -Depth 10
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($dbContent)
                $response.ContentLength64 = $buffer.Length
                $response.ContentType = 'application/json'
                Write-Host "GET /api/data: Served database."
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            # --- API: POST /api/data ---
             elseif ($urlPath -eq "/api/data" -and $httpMethod -eq "POST") {
                $bodyStream = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $body = $bodyStream.ReadToEnd()
                $bodyStream.Close()
                
                $bodyObject = $body | ConvertFrom-Json
                
                if ($bodyObject.PSObject.Properties['es_posts']) {
                    $bodyObject.es_posts = @($bodyObject.es_posts | Where-Object { -not $_.isFromFile })
                }
                
                $bodyObject | ConvertTo-Json -Depth 10 | Set-Content -Path $databaseFile -Encoding UTF8
                
                $response.StatusCode = 200
                Write-Host "POST /api/data: Database updated."
            }
            # --- API: GET /api/images ---
            elseif ($urlPath -eq "/api/images" -and $httpMethod -eq "GET") {
                $images = Get-ChildItem -Path $imagesPath | Select-Object -ExpandProperty Name
                $jsonResponse = $images | ConvertTo-Json
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
                $response.ContentType = 'application/json'
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            # --- API: GET /api/videos ---
            elseif ($urlPath -eq "/api/videos" -and $httpMethod -eq "GET") {
                $videos = Get-ChildItem -Path $videosPath | Select-Object -ExpandProperty Name
                $jsonResponse = $videos | ConvertTo-Json
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
                $response.ContentType = 'application/json'
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            # --- API: POST /api/upload ---
            elseif ($urlPath -eq "/api/upload" -and $httpMethod -eq "POST") {
                $fileData = Parse-MultipartFormData -request $request
                if ($fileData) {
                    $filePath = Join-Path $imagesPath $fileData.filename
                    [System.IO.File]::WriteAllBytes($filePath, $fileData.content)
                    $response.StatusCode = 200
                    Write-Host "Uploaded file $($fileData.filename) successfully."
                } else {
                    $response.StatusCode = 400
                    Write-Error "Failed to parse uploaded file."
                }
            }
            # --- Static File Serving ---
            else {
                $filePath = ""
                # Default to index.html for root path
                if ($urlPath -eq "/") {
                    $filePath = Join-Path $PSScriptRoot "index.html"
                } else {
                    # Serve other files from the root directory
                    $filePath = Join-Path $PSScriptRoot ($urlPath.TrimStart("/"))
                }

                if (Test-Path $filePath -PathType Leaf) {
                    $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
                    $response.ContentType = Get-MimeType -extension ([System.IO.Path]::GetExtension($filePath))
                    $response.ContentLength64 = $fileBytes.Length
                    $response.OutputStream.Write($fileBytes, 0, $fileBytes.Length)
                } else {
                    # Fallback for Single Page App routing: if a path doesn't match a file, serve index.html
                    $indexPath = Join-Path $PSScriptRoot "index.html"
                    if(Test-Path $indexPath) {
                        $fileBytes = [System.IO.File]::ReadAllBytes($indexPath)
                        $response.ContentType = "text/html"
                        $response.ContentLength64 = $fileBytes.Length
                        $response.OutputStream.Write($fileBytes, 0, $fileBytes.Length)
                    } else {
                        $response.StatusCode = 404
                    }
                }
            }
        } catch {
            $errorMessage = "Error processing request: $($_.Exception.Message)"
            Write-Error $errorMessage
            $response.StatusCode = 500
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($errorMessage)
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        } finally {
            $response.Close()
        }
    }
}
finally {
    Write-Host "Stopping local backend server."
    $listener.Stop()
    $listener.Close()
}
