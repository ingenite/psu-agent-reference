Describe 'Temporary CI failure-path verification' {
    It 'intentionally fails to verify the required merge check' {
        $true | Should -BeFalse
    }
}
