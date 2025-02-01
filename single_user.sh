ORIGINAL_DIR=$(pwd)

echo "🔹 Installing zsh and required packages..."
sudo apt update && sudo apt install -y zsh git wget unzip fonts-powerline

echo "🔹 Changing default shell to Zsh..."
chsh -s "$(which zsh)"
touch ~/.zshrc

echo "🔹 Installing Oh-My-Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

echo "🔹 Installing Powerlevel10k theme..."
if [ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
fi

echo "🔹 Installing Zsh plugins..."
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
fi
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
fi

echo "🔹 Applying Powerlevel10k settings..."
cp ".p10k.zsh" "$HOME/.p10k.zsh"

echo "🔹 Configuring .zshrc..."

if [ ! -f "$HOME/.zshrc" ]; then
    touch "$HOME/.zshrc"
fi

sed -i 's|^export ZSH=.*|export ZSH="$HOME/.oh-my-zsh"|' "$HOME/.zshrc"
sed -i 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$HOME/.zshrc"
sed -i 's|^plugins=(.*)|plugins=(git zsh-autosuggestions zsh-syntax-highlighting)|' "$HOME/.zshrc"

# ✅ 초기 설정 마법사가 실행되지 않도록 설정 추가
echo '[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh' >> "$HOME/.zshrc"
echo 'POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true' >> "$HOME/.zshrc"

cd "$ORIGINAL_DIR"
echo "🔹 Cleaning up..."
rm -rf "$ORIGINAL_DIR/auto_zsh"

zsh

source ~/.zshrc

echo "✅ Zsh setup complete!"
echo "🚀 Please restart your terminal and make sure to use a Nerd Font!"
