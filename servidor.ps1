# Servidor local minimo para abrir index.html por http:// (necesario para que YouTube funcione).
# Uso: clic derecho > "Ejecutar con PowerShell", o desde una terminal:
#   powershell -ExecutionPolicy Bypass -File servidor.ps1

$puerto = 8000
$carpeta = $PSScriptRoot

$tipos = @{
  '.html'='text/html'; '.htm'='text/html'; '.js'='application/javascript'
  '.css'='text/css'; '.json'='application/json'; '.png'='image/png'
  '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.svg'='image/svg+xml'
  '.ico'='image/x-icon'; '.mp4'='video/mp4'; '.webm'='video/webm'
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$puerto/")
try {
    $listener.Start()
} catch {
    Write-Host "No se pudo abrir el puerto $puerto (¿ya hay un servidor corriendo? ciérralo o cambia `$puerto en este script)." -ForegroundColor Red
    exit 1
}

Write-Host "Servidor arrancado." -ForegroundColor Green
Write-Host "Abre en tu navegador:  http://localhost:$puerto/index.html" -ForegroundColor Cyan
Write-Host "Deja esta ventana abierta mientras uses la app. Ctrl+C para parar." -ForegroundColor DarkGray

Start-Process "http://localhost:$puerto/index.html"

while ($listener.IsListening) {
    $contexto = $listener.GetContext()
    $peticion = $contexto.Request
    $respuesta = $contexto.Response
    try {
        $ruta = [System.Uri]::UnescapeDataString($peticion.Url.LocalPath)
        if ($ruta -eq '/') { $ruta = '/index.html' }
        $archivo = Join-Path $carpeta ($ruta.TrimStart('/'))

        if (Test-Path $archivo -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($archivo).ToLower()
            $tipo = $tipos[$ext]
            if (-not $tipo) { $tipo = 'application/octet-stream' }
            $bytes = [System.IO.File]::ReadAllBytes($archivo)
            $respuesta.ContentType = $tipo
            $respuesta.ContentLength64 = $bytes.Length
            $respuesta.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $respuesta.StatusCode = 404
            $mensaje = [System.Text.Encoding]::UTF8.GetBytes("404 - No encontrado: $ruta")
            $respuesta.OutputStream.Write($mensaje, 0, $mensaje.Length)
        }
    } catch {
        $respuesta.StatusCode = 500
    } finally {
        $respuesta.OutputStream.Close()
    }
}
