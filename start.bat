@echo off
chcp 65001 >nul 2>&1
title Style AI Server Launcher
cd /d "%~dp0"

echo.
echo ============================================
echo   Style AI 启动脚本
echo ============================================
echo.

REM ===== 步骤 0/4: 查找 Node.js =====
echo [步骤 0/4] 查找 Node.js...

set "NODE_EXE="

REM 候选路径（优先 v20，匹配 better-sqlite3 预编译二进制）
if exist "D:\code tools\node\node.exe" (
    set "NODE_EXE=D:\code tools\node\node.exe"
    goto :found_node
)
if exist "C:\Program Files\nodejs\node.exe" (
    set "NODE_EXE=C:\Program Files\nodejs\node.exe"
    goto :found_node
)
if exist "C:\Program Files (x86)\nodejs\node.exe" (
    set "NODE_EXE=C:\Program Files (x86)\nodejs\node.exe"
    goto :found_node
)
if exist "%LOCALAPPDATA%\Programs\nodejs\node.exe" (
    set "NODE_EXE=%LOCALAPPDATA%\Programs\nodejs\node.exe"
    goto :found_node
)
if exist "C:\nodejs\node.exe" (
    set "NODE_EXE=C:\nodejs\node.exe"
    goto :found_node
)

echo [错误] 未找到 Node.js，请安装 Node.js v20+
echo   下载地址: https://nodejs.org/
pause
exit /b 1

:found_node
echo   Node.js: %NODE_EXE%
"%NODE_EXE%" -e "console.log('  版本: ' + process.version)"
echo.

REM ===== 步骤 1/4: 环境检查 =====
echo [步骤 1/4] 环境检查...

if not exist "backend-node\node_modules" (
    echo [错误] backend-node\node_modules 不存在
    echo   请先运行: cd backend-node ^&^& npm install
    pause
    exit /b 1
)
if not exist "app\node_modules" (
    echo [错误] app\node_modules 不存在
    echo   请先运行: cd app ^&^& npm install
    pause
    exit /b 1
)
echo   环境检查通过
echo.

REM ===== 步骤 2/4: 清理端口 5000 =====
echo [步骤 2/4] 清理端口 5000...

for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":5000" ^| findstr "LISTENING"') do (
    echo   终止占用进程 PID=%%a
    taskkill /F /PID %%a >nul 2>&1
)
timeout /t 2 /nobreak >nul 2>&1
echo   端口已清理
echo.

REM ===== 步骤 3/4: 构建前端 =====
echo [步骤 3/4] 构建前端 (esbuild)...

cd /d "%~dp0app"
"%NODE_EXE%" --require "%~dp0npm-patch.js" build-esbuild.cjs
if %errorlevel% neq 0 (
    echo.
    echo [错误] 前端构建失败
    cd /d "%~dp0"
    pause
    exit /b 1
)
echo   前端构建成功
echo.

REM ===== 步骤 4/4: 启动后端 =====
echo [步骤 4/4] 启动后端服务 (端口 5000)...
echo.
echo ============================================
echo   服务地址:   http://127.0.0.1:5000
echo   健康检查:   http://127.0.0.1:5000/api/health
echo   管理后台:   http://127.0.0.1:5000/admin/login
echo   3D展厅:     http://127.0.0.1:5000/gallery
echo ============================================
echo   按 Ctrl+C 停止服务
echo.

REM 5秒后自动打开浏览器
start "" cmd /c "timeout /t 5 /nobreak >nul 2>&1 && start http://127.0.0.1:5000"

cd /d "%~dp0backend-node"
"%NODE_EXE%" --require "%~dp0npm-patch.js" server.js

echo.
echo 服务已停止
cd /d "%~dp0"
pause
