Add-Type -AssemblyName Microsoft.VisualBasic
$targetFolder = "E:\Tu vi online\AI học tử vi\Kiểm Tra Quá Trình Học Kiến Thức Của AI\Báo Cáo Quét Định Kỳ"
$cutoffDate = (Get-Date).AddDays(-3)

if (Test-Path $targetFolder) {
    # Lấy các file có ngày tạo hoặc ngày sửa đổi cũ hơn 3 ngày
    $files = Get-ChildItem -Path $targetFolder -File | Where-Object { $_.CreationTime -le $cutoffDate -or $_.LastWriteTime -le $cutoffDate }
    foreach ($file in $files) {
        try {
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($file.FullName, 'OnlyErrorDialogs', 'SendToRecycleBin')
        } catch {
            # Ignore errors
        }
    }
}
