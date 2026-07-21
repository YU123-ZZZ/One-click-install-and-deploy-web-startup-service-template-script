@echo off
:: 版权所有 (c) 2026
:: 作者: https://github.com/YU123-ZZZ
:: 吾爱破解: https://www.52pojie.cn/home.php?mod=space^&uid=2394304
:: 本脚本仅供学习与合法项目部署使用。
chcp 936 >nul
setlocal EnableExtensions EnableDelayedExpansion
title 一键安装部署启动服务模板 v4.2
mode con cols=92 lines=34 >nul 2>&1
color 07 >nul 2>&1

set "VERSION=4.2"
set "PROJECT_DIR=%~dp0"
set "CONFIG_FILE=%PROJECT_DIR%service.conf"
set "STATE_FILE=%PROJECT_DIR%service.state"

call :restore_defaults

set "CURRENT_PORT="
set "CURRENT_PID="
set "SERVER_RUNNING=0"
set "PORT_USED=0"
set "PORT_PID="
set "LAN_IP=localhost"
set "AUTO_MODE=0"
set "IS_ADMIN=0"

net session >nul 2>&1
if !errorlevel! equ 0 set "IS_ADMIN=1"
if "!IS_ADMIN!"=="0" fltmc >nul 2>&1
if !errorlevel! equ 0 set "IS_ADMIN=1"

if exist "!CONFIG_FILE!" call "!CONFIG_FILE!"
call :load_state
call :get_lan_ip
goto main_menu

:main_menu
cls
echo.
call :color_title
echo   ========================================================================================
call :color_normal
call :color_title
echo                         一键安装部署启动服务模板 v!VERSION!
call :color_normal
call :color_title
echo   ========================================================================================
call :color_normal
echo.
echo     [1] 一键部署启动                 [6] 端口管理
echo     [2] 使用默认端口启动             [7] 环境安装
echo     [3] 使用自定义端口启动           [8] 项目管理
echo     [4] 停止服务                     [9] 系统信息
echo     [5] 重启服务                     [0] 退出脚本
echo.
call :color_title
echo   ========================================================================================
call :color_normal
echo.
call :show_status
echo.
if "!IS_ADMIN!"=="0" (
    echo   权限状态: 普通权限
    echo   提示: 安装环境和修改防火墙时, 请右键 CMD 选择"以管理员身份运行"。
) else (
    echo   权限状态: 管理员
)
echo.
set "choice="
set /p "choice=请输入菜单编号: "
if "!choice!"=="1" goto deploy
if "!choice!"=="2" goto start_default
if "!choice!"=="3" goto start_custom
if "!choice!"=="4" goto stop_menu
if "!choice!"=="5" goto restart_menu
if "!choice!"=="6" goto port_menu
if "!choice!"=="7" goto env_menu
if "!choice!"=="8" goto project_menu
if "!choice!"=="9" goto system_info
if "!choice!"=="0" goto exit_script
goto main_menu

:deploy
cls
echo.
call :color_title
echo   === 一键部署启动 ===
call :color_normal
echo.
set "AUTO_MODE=1"
echo   [1/5] 正在检查运行环境...
call :check_environment
if "!ENV_OK!"=="0" (
    echo   当前环境不完整。
    set "install_now="
    set /p "install_now=是否立即安装缺少的环境? (Y/N): "
    if /i "!install_now!"=="Y" (
        if "!IS_ADMIN!"=="0" (
            echo.
            call :color_error
            echo   [错误] 安装环境需要管理员权限。
            call :color_normal
            echo   请关闭脚本后, 右键 CMD 选择"以管理员身份运行"。
            set "AUTO_MODE=0"
            pause
            goto main_menu
        )
        call :install_required
        call :check_environment
        if "!ENV_OK!"=="0" (
            call :color_error
            echo   [错误] 环境仍不完整, 请手动检查。
            call :color_normal
            set "AUTO_MODE=0"
            pause
            goto main_menu
        )
    ) else (
        set "AUTO_MODE=0"
        goto main_menu
    )
)
call :color_success
echo   [完成] 运行环境已就绪。
call :color_normal
echo.
echo   [2/5] 正在检查项目文件...
if exist "!PROJECT_DIR!!JAR_FILE!" (
    call :color_success
    echo   [存在] !JAR_FILE!
    call :color_normal
) else (
    call :color_warning
    echo   [缺失] !JAR_FILE!
    call :color_normal
    set "continue_missing="
    set /p "continue_missing=程序文件缺失, 是否仍然继续? (Y/N): "
    if /i not "!continue_missing!"=="Y" (
        set "AUTO_MODE=0"
        goto main_menu
    )
)
echo.
echo   [3/5] 正在检查端口...
set "DEPLOY_PORT=!DEFAULT_PORT!"
call :check_port !DEPLOY_PORT!
if "!PORT_USED!"=="1" (
    call :find_free_port !DEPLOY_PORT!
    if "!FREE_PORT!"=="" (
        call :color_error
        echo   [错误] 未找到可用端口。
        call :color_normal
        set "AUTO_MODE=0"
        pause
        goto main_menu
    )
    set "DEPLOY_PORT=!FREE_PORT!"
    call :color_success
    echo   [完成] 默认端口已占用, 自动切换到 !DEPLOY_PORT!。
    call :color_normal
) else (
    call :color_success
    echo   [完成] 默认端口 !DEPLOY_PORT! 可以使用。
    call :color_normal
)
echo.
echo   [4/5] 正在启动服务...
call :start_service !DEPLOY_PORT!
if "!SERVER_RUNNING!"=="0" (
    set "AUTO_MODE=0"
    pause
    goto main_menu
)
echo.
echo   [5/5] 正在打开浏览器...
start "" "http://localhost:!CURRENT_PORT!"
call :color_success
echo   [完成] 部署启动完成。
call :color_normal
set "AUTO_MODE=0"
pause
goto main_menu

:start_default
cls
call :start_service !DEFAULT_PORT!
pause
goto main_menu

:start_custom
cls
set "custom_port="
set /p "custom_port=请输入端口 (1-65535): "
if "!custom_port!"=="" goto main_menu
call :validate_port "!custom_port!"
if "!PORT_VALID!"=="0" (
    call :color_error
    echo [错误] 端口必须是 1 到 65535 之间的数字。
    call :color_normal
    pause
    goto main_menu
)
call :start_service !PORT_VALUE!
pause
goto main_menu

:stop_menu
cls
call :stop_service
pause
goto main_menu

:restart_menu
cls
call :load_state
if "!SERVER_RUNNING!"=="1" (
    set "RESTART_PORT=!CURRENT_PORT!"
) else (
    set "RESTART_PORT=!DEFAULT_PORT!"
)
call :stop_service_quiet
timeout /t 1 >nul
call :start_service !RESTART_PORT!
pause
goto main_menu

:port_menu
cls
echo.
call :color_title
echo   === 端口管理 ===
call :color_normal
echo.
echo     [1] 查看常用端口状态
echo     [2] 检测指定端口
echo     [3] 结束占用端口的进程
echo     [4] 添加防火墙放行规则
echo     [5] 删除防火墙放行规则
echo     [0] 返回主菜单
echo.
set "port_choice="
set /p "port_choice=请输入菜单编号: "
if "!port_choice!"=="1" goto port_list
if "!port_choice!"=="2" goto port_check
if "!port_choice!"=="3" goto port_kill
if "!port_choice!"=="4" goto firewall_open
if "!port_choice!"=="5" goto firewall_close
if "!port_choice!"=="0" goto main_menu
goto port_menu

:port_list
cls
echo.
echo 常用端口状态:
echo.
for %%p in (80 443 3000 8080 8888) do (
    call :check_port %%p
    if "!PORT_USED!"=="1" (
        echo   端口 %%p: 占用中, PID !PORT_PID!
    ) else (
        echo   端口 %%p: 空闲
    )
)
echo.
pause
goto port_menu

:port_check
cls
set "check_value="
set /p "check_value=请输入要检测的端口: "
call :validate_port "!check_value!"
if "!PORT_VALID!"=="0" (
    call :color_error
    echo [错误] 端口无效。
    call :color_normal
    pause
    goto port_menu
)
call :check_port !PORT_VALUE!
if "!PORT_USED!"=="1" (
    echo 端口 !PORT_VALUE! 已被占用, PID !PORT_PID!。
) else (
    echo 端口 !PORT_VALUE! 可以使用。
)
pause
goto port_menu

:port_kill
cls
set "kill_value="
set /p "kill_value=请输入要释放的端口: "
call :validate_port "!kill_value!"
if "!PORT_VALID!"=="0" (
    call :color_error
    echo [错误] 端口无效。
    call :color_normal
    pause
    goto port_menu
)
call :kill_port !PORT_VALUE!
call :load_state
if "!CURRENT_PORT!"=="!PORT_VALUE!" call :clear_state
pause
goto port_menu

:firewall_open
cls
if "!IS_ADMIN!"=="0" (
    call :color_error
    echo [错误] 修改防火墙需要管理员权限。
    call :color_normal
    echo 请右键 CMD 选择"以管理员身份运行"。
    pause
    goto port_menu
)
set "firewall_port="
set /p "firewall_port=请输入要放行的端口: "
call :validate_port "!firewall_port!"
if "!PORT_VALID!"=="0" (
    call :color_error
    echo [错误] 端口无效。
    call :color_normal
    pause
    goto port_menu
)
netsh advfirewall firewall add rule name="模板服务端口!PORT_VALUE!" dir=in action=allow protocol=TCP localport=!PORT_VALUE! >nul 2>&1
if !errorlevel! equ 0 (
    call :color_success
    echo [完成] 防火墙放行规则已添加。
    call :color_normal
) else (
    call :color_error
    echo [错误] 防火墙规则添加失败。
    call :color_normal
)
pause
goto port_menu

:firewall_close
cls
if "!IS_ADMIN!"=="0" (
    call :color_error
    echo [错误] 修改防火墙需要管理员权限。
    call :color_normal
    echo 请右键 CMD 选择"以管理员身份运行"。
    pause
    goto port_menu
)
set "firewall_port="
set /p "firewall_port=请输入要删除放行规则的端口: "
call :validate_port "!firewall_port!"
if "!PORT_VALID!"=="0" (
    call :color_error
    echo [错误] 端口无效。
    call :color_normal
    pause
    goto port_menu
)
netsh advfirewall firewall delete rule name="模板服务端口!PORT_VALUE!" >nul 2>&1
if !errorlevel! equ 0 (
    call :color_success
    echo [完成] 防火墙规则已删除。
    call :color_normal
) else (
    call :color_error
    echo [错误] 防火墙规则删除失败或规则不存在。
    call :color_normal
)
pause
goto port_menu

:env_menu
cls
echo.
call :color_title
echo   === 环境安装 ===
call :color_normal
echo.
echo     [1] 检查运行环境
echo     [2] 安装 JDK
echo     [3] 安装 Node.js
echo     [4] 安装 Git
echo     [5] 安装配置中需要的环境
echo     [0] 返回主菜单
echo.
set "env_choice="
set /p "env_choice=请输入菜单编号: "
if "!env_choice!"=="1" goto env_check
if "!env_choice!"=="2" goto env_java
if "!env_choice!"=="3" goto env_node
if "!env_choice!"=="4" goto env_git
if "!env_choice!"=="5" goto env_required
if "!env_choice!"=="0" goto main_menu
goto env_menu

:env_check
cls
call :show_environment
pause
goto env_menu

:env_java
cls
call :require_admin
if "!ADMIN_OK!"=="0" (
    pause
    goto env_menu
)
call :install_java
pause
goto env_menu

:env_node
cls
call :require_admin
if "!ADMIN_OK!"=="0" (
    pause
    goto env_menu
)
call :install_node
pause
goto env_menu

:env_git
cls
call :require_admin
if "!ADMIN_OK!"=="0" (
    pause
    goto env_menu
)
call :install_git
pause
goto env_menu

:env_required
cls
call :require_admin
if "!ADMIN_OK!"=="0" (
    pause
    goto env_menu
)
call :install_required
pause
goto env_menu

:project_menu
cls
echo.
call :color_title
echo   === 项目管理 ===
call :color_normal
echo.
echo     [1] 检查项目文件
echo     [2] 打开项目目录
echo     [3] 查看当前配置
echo     [4] 修改配置
echo     [5] 删除环境配置
echo     [0] 返回主菜单
echo.
set "project_choice="
set /p "project_choice=请输入菜单编号: "
if "!project_choice!"=="1" goto project_check
if "!project_choice!"=="2" goto project_open
if "!project_choice!"=="3" goto project_view
if "!project_choice!"=="4" goto project_modify
if "!project_choice!"=="5" goto project_delete_config
if "!project_choice!"=="0" goto main_menu
goto project_menu

:project_check
cls
echo.
echo 项目文件检查:
echo.
if exist "!PROJECT_DIR!!JAR_FILE!" (
    call :color_success
    echo   [存在] !JAR_FILE!
    call :color_normal
) else (
    call :color_warning
    echo   [缺失] !JAR_FILE!
    call :color_normal
)
if exist "!CONFIG_FILE!" (
    call :color_success
    echo   [存在] service.conf
    call :color_normal
) else (
    call :color_warning
    echo   [未生成] service.conf
    call :color_normal
)
if exist "!STATE_FILE!" (
    call :color_success
    echo   [存在] service.state
    call :color_normal
) else (
    call :color_warning
    echo   [未生成] service.state
    call :color_normal
)
echo.
pause
goto project_menu

:project_open
start "" explorer.exe "!PROJECT_DIR!"
goto project_menu

:project_delete_config
cls
echo.
call :color_title
echo   === 删除环境配置 ===
call :color_normal
echo.
echo   将删除 service.conf，并恢复模板默认参数。
echo   此操作不会停止当前正在运行的服务，也不会删除 service.state。
echo.
set "delete_config_confirm="
set /p "delete_config_confirm=确认删除环境配置? (Y/N): "
if /i not "!delete_config_confirm!"=="Y" (
    call :color_warning
    echo [提示] 已取消删除环境配置。
    call :color_normal
    pause
    goto project_menu
)
if exist "!CONFIG_FILE!" (
    del /q "!CONFIG_FILE!" >nul 2>&1
    if exist "!CONFIG_FILE!" (
        call :color_error
        echo [错误] 无法删除 service.conf。
        call :color_normal
        pause
        goto project_menu
    )
)
call :restore_defaults
call :color_success
echo [完成] 环境配置已删除，模板参数已恢复默认值。
call :color_normal
pause
goto project_menu

:project_view
cls
call :load_state
echo.
call :color_title
echo   === 当前配置 ===
call :color_normal
echo.
echo   项目名称:       !PROJECT_NAME!
echo   项目目录:       !PROJECT_DIR!
echo   默认端口:       !DEFAULT_PORT!
echo   启动命令:       !SERVER_CMD!
echo   命令前参数:     !SERVER_ARGS!
echo   启动附加参数:   !SERVER_EXTRA_ARGS!
echo   程序文件:       !JAR_FILE!
echo   端口参数前缀:   !SERVER_PORT_ARG!
echo   需要 Java:      !NEED_JAVA!
echo   需要 Node.js:   !NEED_NODE!
echo   需要 Git:       !NEED_GIT!
if "!SERVER_RUNNING!"=="1" (
    echo   服务状态:       运行中, 端口 !CURRENT_PORT!
) else (
    echo   服务状态:       未运行
)
echo.
pause
goto project_menu

:project_modify
cls
echo.
call :color_title
echo   === 修改配置 ===
call :color_normal
echo.
echo     [1] 项目名称       [!PROJECT_NAME!]
echo     [2] 默认端口       [!DEFAULT_PORT!]
echo     [3] 启动命令       [!SERVER_CMD!]
echo     [4] 命令前参数     [!SERVER_ARGS!]
echo     [5] 启动附加参数   [!SERVER_EXTRA_ARGS!]
echo     [6] 程序文件       [!JAR_FILE!]
echo     [7] 需要 Java      [!NEED_JAVA!]
echo     [8] 需要 Node.js   [!NEED_NODE!]
    echo     [9] 需要 Git       [!NEED_GIT!]
    echo     [10] 端口参数     [!SERVER_PORT_ARG!]
echo     [S] 保存并返回
echo     [0] 取消并返回
echo.
set "modify_choice="
set /p "modify_choice=请输入要修改的编号: "
if "!modify_choice!"=="1" (
    set "new_value="
    set /p "new_value=请输入项目名称: "
    if not "!new_value!"=="" set "PROJECT_NAME=!new_value!"
    goto project_modify
)
if "!modify_choice!"=="2" (
    set "new_value="
    set /p "new_value=请输入默认端口: "
    call :validate_port "!new_value!"
    if "!PORT_VALID!"=="1" (
        set "DEFAULT_PORT=!PORT_VALUE!"
    ) else (
        call :color_error
        echo [错误] 端口无效。
        call :color_normal
        timeout /t 2 >nul
    )
    goto project_modify
)
if "!modify_choice!"=="3" (
    set "new_value="
    set /p "new_value=请输入启动命令: "
    if not "!new_value!"=="" set "SERVER_CMD=!new_value!"
    goto project_modify
)
if "!modify_choice!"=="4" (
    set "new_value="
    set /p "new_value=请输入命令前参数, 输入减号清空: "
    if "!new_value!"=="-" (
        set "SERVER_ARGS="
    ) else (
        if not "!new_value!"=="" set "SERVER_ARGS=!new_value!"
    )
    goto project_modify
)
if "!modify_choice!"=="5" (
    set "new_value="
    set /p "new_value=请输入启动附加参数, 输入减号清空: "
    if "!new_value!"=="-" (
        set "SERVER_EXTRA_ARGS="
    ) else (
        if not "!new_value!"=="" set "SERVER_EXTRA_ARGS=!new_value!"
    )
    goto project_modify
)
if "!modify_choice!"=="6" (
    set "new_value="
    set /p "new_value=请输入程序文件名: "
    if not "!new_value!"=="" set "JAR_FILE=!new_value!"
    goto project_modify
)
if "!modify_choice!"=="7" (
    set "new_value="
    set /p "new_value=是否需要 Java? 输入 1 或 0: "
    if "!new_value!"=="1" set "NEED_JAVA=1"
    if "!new_value!"=="0" set "NEED_JAVA=0"
    goto project_modify
)
if "!modify_choice!"=="8" (
    set "new_value="
    set /p "new_value=是否需要 Node.js? 输入 1 或 0: "
    if "!new_value!"=="1" set "NEED_NODE=1"
    if "!new_value!"=="0" set "NEED_NODE=0"
    goto project_modify
)
if "!modify_choice!"=="9" (
    set "new_value="
    set /p "new_value=是否需要 Git? 输入 1 或 0: "
    if "!new_value!"=="1" set "NEED_GIT=1"
    if "!new_value!"=="0" set "NEED_GIT=0"
    goto project_modify
)
if "!modify_choice!"=="10" (
    set "new_value="
    set /p "new_value=请输入端口参数前缀, 输入减号清空: "
    if "!new_value!"=="-" (
        set "SERVER_PORT_ARG="
    ) else (
        if not "!new_value!"=="" set "SERVER_PORT_ARG=!new_value!"
    )
    goto project_modify
)
if /i "!modify_choice!"=="S" goto project_save
if "!modify_choice!"=="0" goto project_menu
goto project_modify

:project_save
call :save_config
echo.
call :color_success
echo [完成] 配置已保存到 service.conf。
call :color_normal
call :load_state
if "!SERVER_RUNNING!"=="1" (
    set "apply_now="
    set /p "apply_now=服务正在运行, 是否立即重启应用新配置? (Y/N): "
    if /i "!apply_now!"=="Y" (
        set "APPLY_PORT=!CURRENT_PORT!"
        call :stop_service_quiet
        timeout /t 1 >nul
        call :start_service !APPLY_PORT!
    )
)
pause
goto project_menu

:system_info
cls
call :load_state
call :get_lan_ip
echo.
call :color_title
echo   === 系统信息 ===
call :color_normal
echo.
ver
echo.
echo   项目目录: !PROJECT_DIR!
echo   局域网 IP: !LAN_IP!
echo   管理员权限: !IS_ADMIN!
echo.
call :show_environment
echo.
if "!SERVER_RUNNING!"=="1" (
    call :color_success
    echo   服务状态: 运行中
    call :color_normal
    echo   服务端口: !CURRENT_PORT!
    echo   本机地址: http://localhost:!CURRENT_PORT!
    echo   局域网地址: http://!LAN_IP!:!CURRENT_PORT!
) else (
    call :color_warning
    echo   服务状态: 未运行
    call :color_normal
)
echo.
pause
goto main_menu

:exit_script
call :load_state
if "!SERVER_RUNNING!"=="1" (
    echo.
    echo 服务仍在后台运行, 端口 !CURRENT_PORT!。
    set "exit_stop="
    set /p "exit_stop=是否同时停止服务? 输入 Y 停止, 直接回车保持运行: "
    if /i "!exit_stop!"=="Y" call :stop_service_quiet
)
exit

:show_status
call :load_state
call :get_lan_ip
if "!SERVER_RUNNING!"=="1" (
    call :color_success
    echo   当前状态: 运行中
    call :color_normal
    echo   项目名称: !PROJECT_NAME!
    echo   运行端口: !CURRENT_PORT!
    echo   本机地址: http://localhost:!CURRENT_PORT!
    echo   局域网地址: http://!LAN_IP!:!CURRENT_PORT!
    echo   关闭当前管理窗口后, 服务会继续运行。
) else (
    call :color_warning
    echo   当前状态: 未运行
    call :color_normal
    echo   项目名称: !PROJECT_NAME!
    echo   默认端口: !DEFAULT_PORT!
    echo   项目目录: !PROJECT_DIR!
)
goto :eof

:start_service
call :load_state
if "!SERVER_RUNNING!"=="1" (
    call :color_warning
    echo [提示] 服务已经在运行, 当前端口 !CURRENT_PORT!。
    call :color_normal
    goto :eof
)

set "START_PORT=%~1"
call :validate_port "!START_PORT!"
if "!PORT_VALID!"=="0" (
    call :color_error
    echo [错误] 启动端口无效。
    call :color_normal
    set "SERVER_RUNNING=0"
    goto :eof
)
set "START_PORT=!PORT_VALUE!"

call :check_port !START_PORT!
if "!PORT_USED!"=="1" (
    if "!AUTO_MODE!"=="1" (
        call :find_free_port !START_PORT!
        if "!FREE_PORT!"=="" (
            call :color_error
            echo [错误] 未找到可用端口。
            call :color_normal
            set "SERVER_RUNNING=0"
            goto :eof
        )
        set "START_PORT=!FREE_PORT!"
    ) else (
        echo 端口 !START_PORT! 已被占用, PID !PORT_PID!。
        set "force_kill="
        set /p "force_kill=是否结束占用进程? (Y/N): "
        if /i not "!force_kill!"=="Y" (
            set "SERVER_RUNNING=0"
            goto :eof
        )
        call :kill_port !START_PORT!
        timeout /t 1 >nul
        call :check_port !START_PORT!
        if "!PORT_USED!"=="1" (
            call :color_error
            echo [错误] 端口仍被占用。
            call :color_normal
            set "SERVER_RUNNING=0"
            goto :eof
        )
    )
)

if not exist "!PROJECT_DIR!!JAR_FILE!" (
    call :color_warning
    echo [提示] 未找到程序文件 !JAR_FILE!。
    call :color_normal
    set "start_anyway="
    set /p "start_anyway=是否仍然尝试启动? (Y/N): "
    if /i not "!start_anyway!"=="Y" (
        set "SERVER_RUNNING=0"
        goto :eof
    )
)

echo 正在启动服务, 端口 !START_PORT!...
pushd "!PROJECT_DIR!"
set "PORT_ARGUMENT="
if defined SERVER_PORT_ARG set "PORT_ARGUMENT=!SERVER_PORT_ARG!!START_PORT!"
start "模板服务-!START_PORT!" /min "!SERVER_CMD!" !SERVER_ARGS! "!JAR_FILE!" !SERVER_EXTRA_ARGS! !PORT_ARGUMENT!
popd

set "START_RETRY=0"
:wait_for_start
timeout /t 1 >nul
call :check_port !START_PORT!
if "!PORT_USED!"=="1" (
    set "CURRENT_PORT=!START_PORT!"
    set "CURRENT_PID=!PORT_PID!"
    set "SERVER_RUNNING=1"
    call :save_state
    call :get_lan_ip
    call :color_success
    echo [完成] 服务已启动。
    call :color_normal
    echo 本机地址: http://localhost:!CURRENT_PORT!
    echo 局域网地址: http://!LAN_IP!:!CURRENT_PORT!
    echo 服务在独立的最小化窗口中运行, 关闭管理窗口不会停止服务。
    goto :eof
)
set /a START_RETRY+=1
if !START_RETRY! LSS 15 goto wait_for_start
call :color_error
echo [错误] 启动超时, 未检测到端口监听。
call :color_normal
set "CURRENT_PORT="
set "SERVER_RUNNING=0"
goto :eof

:stop_service
call :stop_service_quiet
goto :eof

:stop_service_quiet
call :load_state
if "!SERVER_RUNNING!"=="0" (
    call :color_warning
    echo [提示] 当前没有运行中的服务。
    call :color_normal
    goto :eof
)
call :check_port !CURRENT_PORT!
if "!PORT_USED!"=="1" if "!PORT_PID!"=="!CURRENT_PID!" (
    taskkill /PID !CURRENT_PID! /T /F >nul 2>&1
)
timeout /t 1 >nul
call :clear_state
call :color_success
echo [完成] 服务已停止。
call :color_normal
goto :eof

:load_state
set "CURRENT_PORT="
set "CURRENT_PID="
set "SERVER_RUNNING=0"
if not exist "!STATE_FILE!" goto :eof
set /p "CURRENT_PORT="<"!STATE_FILE!"
for /f "usebackq skip=1 tokens=1" %%a in ("!STATE_FILE!") do if not defined CURRENT_PID set "CURRENT_PID=%%a"
if "!CURRENT_PORT!"=="" (
    call :clear_state
    goto :eof
)
call :validate_port "!CURRENT_PORT!"
if "!PORT_VALID!"=="0" (
    call :clear_state
    goto :eof
)
if "!CURRENT_PID!"=="" (
    call :clear_state
    goto :eof
)
echo(!CURRENT_PID!| findstr /R "^[0-9][0-9]*$" >nul 2>&1
if !errorlevel! neq 0 (
    call :clear_state
    goto :eof
)
call :check_port !CURRENT_PORT!
if "!PORT_USED!"=="1" (
    if "!PORT_PID!"=="!CURRENT_PID!" (
        set "SERVER_RUNNING=1"
    ) else (
        call :clear_state
    )
) else (
    call :clear_state
)
goto :eof

:save_state
> "!STATE_FILE!" (
    echo !CURRENT_PORT!
    echo !CURRENT_PID!
)
goto :eof

:clear_state
if exist "!STATE_FILE!" del /q "!STATE_FILE!" >nul 2>&1
set "CURRENT_PORT="
set "CURRENT_PID="
set "SERVER_RUNNING=0"
goto :eof

:save_config
(
    echo :: 版权所有 (c) 2026
    echo :: 作者: https://github.com/YU123-ZZZ
    echo :: 吾爱破解: https://www.52pojie.cn/home.php?mod=space^&uid=2394304
    echo.
    echo set "PROJECT_NAME=!PROJECT_NAME!"
    echo set "DEFAULT_PORT=!DEFAULT_PORT!"
    echo set "SERVER_CMD=!SERVER_CMD!"
    echo set "SERVER_ARGS=!SERVER_ARGS!"
    echo set "SERVER_EXTRA_ARGS=!SERVER_EXTRA_ARGS!"
    echo set "JAR_FILE=!JAR_FILE!"
    echo set "SERVER_PORT_ARG=!SERVER_PORT_ARG!"
    echo set "NEED_JAVA=!NEED_JAVA!"
    echo set "NEED_NODE=!NEED_NODE!"
    echo set "NEED_GIT=!NEED_GIT!"
) > "!CONFIG_FILE!"
goto :eof

:validate_port
set "PORT_VALID=0"
set "PORT_VALUE="
set "PORT_TEXT=%~1"
if "!PORT_TEXT!"=="" goto :eof
echo(!PORT_TEXT!| findstr /R "^[0-9][0-9]*$" >nul 2>&1
if !errorlevel! neq 0 goto :eof
set /a PORT_NUMBER=!PORT_TEXT! >nul 2>&1
if !PORT_NUMBER! LSS 1 goto :eof
if !PORT_NUMBER! GTR 65535 goto :eof
set "PORT_VALID=1"
set "PORT_VALUE=!PORT_NUMBER!"
goto :eof

:check_port
set "PORT_USED=0"
set "PORT_PID="
for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr /L ":%~1 " ^| findstr "LISTENING"') do (
    set "PORT_USED=1"
    set "PORT_PID=%%a"
)
goto :eof

:kill_port
call :check_port %~1
if "!PORT_USED!"=="0" (
    call :color_warning
    echo [提示] 端口 %~1 当前未被占用。
    call :color_normal
    goto :eof
)
taskkill /PID !PORT_PID! /T /F >nul 2>&1
if !errorlevel! equ 0 (
    call :color_success
    echo [完成] 已结束 PID !PORT_PID!。
    call :color_normal
) else (
    call :color_error
    echo [错误] 无法结束 PID !PORT_PID!。
    call :color_normal
)
goto :eof

:find_free_port
set "FREE_PORT="
set /a SEARCH_START=%~1
set /a SEARCH_END=SEARCH_START+100
if !SEARCH_END! GTR 65535 set "SEARCH_END=65535"
for /L %%p in (!SEARCH_START!,1,!SEARCH_END!) do (
    if "!FREE_PORT!"=="" (
        call :check_port %%p
        if "!PORT_USED!"=="0" set "FREE_PORT=%%p"
    )
)
goto :eof

:check_environment
set "ENV_OK=1"
if "!NEED_JAVA!"=="1" (
    where java >nul 2>&1
    if !errorlevel! neq 0 set "ENV_OK=0"
)
if "!NEED_NODE!"=="1" (
    where node >nul 2>&1
    if !errorlevel! neq 0 set "ENV_OK=0"
)
if "!NEED_GIT!"=="1" (
    where git >nul 2>&1
    if !errorlevel! neq 0 set "ENV_OK=0"
)
goto :eof

:show_environment
echo   Java / JDK:
where java >nul 2>&1
if !errorlevel! equ 0 (
    java -version 2>&1
) else (
    echo     未安装
)
echo.
echo   Node.js:
where node >nul 2>&1
if !errorlevel! equ 0 (
    node --version
) else (
    echo     未安装
)
echo.
echo   Git:
where git >nul 2>&1
if !errorlevel! equ 0 (
    git --version
) else (
    echo     未安装
)
echo.
echo   winget:
where winget >nul 2>&1
if !errorlevel! equ 0 (
    echo     可用
) else (
    echo     不可用
)
goto :eof

:require_admin
set "ADMIN_OK=1"
if "!IS_ADMIN!"=="0" (
    set "ADMIN_OK=0"
    call :color_error
    echo [错误] 此操作需要管理员权限。
    call :color_normal
    echo 请关闭脚本后, 右键 CMD 选择"以管理员身份运行"。
)
goto :eof

:install_required
if "!NEED_JAVA!"=="1" (
    where java >nul 2>&1
    if !errorlevel! neq 0 call :install_java
)
if "!NEED_NODE!"=="1" (
    where node >nul 2>&1
    if !errorlevel! neq 0 call :install_node
)
if "!NEED_GIT!"=="1" (
    where git >nul 2>&1
    if !errorlevel! neq 0 call :install_git
)
goto :eof

:install_java
where winget >nul 2>&1
if !errorlevel! neq 0 (
    call :color_error
    echo [错误] 未检测到 winget, 请手动安装 JDK。
    call :color_normal
    goto :eof
)
echo 正在安装 JDK...
winget install EclipseAdoptium.Temurin.17.JDK -e --accept-source-agreements --accept-package-agreements
if !errorlevel! equ 0 (
    call :color_success
    echo [完成] JDK 安装完成。
    call :color_normal
) else (
    call :color_error
    echo [错误] JDK 安装失败。
    call :color_normal
)
call :refresh_path
goto :eof

:install_node
where winget >nul 2>&1
if !errorlevel! neq 0 (
    call :color_error
    echo [错误] 未检测到 winget, 请手动安装 Node.js。
    call :color_normal
    goto :eof
)
echo 正在安装 Node.js...
winget install OpenJS.NodeJS.LTS -e --accept-source-agreements --accept-package-agreements
if !errorlevel! equ 0 (
    call :color_success
    echo [完成] Node.js 安装完成。
    call :color_normal
) else (
    call :color_error
    echo [错误] Node.js 安装失败。
    call :color_normal
)
call :refresh_path
goto :eof

:install_git
where winget >nul 2>&1
if !errorlevel! neq 0 (
    call :color_error
    echo [错误] 未检测到 winget, 请手动安装 Git。
    call :color_normal
    goto :eof
)
echo 正在安装 Git...
winget install Git.Git -e --accept-source-agreements --accept-package-agreements
if !errorlevel! equ 0 (
    call :color_success
    echo [完成] Git 安装完成。
    call :color_normal
) else (
    call :color_error
    echo [错误] Git 安装失败。
    call :color_normal
)
call :refresh_path
goto :eof

:refresh_path
set "SYSTEM_PATH="
set "USER_PATH="
for /f "tokens=1,2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do if /i "%%a"=="Path" set "SYSTEM_PATH=%%c"
for /f "tokens=1,2*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do if /i "%%a"=="Path" set "USER_PATH=%%c"
if defined SYSTEM_PATH (
    if defined USER_PATH (
        set "PATH=!SYSTEM_PATH!;!USER_PATH!"
    ) else (
        set "PATH=!SYSTEM_PATH!"
    )
)
goto :eof

:get_lan_ip
set "LAN_IP="
set "FALLBACK_IP="
for /f "tokens=2 delims=:" %%a in ('ipconfig 2^>nul ^| findstr /R /C:"IPv4"') do (
    set "IP_VALUE=%%a"
    set "IP_VALUE=!IP_VALUE: =!"
    if not "!IP_VALUE!"=="" if not "!IP_VALUE!"=="127.0.0.1" (
        if "!FALLBACK_IP!"=="" set "FALLBACK_IP=!IP_VALUE!"
        echo !IP_VALUE! | findstr /R "^192\.168\." >nul 2>&1
        if !errorlevel! equ 0 if "!LAN_IP!"=="" set "LAN_IP=!IP_VALUE!"
    )
)
if "!LAN_IP!"=="" set "LAN_IP=!FALLBACK_IP!"
if "!LAN_IP!"=="" set "LAN_IP=localhost"
goto :eof


:color_normal
color 07 >nul 2>&1
goto :eof

:color_success
color 0A >nul 2>&1
goto :eof

:color_warning
color 0E >nul 2>&1
goto :eof

:color_error
color 0C >nul 2>&1
goto :eof

:color_title
color 0B >nul 2>&1
goto :eof

:restore_defaults
set "PROJECT_NAME=示例项目"
set "DEFAULT_PORT=8080"
set "SERVER_CMD=java"
set "SERVER_ARGS=-jar"
set "SERVER_EXTRA_ARGS="
set "JAR_FILE=app.jar"
set "SERVER_PORT_ARG=--server.port="
set "NEED_JAVA=1"
set "NEED_NODE=0"
set "NEED_GIT=0"
goto :eof
