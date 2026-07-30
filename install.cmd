@echo off
rem Bootstrapper for the cross-platform Node installer (Windows).
rem All real work lives in install.mjs - this just locates Node and runs it.
rem
rem This is a batch file rather than PowerShell on purpose: .ps1 scripts are
rem refused outright under the default Restricted ExecutionPolicy on Windows
rem client installs, and a .ps1 downloaded from GitHub carries Mark-of-the-Web
rem so even RemoteSigned rejects it until it is unblocked. Batch has no such
rem gate. `node install.mjs` works from any shell too, if you prefer.
setlocal
cd /d "%~dp0"
where node >nul 2>nul
if errorlevel 1 (
  echo Node.js ^(^>=18^) is required to run the installer. 1>&2
  echo Install it from https://nodejs.org/ and re-run install.cmd 1>&2
  exit /b 1
)
node install.mjs %*
exit /b %ERRORLEVEL%
