param(
 [string]$PgBin = 'C:\Program Files\PostgreSQL\18\bin',
 [string]$Java = 'C:\Program Files\Java\jdk-18.0.1.1\bin\java.exe'
)
$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$backendJar = [System.IO.Path]::GetFullPath((Join-Path $projectRoot '..\..\procesos\target\procesos-0.0.1-SNAPSHOT.jar'))
if (-not (Test-Path -LiteralPath $backendJar)) { throw 'Primero compilar el backend con mvnw.cmd package' }
$runRoot = Join-Path $projectRoot ('build\backend-smoke\' + [Guid]::NewGuid().ToString('N'))
$cluster = Join-Path $runRoot 'postgres'
[System.IO.Directory]::CreateDirectory($runRoot) | Out-Null
$backend = $null
$previous = @{}
foreach ($key in @('DB_URL','DB_USERNAME','DB_PASSWORD','ADMIN_USERNAME','ADMIN_PASSWORD','APP_MEDIA_DIR','CORS_ORIGINS')) {
 $previous[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
}
try {
 & (Join-Path $PgBin 'initdb.exe') -D $cluster -U fluttertest -A trust --encoding=UTF8 --locale=C
 if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear PostgreSQL temporal' }
 $pgArgs = @('-D', ('"' + $cluster + '"'), '-l', ('"' + $runRoot + '\postgres.log"'), '-o', '"-h 127.0.0.1 -p 55449"', '-w', 'start')
 $starter = Start-Process -FilePath (Join-Path $PgBin 'pg_ctl.exe') -ArgumentList $pgArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runRoot 'pg-start.out') -RedirectStandardError (Join-Path $runRoot 'pg-start.err')
 if (-not $starter.WaitForExit(30000) -or -not (Test-Path -LiteralPath (Join-Path $cluster 'postmaster.pid'))) {
  throw 'No se pudo iniciar PostgreSQL temporal'
 }
 $env:DB_URL = 'jdbc:postgresql://127.0.0.1:55449/postgres'
 $env:DB_USERNAME = 'fluttertest'
 $env:DB_PASSWORD = 'fluttertest'
 $env:ADMIN_USERNAME = 'smokeadmin'
 $env:ADMIN_PASSWORD = 'Smoke-backend-2026!'
 $env:APP_MEDIA_DIR = Join-Path $runRoot 'media'
 $env:CORS_ORIGINS = 'http://localhost:5173'
 $backend = Start-Process -FilePath $Java -ArgumentList @('-jar', ('"' + $backendJar + '"'), '--server.port=18080') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runRoot 'backend.out') -RedirectStandardError (Join-Path $runRoot 'backend.err')
 $null = $backend.Handle
 $ready = $false
 for ($attempt = 0; $attempt -lt 80; $attempt++) {
  if ($backend.HasExited) { throw ('El backend no inicio; ver ' + $runRoot) }
  try {
   $response = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:18080/api/catalogo/celulares?size=1' -TimeoutSec 1
   if ($response.StatusCode -eq 200) { $ready = $true; break }
  } catch { Start-Sleep -Milliseconds 250 }
 }
 if (-not $ready) { throw 'El backend temporal no estuvo listo a tiempo' }
 Push-Location $projectRoot
 try {
  & flutter test test/backend_smoke_test.dart --dart-define=RUN_BACKEND_SMOKE=true
  if ($LASTEXITCODE -ne 0) { throw 'Fallo la integracion Flutter + Spring Boot' }
 } finally { Pop-Location }
} finally {
 if ($null -ne $backend -and -not $backend.HasExited) {
  Stop-Process -Id $backend.Id
  $null = $backend.WaitForExit(10000)
 }
 if (Test-Path -LiteralPath (Join-Path $cluster 'postmaster.pid')) {
  & (Join-Path $PgBin 'pg_ctl.exe') -D $cluster -m fast -w stop
 }
 foreach ($key in $previous.Keys) { [Environment]::SetEnvironmentVariable($key, $previous[$key], 'Process') }
}