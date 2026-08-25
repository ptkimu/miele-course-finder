$l = New-Object System.Net.HttpListener
$l.Prefixes.Add("http://localhost:8080/")
$l.Start()
$file = "C:\Users\ptkim\salon-match\index.html"
while ($l.IsListening) {
  $ctx = $l.GetContext()
  $bytes = [IO.File]::ReadAllBytes($file)
  $ctx.Response.ContentType = "text/html; charset=utf-8"
  $ctx.Response.Headers.Add("Cache-Control", "no-store")
  $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  $ctx.Response.Close()
}