#!/bin/bash

# 菜单函数
show_menu() {
	echo "当前脚本使用nibalee修改为动态gas后编译，不是官方原版程序，介意请直接退出！"
    echo "请选择一个选项:"
    echo "1) 安装程序"
    echo "2) 启动程序"
    echo "3) 查看日志"
    echo "4) 退出脚本"
}

# 安装程序函数
install_program() {
    download_url="https://github.com/kingdancing/heminetwork/releases/download/v1.0.0/heminetwork_v0.2.8_linux_amd64.tar.gz"

    echo "正在下载程序..."
    wget $download_url -O heminetwork_v0.2.8_linux_amd64.tar.gz
    wget_status=$?

    if [ $wget_status -ne 0 ]; then
        echo "下载失败，请检查链接是否正确。"
        echo "wget 返回状态码: $wget_status"
        return
    fi

    echo "正在解压文件..."
    tar --warning=no-unknown-keyword -xvf heminetwork_v0.2.8_linux_amd64.tar.gz

    echo "进入 bin 目录..."
    cd bin

    echo "正在生成密钥..."
    ./keygen -secp256k1 -json -net="testnet" > ~/popm-address.json

    echo "生成的地址信息如下:"
    cat ~/popm-address.json

    pubkey_hash=$(grep -o '"pubkey_hash": *"[^"]*"' ~/popm-address.json | sed 's/"pubkey_hash": *"//;s/"//')
    echo "请充值 tBTC 到以下地址后启动程序: $pubkey_hash"
    
    echo "返回菜单..."
}

# 启动程序函数
start_program() {
    if [ ! -f ~/popm-address.json ]; then
        echo "密钥文件不存在，请先安装程序。"
        return
    fi

    private_key=$(grep -o '"private_key": *"[^"]*"' ~/popm-address.json | sed 's/"private_key": *"//;s/"//')

    if [ -z "$private_key" ]; then
        echo "未能从密钥文件中获取到 private_key。"
        return
    fi

    if ! command -v screen &> /dev/null; then
        echo "screen 未安装，正在安装..."
        sudo apt-get update
        sudo apt-get install -y screen
    fi

    echo "启动程序..."
    screen -S hemi -dm bash -c "
    cd bin
    export POPM_BTC_PRIVKEY=$private_key
    export POPM_STATIC_FEE=55
    export POPM_BFG_URL=wss://testnet.rpc.hemi.network/v1/ws/public
    ./popmd
    "

    echo ">>>>>>>>程序已启动，返回菜单..."
}

# 查看日志函数
view_logs() {
    if screen -list | grep -q "hemi"; then
        echo "显示名为 hemi 的 screen 的日志:"
        screen -r hemi -X hardcopy ~/hemi.log
        tail -f ~/hemi.log
    else
        echo "没有找到名为 hemi 的 screen。"
    fi
}

# 主程序循环
while true; do
    show_menu
    read -p "请输入你的选择: " choice

    case $choice in
        1)
            install_program
            ;;
        2)
            start_program
            ;;
        3)
            view_logs
            ;;
        4)
            echo "退出脚本..."
            exit 0
            ;;
        *)
            echo "无效的选择，请重试。"
            ;;
    esac
done
