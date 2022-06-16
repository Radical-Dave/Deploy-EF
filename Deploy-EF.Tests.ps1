Describe 'Deploy-EF.Tests' {
    It 'passes empty' {
        .\Deploy-EF.ps1 | Should -BeNullOrEmpty
        $? | Should -BeLike '*error*'
    }
    It 'passes junk' {
        $results = .\Deploy-EF.ps1 junk | Should -BeNullOrEmpty
        $results | Should -BeLike '*error*'
        $? | Should -Be $true
    }
    It 'passes junk' {
        $results = .\Deploy-EF $MyInvocation.MyCommand.Parameters $PSBoundParameters "$PSScriptName started" -Show -Stamp -StartWatch
        $results | Should -Not -BeLike '*error*'
        $? | Should -Be $true
        Write-Host "results:$results"
    }
    It 'passes array' {
        $testparams = @(@{'smoke'='test'})
        $results = .\Deploy-EF @testparams $PSBoundParameters "$PSScriptName started" -Show -Stamp -StartWatch
        $results | Should -Not -BeLike '*error*'
        $? | Should -Be $true
        Write-Host "results:$results"
    }
    It 'passes verbose' {
        $testparams = @(@{'smoke'='test'})
        $results = .\Deploy-EF @testparams $PSBoundParameters "$PSScriptName started" -Show -Stamp -StartWatch -Verbose
        $results | Should -Not -BeLike '*error*'
        $? | Should -Be $true
        Write-Host "results:$($results | out-string -stream)"
    }
}