$filePath = 'd:\NeUshare\entry\src\main\ets\pages\DetailPage.ets'
$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

# Replace '#0E0E10' patterns
$content = $content.Replace("this.isDarkMode ? '#0E0E10' : ColorTokens.TEXT_WHITE", 'ColorTokens.textOnPrimary(this.isDarkMode)')
$content = $content.Replace("this.isDarkMode ? '#0E0E10' : ColorTokens.primary(this.isDarkMode)", 'ColorTokens.textOnPrimary(this.isDarkMode)')

# Replace TEXT_DISABLED
$content = $content.Replace('ColorTokens.TEXT_DISABLED', 'ColorTokens.textDisabled(this.isDarkMode)')

[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
Write-Host 'Done'
