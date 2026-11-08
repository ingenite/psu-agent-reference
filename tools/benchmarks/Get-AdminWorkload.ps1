# Experimental only; not reference material for creating production PSU resources.
# Owner authorized generic collections for these benchmark comparisons.
# Each variant returns one container. Timed report variants all return an object array.
@{
    'report-array-add' = { param($Users, $Keys)
        $rows = @()
        foreach ($user in $Users) {
            $rows += [pscustomobject]@{ Account=$user.SamAccountName; Email=$user.Mail; Department=$user.Department; Enabled=$user.Enabled }
        }
        @{ Rows = $rows }
    }
    'report-array-capture' = { param($Users, $Keys)
        $rows = @(foreach ($user in $Users) {
            [pscustomobject]@{ Account=$user.SamAccountName; Email=$user.Mail; Department=$user.Department; Enabled=$user.Enabled }
        })
        @{ Rows = $rows }
    }
    'report-list' = { param($Users, $Keys)
        $rows = [System.Collections.Generic.List[object]]::new()
        foreach ($user in $Users) {
            $rows.Add([pscustomobject]@{ Account=$user.SamAccountName; Email=$user.Mail; Department=$user.Department; Enabled=$user.Enabled })
        }
        @{ Rows = $rows.ToArray() }
    }
    'lookup-where' = { param($Users, $Keys)
        $rows = @(foreach ($key in $Keys) {
            $user = $Users | Where-Object SamAccountName -EQ $key
            $user.Mail
        })
        @{ Rows = $rows }
    }
    'lookup-foreach' = { param($Users, $Keys)
        $rows = @(foreach ($key in $Keys) {
            foreach ($user in $Users) {
                if ($user.SamAccountName -eq $key) { $user.Mail; break }
            }
        })
        @{ Rows = $rows }
    }
    'lookup-hashtable' = { param($Users, $Keys)
        $index = @{}
        foreach ($user in $Users) { $index[$user.SamAccountName] = $user }
        $rows = @(foreach ($key in $Keys) { $index[$key].Mail })
        @{ Rows = $rows }
    }
    'lookup-dictionary' = { param($Users, $Keys)
        $index = [System.Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($user in $Users) { $index[$user.SamAccountName] = $user }
        $rows = @(foreach ($key in $Keys) { $index[$key].Mail })
        @{ Rows = $rows }
    }
}
