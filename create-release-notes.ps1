<#
.SYNOPSIS
    Generates a project change log file.
.LINK
    Script posted over:
    http://open.bekk.no/generating-a-project-change-log-with-teamcity-and-powershell
#>

# username/password to access Teamcity REST API
$acctname = "%system.teamcity.auth.userId%";
$password = "%system.teamcity.auth.password%";
$header = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($acctname):$($password)"))};
		
# Where the changelog file will be created
$outputFile = "%system.teamcity.build.tempDir%\ReleaseNotes.txt"

# the url of teamcity server
$teamcityUrl = "%teamcity.serverUrl%"

# Build id for the release notes
$buildId = %teamcity.build.id%


$buildChangesUrl = $teamCityUrl + "/httpAuth/app/rest/changes?build=id:" + $buildId
$buildChangesResponse = Invoke-WebRequest $buildChangesUrl -Headers $header | select -ExpandProperty Content
$changesList = ([Xml]$buildChangesResponse).GetElementsByTagName("change")

# Get the commit messages for the specified change id
# Ignore messages containing #ignore
# Ignore empty lines
$stream = [System.IO.StreamWriter] "$outputFile"
Foreach ($buildChange in $changesList)
{    
	$stream.WriteLine("<ul>")
	
    $changeUrl = $teamCityUrl  + $buildChange.href
    $changeResponse = Invoke-WebRequest $changeUrl -Headers $header | select -ExpandProperty Content
    $change = ([Xml]$changeResponse).GetElementsByTagName("change")
    $version = $change.version
    $user =$change.username
    $comment = $change.GetElementsByTagName("comment").InnerXml
	
	$stream.WriteLine("<li>")
	
	$stream.WriteLine("<strong>")
    $stream.WriteLine("Commit #" +$version + " :: " + $user)
	$stream.WriteLine("</strong>")
	
	$stream.WriteLine("<em>")
    $stream.WriteLine("Comment:" + $comment)
	$stream.WriteLine("</em>")
	
	$stream.WriteLine("</li>")
	
	Write-Host "Commit #" +$version + " :: " + $user + " :: " + $comment
	
    $stream.WriteLine("<h5>Files:</h5>")
    $files = $change.GetElementsByTagName("file")
	$stream.WriteLine("<ol>")
    Foreach ($file in $files)
    {
		$stream.WriteLine("<li>")
        $stream.WriteLine($file.file)
		$stream.WriteLine("</li>")
    }
	$stream.WriteLine("</ol>")
    $stream.WriteLine("")
	
	$stream.WriteLine("</ul>")
}
$stream.Flush()
$stream.close()

Write-Host "Changelog saved to ${outputFile}"
