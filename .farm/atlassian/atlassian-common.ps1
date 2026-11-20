# Wspólne funkcje farmy dla Atlassian (Jira, Confluence).
# Tokeny Farm Bota leżą w Menedżerze poświadczeń Windows (poświadczenia ogólne),
# nigdy w repo, logach ani zmiennych środowiskowych zapisywanych na dysk.
#   tamitu-farm-jira        token do Jiry (task.ps1, orkiestrator)
#   tamitu-farm-confluence  token do Confluence (przekazania agentów; w CI osobny sekret)

$AtlassianSite  = 'https://tadecode.atlassian.net'
$AtlassianEmail = 'farm-bot@tadecode.pl'
$AtlassianCredTargets = @{
    jira       = 'tamitu-farm-jira'
    confluence = 'tamitu-farm-confluence'
}

if (-not ('FarmCred' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public static class FarmCred {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct CREDENTIAL {
        public int Flags; public int Type; public string TargetName; public string Comment;
        public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
        public int CredentialBlobSize; public IntPtr CredentialBlob; public int Persist;
        public int AttributeCount; public IntPtr Attributes; public string TargetAlias; public string UserName;
    }
    [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredWrite(ref CREDENTIAL c, int flags);
    [DllImport("advapi32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern bool CredRead(string target, int type, int flags, out IntPtr c);
    [DllImport("advapi32.dll", SetLastError = true)]
    private static extern bool CredDelete(string target, int type, int flags);
    [DllImport("advapi32.dll")]
    private static extern void CredFree(IntPtr p);
    private const int GENERIC = 1, LOCAL_MACHINE = 2;

    public static void Write(string target, string user, string secret) {
        byte[] blob = Encoding.Unicode.GetBytes(secret);
        IntPtr p = Marshal.AllocCoTaskMem(blob.Length);
        try {
            Marshal.Copy(blob, 0, p, blob.Length);
            var c = new CREDENTIAL { Type = GENERIC, TargetName = target, UserName = user,
                CredentialBlobSize = blob.Length, CredentialBlob = p, Persist = LOCAL_MACHINE };
            if (!CredWrite(ref c, 0)) throw new System.ComponentModel.Win32Exception(Marshal.GetLastWin32Error());
        } finally { Array.Clear(blob, 0, blob.Length); Marshal.FreeCoTaskMem(p); }
    }
    public static string Read(string target) {
        IntPtr p;
        if (!CredRead(target, GENERIC, 0, out p)) return null;
        try {
            var c = (CREDENTIAL)Marshal.PtrToStructure(p, typeof(CREDENTIAL));
            return Marshal.PtrToStringUni(c.CredentialBlob, c.CredentialBlobSize / 2);
        } finally { CredFree(p); }
    }
    public static bool Delete(string target) { return CredDelete(target, GENERIC, 0); }
}
'@
}

function Get-AtlassianToken([ValidateSet('jira', 'confluence')][string]$App) {
    $t = [FarmCred]::Read($AtlassianCredTargets[$App])
    if (-not $t) { throw "Brak tokena '$($AtlassianCredTargets[$App])'. Uruchom: .farm/atlassian/set-token.ps1 $App" }
    $t
}

function Get-AtlassianAuthHeader([string]$Token) {
    'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${AtlassianEmail}:$Token"))
}

# Sprawdza token: zwraca nazwę konta, w którego imieniu działa, albo rzuca wyjątek.
function Test-AtlassianToken([ValidateSet('jira', 'confluence')][string]$App, [string]$Token) {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $uri = if ($App -eq 'jira') { "$AtlassianSite/rest/api/3/myself" } else { "$AtlassianSite/wiki/rest/api/user/current" }
    $r = Invoke-RestMethod -Uri $uri -Headers @{ Authorization = (Get-AtlassianAuthHeader $Token); Accept = 'application/json' } -Method Get
    if ($r.displayName) { $r.displayName } elseif ($r.publicName) { $r.publicName } else { $r.accountId }
}
