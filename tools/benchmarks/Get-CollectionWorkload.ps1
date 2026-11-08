# Experimental only; not reference material for creating production PSU resources.
# Owner authorized generic collections for these benchmark comparisons.
# Each loop has its own small scriptblock so the surrounding case dispatcher does not
# determine whether PowerShell can optimize its loop. Return one container object.
@{
    'hashtable-difference' = { param($Count, $Left, $Right)
        $lookup = @{}
        foreach ($item in $Right) { $lookup[$item] = $true }
        $items = @(foreach ($item in $Left) { if (!$lookup.ContainsKey($item)) { $item } })
        @{ Items = $items }
    }
    'hashset-difference' = { param($Count, $Left, $Right)
        $set = [System.Collections.Generic.HashSet[int]]::new([int[]]$Left)
        $set.ExceptWith([int[]]$Right)
        @{ Items = @($set) }
    }
    'array-add' = { param($Count)
        $items = @()
        for ($i = 0; $i -lt $Count; $i++) { $items += $i }
        @{ Items = $items }
    }
    'array-capture' = { param($Count)
        $items = @(for ($i = 0; $i -lt $Count; $i++) { $i })
        @{ Items = $items }
    }
    'list' = { param($Count)
        $items = [System.Collections.Generic.List[int]]::new()
        for ($i = 0; $i -lt $Count; $i++) { $items.Add($i) }
        @{ Items = $items }
    }
    'hashtable' = { param($Count)
        $items = @{}
        for ($i = 0; $i -lt $Count; $i++) { $items["key$i"] = $i }
        for ($i = 0; $i -lt $Count; $i++) { $null = $items["KEY$i"] }
        @{ Items = $items }
    }
    'dictionary' = { param($Count)
        $items = [System.Collections.Generic.Dictionary[string,int]]::new([StringComparer]::OrdinalIgnoreCase)
        for ($i = 0; $i -lt $Count; $i++) { $items["key$i"] = $i }
        for ($i = 0; $i -lt $Count; $i++) { $null = $items["KEY$i"] }
        @{ Items = $items }
    }
    'array-membership' = { param($Count)
        $items = @(0..($Count - 1)); $hits = 0
        for ($i = 0; $i -lt $Count; $i++) { if ($items -contains $i) { $hits++ } }
        @{ Items = $items; Hits = $hits }
    }
    'hashtable-membership' = { param($Count)
        $items = @{}
        for ($i = 0; $i -lt $Count; $i++) { $items[$i] = $true }
        $hits = 0
        for ($i = 0; $i -lt $Count; $i++) { if ($items.ContainsKey($i)) { $hits++ } }
        @{ Items = $items; Hits = $hits }
    }
    'hashset-membership' = { param($Count)
        $items = [System.Collections.Generic.HashSet[int]]::new()
        for ($i = 0; $i -lt $Count; $i++) { $null = $items.Add($i) }
        $hits = 0
        for ($i = 0; $i -lt $Count; $i++) { if ($items.Contains($i)) { $hits++ } }
        @{ Items = $items; Hits = $hits }
    }
}
