import re

file_path = "/home/abubakar/kflkiosk/.github/workflows/auto-build-installers.yml"
with open(file_path, "r") as f:
    content = f.read()

# Replace NSIS Publisher from $env:FLAVOR_APP_NAME to TECHBIZ LIMITED
content = content.replace(
    '\'  WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\' + $env:FLAVOR_APP_NAME + \'" "Publisher" "\' + $env:FLAVOR_APP_NAME + \'"\'',
    '\'  WriteRegStr HKLM "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\\' + $env:FLAVOR_APP_NAME + \'" "Publisher" "TECHBIZ LIMITED"\''
)


exe_sign_block = """      - name: Sign Windows executable
        shell: pwsh
        timeout-minutes: 15
        continue-on-error: true
        env:
          WINDOWS_CERTIFICATE: ${{ secrets.WINDOWS_CERTIFICATE }}
          WINDOWS_CERTIFICATE_PASSWORD: ${{ secrets.WINDOWS_CERTIFICATE_PASSWORD }}
        run: |
          $exePath = "build\\windows\\x64\\runner\\Release\\$env:FLAVOR_APP_NAME.exe"
          $certPath = Join-Path $env:TEMP "cert.pfx"
          $certPassword = ""
          
          if ($env:WINDOWS_CERTIFICATE -and $env:WINDOWS_CERTIFICATE_PASSWORD) {
            Write-Host "Using provided code signing certificate from secrets..."
            $certBytes = [Convert]::FromBase64String($env:WINDOWS_CERTIFICATE)
            [IO.File]::WriteAllBytes($certPath, $certBytes)
            $certPassword = $env:WINDOWS_CERTIFICATE_PASSWORD
          } else {
            Write-Host "Generating self-signed certificate for TECHBIZ LIMITED..."
            $cert = New-SelfSignedCertificate -Subject "CN=TECHBIZ LIMITED" -Type CodeSigningCert -CertStoreLocation "Cert:\CurrentUser\My"
            $securePwd = ConvertTo-SecureString -String "Techbiz123" -Force -AsPlainText
            Export-PfxCertificate -Cert $cert -FilePath $certPath -Password $securePwd | Out-Null
            $certPassword = "Techbiz123"
            
            # Export for the installer signing step
            "WIN_CERT_PATH=$certPath" | Out-File -FilePath "$env:GITHUB_ENV" -Append -Encoding utf8
            "WIN_CERT_PASSWORD=$certPassword" | Out-File -FilePath "$env:GITHUB_ENV" -Append -Encoding utf8
          }
          
          try {
            $signToolPath = Get-ChildItem -Path "C:\Program Files (x86)\Windows Kits\10\\bin\\" -Recurse -Include "signtool.exe" -ErrorAction SilentlyContinue |
              Where-Object { $_.Directory.FullName -match "\\\\x64$" } |
              Select-Object -First 1 -ExpandProperty FullName
            
            if (-not $signToolPath) {
              Write-Warning "signtool.exe not found - skipping signing"
              exit 0
            }
            
            Write-Host "Using signtool from: $signToolPath"
            
            # Sign the executable
            if ($env:WINDOWS_CERTIFICATE -and $env:WINDOWS_CERTIFICATE_PASSWORD) {
              & $signToolPath sign /f $certPath /p $certPassword /tr http://timestamp.digicert.com /td SHA256 /fd SHA256 $exePath
            } else {
              & $signToolPath sign /f $certPath /p $certPassword /fd SHA256 $exePath
            }
            
            if ($LASTEXITCODE -ne 0) {
              Write-Warning "Code signing failed with exit code $LASTEXITCODE"
              exit 0
            }
            
            Write-Host "✓ Executable signed successfully"
          }
          catch {
            Write-Warning "Code signing error: $_"
          }
          finally {
            if ($env:WINDOWS_CERTIFICATE -and $env:WINDOWS_CERTIFICATE_PASSWORD) {
              if (Test-Path $certPath) { Remove-Item $certPath -Force -ErrorAction SilentlyContinue }
            }
          }
"""

# use split to replace blocks
parts1 = content.split("      - name: Sign Windows executable\n")
if len(parts1) == 2:
    subparts1 = parts1[1].split("\n      - name: Save signed executable to artifacts\n")
    if len(subparts1) >= 2:
        content = parts1[0] + exe_sign_block + "      - name: Save signed executable to artifacts\n" + "\n      - name: Save signed executable to artifacts\n".join(subparts1[1:])

installer_sign_block = """      - name: Sign Windows installer
        shell: pwsh
        timeout-minutes: 15
        continue-on-error: true
        env:
          WINDOWS_CERTIFICATE: ${{ secrets.WINDOWS_CERTIFICATE }}
          WINDOWS_CERTIFICATE_PASSWORD: ${{ secrets.WINDOWS_CERTIFICATE_PASSWORD }}
        run: |
          $installerPath = "dist\\${env:FLAVOR_APP_NAME}-${env:VERSION}-Setup.exe"
          $certPath = ""
          $certPassword = ""
          
          if ($env:WINDOWS_CERTIFICATE -and $env:WINDOWS_CERTIFICATE_PASSWORD) {
            $certPath = Join-Path $env:TEMP "cert_installer.pfx"
            $certBytes = [Convert]::FromBase64String($env:WINDOWS_CERTIFICATE)
            [IO.File]::WriteAllBytes($certPath, $certBytes)
            $certPassword = $env:WINDOWS_CERTIFICATE_PASSWORD
          } elseif ($env:WIN_CERT_PATH -and $env:WIN_CERT_PASSWORD) {
            $certPath = $env:WIN_CERT_PATH
            $certPassword = $env:WIN_CERT_PASSWORD
          } else {
            Write-Warning "No certificate found for installer signing."
            exit 0
          }
          
          try {
            $signToolPath = Get-ChildItem -Path "C:\Program Files (x86)\Windows Kits\10\\bin\\" -Recurse -Include "signtool.exe" -ErrorAction SilentlyContinue |
              Where-Object { $_.Directory.FullName -match "\\\\x64$" } |
              Select-Object -First 1 -ExpandProperty FullName
            
            if (-not $signToolPath) {
              Write-Warning "signtool.exe not found - skipping installer signing"
              exit 0
            }
            
            if ($env:WINDOWS_CERTIFICATE -and $env:WINDOWS_CERTIFICATE_PASSWORD) {
              & $signToolPath sign /f $certPath /p $certPassword /tr http://timestamp.digicert.com /td SHA256 /fd SHA256 $installerPath
            } else {
               & $signToolPath sign /f $certPath /p $certPassword /fd SHA256 $installerPath
            }
            
            if ($LASTEXITCODE -ne 0) {
              Write-Warning "Installer signing failed with exit code $LASTEXITCODE"
              exit 0
            }
            
            Write-Host "✓ Installer signed successfully"
          }
          catch {
            Write-Warning "Installer signing error: $_"
          }
          finally {
            if ($env:WINDOWS_CERTIFICATE -and $env:WINDOWS_CERTIFICATE_PASSWORD) {
              if (Test-Path $certPath) { Remove-Item $certPath -Force -ErrorAction SilentlyContinue }
            }
          }
"""

parts2 = content.split("      - name: Sign Windows installer\n")
if len(parts2) == 2:
    subparts2 = parts2[1].split("\n      - name: Save signed installer to artifacts\n")
    if len(subparts2) >= 2:
        content = parts2[0] + installer_sign_block + "      - name: Save signed installer to artifacts\n" + "\n      - name: Save signed installer to artifacts\n".join(subparts2[1:])

with open(file_path, "w") as f:
    f.write(content)

print("Workflow updated.")
