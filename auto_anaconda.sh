#!/bin/bash

# 🔹 현재 작업 디렉토리 저장
ORIGINAL_DIR=$(pwd)
SKEL_DIR="/etc/skel"
ANACONDA_DIR="/opt/anaconda3"
SHARED_ENV="$ANACONDA_DIR/envs/shared_env"

# 🔹 Sudo 비밀번호를 한 번만 입력하도록 설정
echo "🔹 Requesting sudo access... Please enter your password."
sudo -v  # sudo 권한을 미리 요청

# 🔹 sudo 인증이 만료되지 않도록 유지 (백그라운드 실행)
while true; do sudo -v; sleep 300; done &

# 🔹 dpkg lock이 해제될 때까지 기다림 (최대 300초)
echo "🔹 Waiting for dpkg lock to be released..."
LOCK_WAIT_TIME=0
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    sleep 5
    LOCK_WAIT_TIME=$((LOCK_WAIT_TIME+5))
    if [ "$LOCK_WAIT_TIME" -ge 300 ]; then
        echo "⚠️  dpkg lock timeout exceeded (300s). Exiting."
        exit 1
    fi
done

echo "🔹 Installing Zsh and required packages..."
sudo apt update && sudo apt install -y zsh git wget unzip fonts-powerline curl

# 🔹 Zsh에서 실행되도록 강제 변경
if [ -z "$ZSH_VERSION" ]; then
    echo "🔹 Switching to Zsh for proper execution..."
    exec sudo -u "$USER" zsh "$0" "$@"
    exit
fi

echo "🔹 Changing default shell to Zsh..."
sudo chsh -s "$(which zsh)" "$USER"
touch ~/.zshrc

echo "🔹 Installing Oh-My-Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    yes | sudo -u "$USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "🔹 Installing Powerlevel10k theme..."
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    sudo -u "$USER" git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
fi

echo "🔹 Installing Zsh plugins..."
PLUGINS_DIR="$HOME/.oh-my-zsh/custom/plugins"
[ ! -d "$PLUGINS_DIR/zsh-autosuggestions" ] && sudo -u "$USER" git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGINS_DIR/zsh-autosuggestions"
[ ! -d "$PLUGINS_DIR/zsh-syntax-highlighting" ] && sudo -u "$USER" git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGINS_DIR/zsh-syntax-highlighting"

echo "🔹 Configuring .zshrc..."
[ ! -f "$HOME/.zshrc" ] && sudo -u "$USER" touch "$HOME/.zshrc"

# 기존 테마 설정이 있으면 변경, 없으면 추가
if grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
    sudo -u "$USER" sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc"
else
    echo 'ZSH_THEME="powerlevel10k/powerlevel10k"' | sudo -u "$USER" tee -a "$HOME/.zshrc" > /dev/null
fi

# 플러그인 설정이 있으면 변경, 없으면 추가
if grep -q '^plugins=' "$HOME/.zshrc"; then
    sudo -u "$USER" sed -i 's|^plugins=.*|plugins=(git zsh-autosuggestions zsh-syntax-highlighting)|' "$HOME/.zshrc"
else
    echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting)' | sudo -u "$USER" tee -a "$HOME/.zshrc" > /dev/null
fi

# Oh-My-Zsh 및 Powerlevel10k 설정 추가
if ! grep -q 'source $ZSH/oh-my-zsh.sh' "$HOME/.zshrc"; then
    echo 'source $ZSH/oh-my-zsh.sh' | sudo -u "$USER" tee -a "$HOME/.zshrc" > /dev/null
fi

if ! grep -q 'source ~/.p10k.zsh' "$HOME/.zshrc"; then
    echo 'source ~/.p10k.zsh' | sudo -u "$USER" tee -a "$HOME/.zshrc" > /dev/null
fi

if ! grep -q 'source /opt/anaconda3/bin/activate' "$HOME/.zshrc"; then
    echo 'source /opt/anaconda3/bin/activate $SHARED_ENV' | sudo -u "$USER" tee -a "$HOME/.zshrc" > /dev/null
fi

if [ -f "$ORIGINAL_DIR/.p10k.zsh" ]; then
    sudo -u "$USER" cp "$ORIGINAL_DIR/.p10k.zsh" "$HOME/.p10k.zsh"
fi

echo "🔹 Setting Zsh as the default shell for new users..."
sudo sed -i 's|SHELL=.*|SHELL=/bin/zsh|' /etc/default/useradd

echo "🔹 Copying current user’s settings to /etc/skel/"
sudo rm -rf "$SKEL_DIR/.oh-my-zsh" "$SKEL_DIR/.zshrc" "$SKEL_DIR/.p10k.zsh"
sudo cp -r "$HOME/.oh-my-zsh" "$SKEL_DIR/"
sudo cp "$HOME/.zshrc" "$SKEL_DIR/"
sudo cp "$HOME/.p10k.zsh" "$SKEL_DIR/"

echo "✅ Zsh setup complete!"

echo "🔹 Installing Anaconda..."
if [ ! -d "$ANACONDA_DIR" ]; then
    wget https://repo.anaconda.com/archive/Anaconda3-2023.09-0-Linux-aarch64.sh -O /tmp/anaconda.sh
    sudo bash /tmp/anaconda.sh -b -p $ANACONDA_DIR
    rm /tmp/anaconda.sh
fi

echo "🔹 Configuring shared Anaconda environment..."
if [ ! -d "$SHARED_ENV" ]; then
    sudo $ANACONDA_DIR/bin/conda create --prefix $SHARED_ENV python=3.9 -y
fi

echo "🔹 Configuring Conda to use shared environment by default..."
sudo tee /opt/anaconda3/.condarc <<EOF
channels:
  - defaults
envs_dirs:
  - $SHARED_ENV
default_python: 3.9
EOF

echo "✅ Anaconda + Zsh integration complete!"

zsh
