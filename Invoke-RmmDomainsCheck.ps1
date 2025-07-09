function Invoke-RmmDomainsCheck {
    param (
        [Parameter(Mandatory = $false)]
        [string]$InputFile = "rmm_domains.csv",

        [Parameter(Mandatory = $false)]
        [string]$OutputFile = "report.csv",

        [Parameter(Mandatory = $false)]
        [int]$TimeoutMs = 2000
    )

    function Load-DomainsFromCsv {
        param (
            [string]$FilePath
        )
        if (-not (Test-Path $FilePath)) {
            throw "CSV file not found: $FilePath"
        }
        try {
            $data = Import-Csv -Path $FilePath
            if (-not $data) {
                throw "CSV file is empty or invalid: $FilePath"
            }
            return $data
        } catch {
            throw "Failed to import CSV: $_"
        }
    }

    function Test-DomainAccessibility {
        param (
            [string]$Domain,
            [int]$TimeoutMs
        )
        try {
            $url = if ($Domain -match '^https?://') { $Domain } else { "https://$Domain" }
            $request = [System.Net.WebRequest]::Create($url)
            $request.Timeout = $TimeoutMs
            $null = $request.GetResponse()
            return $true
        } catch {
            Write-Verbose "Error accessing $Domain"
            return $false
        }
    }

    try {
        $domains = Load-DomainsFromCsv -FilePath $InputFile
    } catch {
        Write-Error $_
        return
    }

    if (-not $domains -or $domains.Count -eq 0) {
        Write-Error "No domains found in the input file."
        return
    }

    $results = @()

    foreach ($entry in $domains) {
        $domain = $entry.Domain
        $tool = $entry.Tool
        if (-not $domain) {
            Write-Verbose "Skipping an entry with missing domain."
            continue
        }
        $isAccessible = Test-DomainAccessibility -Domain $domain -TimeoutMs $TimeoutMs
        $status = if ($isAccessible) { "Accessible" } else { "Not Accessible" }

        Write-Verbose "Checking domain: $domain ($tool) - Status: $status"

        $results += [PSCustomObject]@{
            Tool   = $tool
            Domain = $domain
            Status = $status
        }
    }

    try {
        $results | Export-Csv -Path $OutputFile -NoTypeInformation -Force
        Write-Host "Report generated: $OutputFile"
    } catch {
        throw "Failed to write report: $($_.Exception.Message)"
    }
}
