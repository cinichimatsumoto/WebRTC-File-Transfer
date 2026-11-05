@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"
title Deploy Local Drop to GitHub Pages

rem ---------------------------------------------------------------
rem  Put this file next to index.html and double-click it.
rem  First run: sets up the repository, pushes, and turns on Pages.
rem  Later runs: just pushes your latest changes.
rem ---------------------------------------------------------------

if not exist index.html (
  echo index.html was not found next to this script.
  goto :fail
)

where git >nul 2>nul
if errorlevel 1 (
  echo Git is not installed. Install it from https://git-scm.com/download/win and run this again.
  goto :fail
)

rem GitHub CLI is optional. If it is installed and signed in, everything is automatic.
set "HASGH=0"
where gh >nul 2>nul && gh auth status >nul 2>nul && set "HASGH=1"

if not exist .git (
  git init >nul
  git symbolic-ref HEAD refs/heads/main
)

git config user.name >nul 2>nul
if errorlevel 1 (
  set /p "GN=Your name for commits: "
  git config user.name "!GN!"
)
git config user.email >nul 2>nul
if errorlevel 1 (
  set /p "GE=Your email for commits: "
  git config user.email "!GE!"
)

git remote get-url origin >nul 2>nul
if errorlevel 1 (
  if "!HASGH!"=="1" (
    set "RN=local-drop"
    set /p "RN=New repository name, press Enter for local-drop: "
    gh repo create "!RN!" --public --source=. --remote=origin
    if errorlevel 1 goto :fail
  ) else (
    echo.
    echo Create an EMPTY public repository at https://github.com/new
    echo Do not add a README. Then paste its URL here.
    set /p "RU=Repository URL: "
    if "!RU!"=="" goto :fail
    git remote add origin "!RU!"
  )
)

git add -A
git diff --cached --quiet
if errorlevel 1 git commit -m "Update Local Drop" >nul

git push -u origin main
if errorlevel 1 (
  echo.
  echo Push failed. If a sign-in window appeared, finish signing in and run this again.
  echo If the repository was not empty, create a new empty one or merge it first.
  goto :fail
)

rem Work out owner and repository name from the remote URL
for /f "delims=" %%u in ('git remote get-url origin') do set "RURL=%%u"
if "!RURL:~-4!"==".git" set "RURL=!RURL:~0,-4!"
set "RURL=!RURL:https://github.com/=!"
set "RURL=!RURL:git@github.com:=!"
for /f "tokens=1,2 delims=/" %%a in ("!RURL!") do (
  set "OWNER=%%a"
  set "REPO=%%b"
)
set "SITE=https://!OWNER!.github.io/!REPO!/"

echo.
if "!HASGH!"=="1" (
  gh api -X POST "repos/!OWNER!/!REPO!/pages" -f "source[branch]=main" -f "source[path]=/" >nul 2>nul
  echo GitHub Pages is on. The first publish can take a minute or two.
  echo Your page: !SITE!
  start "" "!SITE!"
) else (
  echo Uploaded. One manual step is left, only needed the first time:
  echo   Settings, then Pages, then Deploy from a branch, main, / root, Save.
  echo After that your page will be at: !SITE!
  start "" "https://github.com/!OWNER!/!REPO!/settings/pages"
)

echo.
pause
exit /b 0

:fail
echo.
pause
exit /b 1
