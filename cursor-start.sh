#!/bin/bash

# Define o diretório do Cursor
CURSOR_DIR="/usr/local/bin/cursor-pro"

# Muda para o diretório do Cursor
cd "$CURSOR_DIR" || {
    echo "❌ Erro: Não foi possível acessar o diretório $CURSOR_DIR"
    read -p "Pressione Enter para fechar..."
    exit 1
}

echo "🔍 Verificando ambiente do Cursor..."

# Encontra o arquivo AppImage do Cursor
CURSOR_APPIMAGE=$(find "$CURSOR_DIR" -maxdepth 1 -name "cursor*.AppImage" -type f | head -n 1)

# Verifica se os arquivos existem
if [ -z "$CURSOR_APPIMAGE" ]; then
    echo "❌ Nenhum arquivo cursor*.AppImage encontrado em $CURSOR_DIR!"
    echo "Por favor, execute o script de instalação novamente."
    read -p "Pressione Enter para fechar..."
    exit 1
fi

if [ ! -f "$CURSOR_DIR/cursor-vip_linux_amd64" ]; then
    echo "❌ Arquivo cursor-vip_linux_amd64 não encontrado em $CURSOR_DIR!"
    echo "Por favor, execute o script de instalação novamente."
    read -p "Pressione Enter para fechar..."
    exit 1
fi

# Mata qualquer processo existente do Cursor
echo "🧹 Limpando processos anteriores..."
pkill -f "cursor.*AppImage" 2>/dev/null
pkill -f "cursor-vip_linux_amd64" 2>/dev/null

# Limpa diretórios temporários antigos
echo "🧹 Limpando diretórios temporários..."
sudo rm -rf /tmp/.mount_cursor* 2>/dev/null

# Ajusta permissões
echo "🔧 Ajustando permissões..."
chmod +x "$CURSOR_APPIMAGE"
chmod +x "$CURSOR_DIR/cursor-vip_linux_amd64"

# Inicia o cursor-vip em um novo terminal
echo "🚀 Iniciando cursor-vip..."
gnome-terminal --title="Cursor VIP" -- bash -c "cd '$CURSOR_DIR' && ./cursor-vip_linux_amd64; exec bash"

# Aguarda 10 segundos
echo "⏳ Aguardando 10 segundos..."
sleep 10

# Configura variáveis de ambiente
echo "🔧 Configurando variáveis de ambiente..."
export ELECTRON_NO_SANDBOX=1
export DISABLE_SANDBOX=1

# Função para iniciar o Cursor
start_cursor() {
    nohup "$@" >/dev/null 2>&1 &
    sleep 5
    if pgrep -f "cursor.*AppImage" > /dev/null; then
        return 0
    fi
    return 1
}

# Inicia o Cursor sem sandbox
echo "🚀 Iniciando o Cursor (modo sem sandbox)..."
if start_cursor "$CURSOR_APPIMAGE" --no-sandbox; then
    echo "✅ Cursor iniciado com sucesso!"
    exit 0
fi

echo "❌ Falha ao iniciar o Cursor"
echo "Tentando método alternativo..."

# Tenta método alternativo
if start_cursor env ELECTRON_NO_SANDBOX=1 DISABLE_SANDBOX=1 "$CURSOR_APPIMAGE" --disable-gpu-sandbox --no-sandbox; then
    echo "✅ Cursor iniciado com sucesso (método alternativo)!"
    exit 0
fi

echo "❌ Falha ao iniciar o Cursor"
echo "Logs de erro:"
echo "----------------------------------------"
journalctl -n 50 | grep -i cursor
echo "----------------------------------------"
read -p "Pressione Enter para fechar..."
exit 1
