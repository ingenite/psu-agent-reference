function Resolve-ParIntuneDeviceCmdbAsset {
    <#
    .SYNOPSIS
    Finds candidate CMDB assets for each supplied Intune device by serial number.
    .DESCRIPTION
    Transforms supplied source objects without retrieval, source mutation, or
    external requests. Compares SerialNumber on both sources after Trim(), using
    PowerShell's case-insensitive equality (-ieq). Internal whitespace, punctuation,
    and leading zeroes remain significant. No placeholder values are inferred.

    Null, empty, or whitespace-only serials never match, including each other.
    A device with a blank serial produces Missing with reason BlankSerialNumber.
    Otherwise zero matching CMDB records produces Missing/NoMatchingSerialNumber,
    one produces Unique/OneMatchingCmdbRecord, and more than one produces
    Ambiguous/MultipleMatchingCmdbRecords. Counts refer to supplied records:
    duplicate CMDB rows or IDs are not deduplicated and remain ambiguous.

    Emits one result per non-null Intune input in source order, preserving IDs and
    repeated records. Each device is evaluated independently against all assets;
    multiple Intune records may have the same unique candidate. Serial numbers
    never replace source identifiers or establish a one-to-one relationship.
    Unique means one candidate in the supplied CMDB dataset, not proof that the
    records identify the same physical device. Candidates are not consumed or
    reserved by earlier results.
    Device names, asset tags, OS, timestamps, and user associations do not affect
    matching. No candidate is silently selected when the outcome is ambiguous.
    .PARAMETER InputObject
    Intune source objects exposing Id and SerialNumber, as returned by
    Get-ParIntuneDevice. Accepts an array or pipeline input. Null elements are
    ignored; null input, empty arrays, and empty pipelines emit no results.
    .PARAMETER CmdbAsset
    CMDB source objects exposing assetId and serialNumber, as returned by
    Get-ParCmdbAsset. Supply the complete candidate dataset as an array. Null
    elements are ignored; null or empty input gives every device zero candidates.
    Non-null objects on both sides must follow their source contracts; incomplete
    models are not repaired. Equivalent objects allow isolated tests without Graph.
    .INPUTS
    System.Object[]

    Intune source objects, individually or as an array.
    .OUTPUTS
    System.Management.Automation.PSCustomObject

    IntuneDeviceId: original Intune record Id.
    IntuneDevice: original source object, retaining its identifiers and evidence.
    SerialNumber: original Intune serial, preserving null, empty, and whitespace.
    ComparisonSerialNumber: trimmed Intune serial; empty for a blank serial.
    Outcome: Unique, Missing, or Ambiguous, based on CMDB candidate count.
    Reason: BlankSerialNumber, NoMatchingSerialNumber, OneMatchingCmdbRecord,
    or MultipleMatchingCmdbRecords, as described above.
    CandidateCount: number of matching CMDB records.
    CmdbCandidates: always an array, containing every matching original CMDB
    source object in supplied order, including assetId and original serialNumber.
    Source objects are references, not copies. This command leaves them unchanged;
    consumers must not mutate them through the result if retaining source values.
    .EXAMPLE
    $devices | Resolve-ParIntuneDeviceCmdbAsset -CmdbAsset $assets
    .EXAMPLE
    Resolve-ParIntuneDeviceCmdbAsset -InputObject $devices -CmdbAsset $assets
    .EXAMPLE
    Import-Module ./modules/ParData/ParData.psd1
    Import-Module ./modules/ParReports/ParReports.psd1
    $devices = @(Get-ParIntuneDevice)
    $assets = @(Get-ParCmdbAsset)
    $results = @($devices | Resolve-ParIntuneDeviceCmdbAsset -CmdbAsset $assets)
    $results | Select-Object IntuneDeviceId, SerialNumber, Outcome, Reason, CandidateCount
    $results | Where-Object Outcome -eq 'Ambiguous' | ForEach-Object { $_.CmdbCandidates }

    From the repository root, the default offline fixtures produce Unique for
    SYNTH-COMPARE-MATCH (COMPARE-ASSET-001), Missing for SYNTH-COMPARE-NO-ASSET,
    and Ambiguous for SYNTH-COMPARE-DUPLICATE-ASSET (COMPARE-ASSET-007A and
    COMPARE-ASSET-007B), among the eleven device records.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]] $InputObject,

        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object[]] $CmdbAsset
    )

    begin {
        $comparableAssets = @(
            foreach ($asset in $CmdbAsset) {
                if ($null -eq $asset) {
                    continue
                }

                $serial = ([string] $asset.serialNumber).Trim()
                if ($serial -ne '') {
                    [pscustomobject]@{
                        Asset = $asset
                        SerialNumber = $serial
                    }
                }
            }
        )
    }

    process {
        foreach ($device in $InputObject) {
            if ($null -eq $device) {
                continue
            }

            $serial = ([string] $device.SerialNumber).Trim()
            $candidates = @(
                if ($serial -ne '') {
                    foreach ($comparableAsset in $comparableAssets) {
                        if ($serial -ieq $comparableAsset.SerialNumber) {
                            $comparableAsset.Asset
                        }
                    }
                }
            )

            $outcome = 'Missing'
            $reason = 'NoMatchingSerialNumber'
            if ($serial -eq '') {
                $reason = 'BlankSerialNumber'
            }
            elseif ($candidates.Count -eq 1) {
                $outcome = 'Unique'
                $reason = 'OneMatchingCmdbRecord'
            }
            elseif ($candidates.Count -gt 1) {
                $outcome = 'Ambiguous'
                $reason = 'MultipleMatchingCmdbRecords'
            }

            [pscustomobject][ordered]@{
                IntuneDeviceId = $device.Id
                IntuneDevice = $device
                SerialNumber = $device.SerialNumber
                ComparisonSerialNumber = $serial
                Outcome = $outcome
                Reason = $reason
                CandidateCount = $candidates.Count
                CmdbCandidates = $candidates
            }
        }
    }
}
