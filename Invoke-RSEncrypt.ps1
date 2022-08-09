function EncryptFile {
    param (
        $Key, $InputFileName, $OutputFileName
    )

    $AES = New-Object System.Security.Cryptography.AesManaged
    $AES.Mode = [System.Security.Cryptography.CipherMode]::ECB
    $AES.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $AES.Key = $Key

    $Encryptor = $AES.CreateEncryptor()

    $Data = [System.IO.File]::ReadAllBytes($InputFileName)

    $Enc = $Encryptor.TransformFinalBlock($Data, 0, $Data.Length)
    $Enc = [System.Convert]::ToBase64String($Enc)

    $Enc | Out-File $OutputFileName
}


function DecryptFile {
    param (
        $Key, $InputFileName, $OutputFileName
    )

    $AES = New-Object System.Security.Cryptography.AesManaged
    $AES.Mode = [System.Security.Cryptography.CipherMode]::ECB
    $AES.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $AES.Key = $key

    $decryptor = $AES.CreateDecryptor()

    $Enc = Get-Content $InputFileName
    $Enc = [System.Convert]::FromBase64String($Enc)

    $Data = $decryptor.TransformFinalBlock($Enc, 0, $Enc.Length)

    if ([string]::IsNullOrEmpty($OutputFileName)) {
        $Data = [System.Text.Encoding]::UTF8.GetString($Data)
        $Data
    }
    else {
        [System.IO.File]::WriteAllBytes($OutputFileName, $Data)
    }
}
