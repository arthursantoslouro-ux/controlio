#!/data/data/com.termux/files/usr/bin/bash
# ╔══════════════════════════════════════════════╗
# ║         CONTROLIO - by Termux Hacker         ║
# ║   Controle remoto de celular via Termux API  ║
# ╚══════════════════════════════════════════════╝

RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[1;33m'
BLU='\033[0;34m'
CYN='\033[0;36m'
MAG='\033[0;35m'
BLD='\033[1m'
RST='\033[0m'

PORTA=9988

banner() {
  clear
  echo -e "${MAG}${BLD}"
  echo "  ██████╗ ██████╗ ███╗   ██╗████████╗██████╗  ██████╗ ██╗     ██╗ ██████╗ "
  echo " ██╔════╝██╔═══██╗████╗  ██║╚══██╔══╝██╔══██╗██╔═══██╗██║     ██║██╔═══██╗"
  echo " ██║     ██║   ██║██╔██╗ ██║   ██║   ██████╔╝██║   ██║██║     ██║██║   ██║"
  echo " ██║     ██║   ██║██║╚██╗██║   ██║   ██╔══██╗██║   ██║██║     ██║██║   ██║"
  echo " ╚██████╗╚██████╔╝██║ ╚████║   ██║   ██║  ██║╚██████╔╝███████╗██║╚██████╔╝"
  echo "  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝ ╚═════╝ "
  echo -e "${RST}"
  echo -e "${CYN}         🎮 Controle remoto de celular via Termux API 🎮${RST}"
  echo -e "${YEL}         ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
  echo ""
}

checar_deps() {
  local falta=0
  for cmd in nc termux-torch termux-vibrate termux-tts-speak termux-microphone-record termux-camera-photo termux-volume termux-battery-status termux-wifi-connectioninfo termux-toast termux-notification; do
    if ! command -v "$cmd" &>/dev/null; then
      echo -e "${RED}[✗] Faltando: $cmd${RST}"
      falta=1
    fi
  done
  if [ $falta -eq 1 ]; then
    echo -e "${YEL}[!] Instale com: pkg install termux-api && apt install termux-api${RST}"
    echo -e "${YEL}[!] E no celular: instale o app 'Termux:API' da F-Droid${RST}"
    exit 1
  fi
}

# ─── MODO CONTROLADO (VÍTIMA) ───────────────────────────────────────────────

modo_controlado() {
  banner
  echo -e "${GRN}${BLD}[MODO CONTROLADO]${RST}"
  echo -e "${YEL}Verificando dependências...${RST}"
  checar_deps

  # Descobre IP local
  IP_LOCAL=$(ip route get 1 2>/dev/null | awk '{print $7; exit}')
  [ -z "$IP_LOCAL" ] && IP_LOCAL=$(ifconfig 2>/dev/null | grep 'inet ' | grep -v 127 | awk '{print $2}' | head -1)
  [ -z "$IP_LOCAL" ] && IP_LOCAL="(não detectado - veja com: ip addr)"

  # Gera código de 6 dígitos
  CODIGO=$(shuf -i 100000-999999 -n 1)

  echo ""
  echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
  echo -e "${BLD}  📱 SEU IP:    ${CYN}$IP_LOCAL${RST}"
  echo -e "${BLD}  🔑 CÓDIGO:    ${YEL}$CODIGO${RST}"
  echo -e "${BLD}  🔌 PORTA:     ${MAG}$PORTA${RST}"
  echo -e "${GRN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
  echo -e "${RED}  Passe essas infos pro controlador!${RST}"
  echo ""
  echo -e "${BLU}[*] Aguardando conexão...${RST}"

  # Escuta conexões em loop
  while true; do
    # Recebe uma linha via nc
    LINHA=$(echo "" | nc -l -p "$PORTA" -q 1 2>/dev/null)

    [ -z "$LINHA" ] && continue

    CMD=$(echo "$LINHA" | cut -d'|' -f1)
    COD=$(echo "$LINHA" | cut -d'|' -f2)
    ARG=$(echo "$LINHA" | cut -d'|' -f3-)

    if [ "$COD" != "$CODIGO" ]; then
      echo -e "${RED}[!] Código inválido recebido: $COD${RST}"
      continue
    fi

    echo -e "${GRN}[+] Comando recebido: ${YEL}$CMD${RST} ${BLU}arg: $ARG${RST}"

    case "$CMD" in

      LANTERNA_ON)
        termux-torch on
        echo -e "${YEL}💡 Lanterna LIGADA${RST}"
        ;;

      LANTERNA_OFF)
        termux-torch off
        echo -e "${YEL}💡 Lanterna DESLIGADA${RST}"
        ;;

      VIBRAR)
        SEG=${ARG:-1}
        [ "$SEG" -gt 50 ] 2>/dev/null && SEG=50
        MS=$(( SEG * 1000 ))
        termux-vibrate -d "$MS" -f
        echo -e "${MAG}📳 Vibrou por ${SEG}s${RST}"
        ;;

      FALAR)
        TEXTO="$ARG"
        [ -z "$TEXTO" ] && TEXTO="Olá, estou sendo controlado"
        termux-tts-speak "$TEXTO"
        echo -e "${CYN}🗣️  TTS: '$TEXTO'${RST}"
        ;;

      GRAVAR_AUDIO)
        SEG=${ARG:-5}
        [ "$SEG" -gt 50 ] 2>/dev/null && SEG=50
        ARQUIVO="$HOME/controlio_audio_$(date +%s).mp3"
        termux-microphone-record -l "$SEG" -f "$ARQUIVO" -e mp3
        sleep $(( SEG + 1 ))
        echo -e "${RED}🎙️  Áudio gravado: $ARQUIVO${RST}"
        ;;

      FOTO)
        ARQUIVO="$HOME/controlio_foto_$(date +%s).jpg"
        CAM=${ARG:-0}
        termux-camera-photo -c "$CAM" "$ARQUIVO"
        echo -e "${BLU}📸 Foto tirada: $ARQUIVO${RST}"
        ;;

      VOLUME)
        VOL=${ARG:-50}
        termux-volume music "$VOL"
        echo -e "${YEL}🔊 Volume música: $VOL${RST}"
        ;;

      BATERIA)
        INFO=$(termux-battery-status)
        echo -e "${GRN}🔋 Bateria: $INFO${RST}"
        ;;

      WIFI)
        INFO=$(termux-wifi-connectioninfo)
        echo -e "${CYN}📶 WiFi: $INFO${RST}"
        ;;

      TOAST)
        MSG="$ARG"
        [ -z "$MSG" ] && MSG="Você foi trollado! 😈"
        termux-toast -s "$MSG"
        echo -e "${YEL}💬 Toast: '$MSG'${RST}"
        ;;

      NOTIFICACAO)
        TITULO=$(echo "$ARG" | cut -d';' -f1)
        CORPO=$(echo "$ARG" | cut -d';' -f2)
        [ -z "$TITULO" ] && TITULO="Controlio"
        [ -z "$CORPO" ] && CORPO="Você foi hackeado! 😈"
        termux-notification --title "$TITULO" --content "$CORPO" --id 6666
        echo -e "${MAG}🔔 Notificação enviada${RST}"
        ;;

      LANTERNA_PISCA)
        VEZES=${ARG:-5}
        [ "$VEZES" -gt 20 ] && VEZES=20
        for i in $(seq 1 "$VEZES"); do
          termux-torch on; sleep 0.3
          termux-torch off; sleep 0.3
        done
        echo -e "${YEL}💡 Lanterna piscou $VEZES vezes${RST}"
        ;;

      SAIR)
        echo -e "${RED}[!] Conexão encerrada pelo controlador.${RST}"
        termux-tts-speak "Conexão encerrada"
        break
        ;;

      *)
        echo -e "${RED}[?] Comando desconhecido: $CMD${RST}"
        ;;
    esac
  done
}

# ─── MODO CONTROLADOR (TROLL) ────────────────────────────────────────────────

enviar_cmd() {
  local cmd="$1"
  local arg="$2"
  echo "${cmd}|${CODIGO_REMOTO}|${arg}" | nc -w 3 "$IP_REMOTO" "$PORTA" 2>/dev/null
  if [ $? -eq 0 ]; then
    echo -e "${GRN}[✓] Enviado!${RST}"
  else
    echo -e "${RED}[✗] Falha ao enviar. Verifique IP/código/porta.${RST}"
  fi
}

modo_controlador() {
  banner
  echo -e "${RED}${BLD}[MODO CONTROLADOR - MODO TROLL 😈]${RST}"
  echo ""
  echo -ne "${YEL}  IP do celular alvo: ${RST}"
  read IP_REMOTO
  echo -ne "${YEL}  Código (6 dígitos): ${RST}"
  read CODIGO_REMOTO

  echo ""
  echo -e "${GRN}[*] Conectando em ${CYN}${IP_REMOTO}:${PORTA}${RST}${GRN}...${RST}"
  sleep 1

  while true; do
    echo ""
    echo -e "${MAG}━━━━━━━━━━━ MENU DE AÇÕES ━━━━━━━━━━━━${RST}"
    echo -e " ${YEL}1)${RST}  💡 Ligar lanterna"
    echo -e " ${YEL}2)${RST}  💡 Desligar lanterna"
    echo -e " ${YEL}3)${RST}  💡 Piscar lanterna"
    echo -e " ${YEL}4)${RST}  📳 Vibrar (escolher segundos)"
    echo -e " ${YEL}5)${RST}  🗣️  Falar algo (TTS) - você escolhe o texto!"
    echo -e " ${YEL}6)${RST}  🎙️  Gravar áudio"
    echo -e " ${YEL}7)${RST}  📸 Tirar foto (câmera traseira)"
    echo -e " ${YEL}8)${RST}  📸 Tirar foto (câmera frontal)"
    echo -e " ${YEL}9)${RST}  🔊 Alterar volume"
    echo -e " ${YEL}10)${RST} 🔋 Checar bateria"
    echo -e " ${YEL}11)${RST} 📶 Checar WiFi"
    echo -e " ${YEL}12)${RST} 💬 Enviar Toast na tela"
    echo -e " ${YEL}13)${RST} 🔔 Enviar notificação"
    echo -e " ${YEL}14)${RST} 💀 Combo do Caos (tudo junto!)"
    echo -e " ${YEL}0)${RST}  ❌ Encerrar conexão"
    echo -e "${MAG}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RST}"
    echo -ne "${BLD}  👉 Escolha: ${RST}"
    read OPCAO

    case "$OPCAO" in
      1)
        enviar_cmd "LANTERNA_ON" ""
        ;;
      2)
        enviar_cmd "LANTERNA_OFF" ""
        ;;
      3)
        echo -ne "${YEL}  Quantas vezes piscar? (máx 20): ${RST}"
        read VEZES
        enviar_cmd "LANTERNA_PISCA" "$VEZES"
        ;;
      4)
        echo -ne "${YEL}  Quantos segundos vibrar? (máx 50): ${RST}"
        read SEG
        [ "$SEG" -gt 50 ] 2>/dev/null && SEG=50
        enviar_cmd "VIBRAR" "$SEG"
        ;;
      5)
        echo -ne "${YEL}  O que o celular vai FALAR? 🗣️ : ${RST}"
        read TEXTO
        enviar_cmd "FALAR" "$TEXTO"
        ;;
      6)
        echo -ne "${YEL}  Gravar por quantos segundos? (máx 50): ${RST}"
        read SEG
        enviar_cmd "GRAVAR_AUDIO" "$SEG"
        echo -e "${BLU}[i] O arquivo ficará salvo no celular alvo${RST}"
        ;;
      7)
        enviar_cmd "FOTO" "0"
        echo -e "${BLU}[i] Foto salva no celular alvo${RST}"
        ;;
      8)
        enviar_cmd "FOTO" "1"
        echo -e "${BLU}[i] Selfie salva no celular alvo${RST}"
        ;;
      9)
        echo -ne "${YEL}  Volume de 0 a 100: ${RST}"
        read VOL
        enviar_cmd "VOLUME" "$VOL"
        ;;
      10)
        enviar_cmd "BATERIA" ""
        ;;
      11)
        enviar_cmd "WIFI" ""
        ;;
      12)
        echo -ne "${YEL}  Mensagem pra aparecer na tela: ${RST}"
        read MSG
        enviar_cmd "TOAST" "$MSG"
        ;;
      13)
        echo -ne "${YEL}  Título da notificação: ${RST}"
        read TITULO
        echo -ne "${YEL}  Corpo da notificação: ${RST}"
        read CORPO
        enviar_cmd "NOTIFICACAO" "${TITULO};${CORPO}"
        ;;
      14)
        echo -e "${RED}${BLD}💀 ATIVANDO COMBO DO CAOS... 💀${RST}"
        echo -ne "${YEL}  O que o TTS vai gritar? : ${RST}"
        read GRITO
        enviar_cmd "VOLUME" "100"
        sleep 1
        enviar_cmd "VIBRAR" "10"
        sleep 1
        enviar_cmd "LANTERNA_PISCA" "10"
        sleep 1
        enviar_cmd "TOAST" "😈 VOCÊ FOI TROLLADO! 😈"
        sleep 1
        enviar_cmd "NOTIFICACAO" "CONTROLIO;😈 Seu celular foi hackeado! 😈"
        sleep 1
        enviar_cmd "FALAR" "$GRITO"
        echo -e "${RED}💀 COMBO DO CAOS ENVIADO! 💀${RST}"
        ;;
      0)
        enviar_cmd "SAIR" ""
        echo -e "${RED}[!] Encerrando...${RST}"
        break
        ;;
      *)
        echo -e "${RED}[!] Opção inválida${RST}"
        ;;
    esac

    sleep 0.5
  done
}

# ─── INÍCIO ──────────────────────────────────────────────────────────────────

banner
echo -e "${BLD}  Você vai ser o:${RST}"
echo ""
echo -e "  ${GRN}${BLD}1)${RST} 🎮  ${GRN}CONTROLADOR${RST} ${YEL}(o troll - você controla o outro)${RST}"
echo -e "  ${RED}${BLD}2)${RST} 📱  ${RED}CONTROLADO${RST}  ${YEL}(a vítima - recebe os comandos)${RST}"
echo ""
echo -ne "${BLD}  👉 Escolha [1/2]: ${RST}"
read MODO

case "$MODO" in
  1) modo_controlador ;;
  2) modo_controlado ;;
  *)
    echo -e "${RED}Opção inválida. Saindo.${RST}"
    exit 1
    ;;
esac
