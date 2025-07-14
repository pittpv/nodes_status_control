#!/bin/bash

# Цвета
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
MAGENTA=$'\033[0;35m'
CYAN=$'\033[0;36m'
NC=$'\033[0m' # No Color

# Проверка и загрузка языка
if [ ! -f ~/.script_language ]; then
    echo -e "${YELLOW}Select language / Выберите язык:${NC}"
    echo -e "1) English"
    echo -e "2) Русский"
    read -p "Your choice (1/2): " lang_choice

    if [ "$lang_choice" = "2" ]; then
        echo "ru" > ~/.script_language
    else
        echo "en" > ~/.script_language
    fi
fi

LANGUAGE=$(cat ~/.script_language)

# Функция перевода
t() {
    local en="$1"
    local ru="$2"

    if [ "$LANGUAGE" = "ru" ]; then
        echo "$ru"
    else
        echo "$en"
    fi
}

# Улучшенная функция для эффекта печатающегося текста
typewriter() {
    local text="$1"
    local delay="${2:-0.03}"

    local i=0
    while [ $i -lt ${#text} ]; do
        # Обнаружение ANSI escape-последовательности
        if [[ "${text:$i:1}" == $'\033' ]]; then
            local j=$i
            while [[ "${text:$j:1}" != "m" && $j -lt ${#text} ]]; do
                ((j++))
            done
            ((j++)) # включить 'm'
            printf "%s" "${text:$i:$((j - i))}"
            i=$j
        else
            printf "%s" "${text:$i:1}"
            sleep "$delay"
            ((i++))
        fi
    done
    echo
}

echo -e " "
echo -e " "

# Проверка первого запуска
if [ ! -f ~/.script_initialized ]; then
    # Вывод анимированных сообщений
    typewriter "${YELLOW}$(t "Hello!" "Привет!")${NC}" 0.05
    echo -e " "
    typewriter "${YELLOW}$(t "I will help you create a script that will allow you to ${GREEN}sleep${NC}${YELLOW} instead of sitting in the terminal." "Я помогу тебе создать скрипт, который даст тебе возможность ${GREEN}спать${NC}${YELLOW}, а не сидеть в терминале.")${NC}" 0.03
    typewriter "${YELLOW}$(t "This script can also register an ${BLUE}Aztec${NC}${YELLOW} validator." "Еще этот скрипт умеет регистрировать валидатора ${BLUE}Aztec.${NC}")${NC}" 0.03
    typewriter "${RED}$(t "But not like that unfortunate first script on GitHub..." "Но не как тот несчастный, первый скрипт в Гитхабе...")${NC}" 0.03
    typewriter "${YELLOW}$(t "I run at full ${RED}speed${NC}${YELLOW} if you set everything up!" "Я выполняюсь напрямую, на полный ${RED}газ${NC}, если ты все настроишь!")${NC}" 0.03
    echo -e " "
    typewriter "${BLUE}$(t "It's a shame that first script got all the glory of ${MAGENTA}Open Access..." "Правда обидно, что тому скрипту досталась вся слава ${MAGENTA}Открытого доступа...")${NC}" 0.05
    echo -e " "
    typewriter "${BLUE}$(t "My author asks to convey:" "Мой автор просил передать:")${NC}" 0.03
    typewriter "${GREEN}     1. $(t "Don't share me with anyone, be honest with the author!" "Никому меня не передавай, будь честным по отношению к автору!")${NC}" 0.03
    typewriter "${GREEN}     2. $(t "If you want to share the script, invite that person to the author's chat ${YELLOW}https://t.me/+DLsyG6ol3SFjM2Vk${NC}" "Хочешь с кем-то поделиться скриптом, пригласи того человека в чат автора ${YELLOW}https://t.me/+DLsyG6ol3SFjM2Vk${NC}")${NC}" 0.03
    typewriter "${GREEN}     3. $(t "The author didn't promise you anything but gave me away ${MAGENTA}for free." "Автор тебе ничего не обещал, но отдал меня ${MAGENTA}бесплатно.${NC}")${NC}" 0.03
    echo -e " "
    typewriter "${GREEN}$(t "Thanks to my author for this!" "За это моему автору спасибо!")${NC}" 0.05
    echo -e " "
    typewriter "${YELLOW}$(t "If you want to thank the author, here are the wallets:" "Если хочешь отблагодарить автора, то вот кошельки:")${NC}" 0.03
    typewriter "${BLUE}     EVM: ${MAGENTA}0x4FD5eC033BA33507E2dbFE57ca3ce0A6D70b48Bf${NC}" 0.01
    typewriter "${BLUE}     SOLANA: ${MAGENTA}C9TV7Q4N77LrKJx4njpdttxmgpJ9HGFmQAn7GyDebH4R${NC}" 0.01
    echo -e " "
    typewriter "${NC}$(t "Now, let's get started..." "Ну а теперь, давай приступим...")${NC}" 0.01

    touch ~/.script_initialized
    echo ""
fi

echo -e " "
echo -e " "

# Запрос параметров
read -rp "$(echo -e "${YELLOW}$(t "Enter RPC_URL (e.g. https://eth-sepolia.g.alchemy.com/v2/...): " "Введите RPC_URL (например https://eth-sepolia.g.alchemy.com/v2/...): ")${NC}")" RPC_URL
read -rp "$(echo -e "${YELLOW}$(t "Enter VALIDATOR_PRIVATE_KEY (private key without '0x'): " "Введите VALIDATOR_PRIVATE_KEY (приватный ключ без '0x'): ")${NC}")" VALIDATOR_PRIVATE_KEY
read -rp "$(echo -e "${YELLOW}$(t "Enter ATTESTER (wallet address): " "Введите ATTESTER (адрес кошелька): ")${NC}")" ATTESTER

# Получаем PROPOSER_EOA через API
echo -e "${CYAN}$(t "Getting PROPOSER_EOA from API..." "Получаю PROPOSER_EOA с API...")${NC}"
API_RESPONSE=$(curl -s "https://aztec-proposer-api.up.railway.app/proposer?eoa=$ATTESTER")

# Проверка корректности ответа
if [[ -z "$API_RESPONSE" ]] || [[ "$API_RESPONSE" != *"proposerAddress"* ]]; then
  echo -e "${RED}$(t "Error: Failed to get proposerAddress from API. Check connection or ATTESTER validity." "Ошибка: не удалось получить proposerAddress с API. Проверьте соединение или валидность ATTESTER.")${NC}"
  exit 1
fi

# Извлекаем proposerAddress из JSON
PROPOSER_EOA=$(echo "$API_RESPONSE" | grep -oP '"proposerAddress":"\K0x[0-9a-fA-F]{40}')

if [[ -z "$PROPOSER_EOA" ]]; then
  echo -e "${RED}$(t "Error: Failed to extract proposerAddress from API response." "Ошибка: не удалось извлечь proposerAddress из ответа API.")${NC}"
  exit 1
fi

echo -e "${GREEN}✓ $(t "Received PROPOSER_EOA: $PROPOSER_EOA" "Получен PROPOSER_EOA: $PROPOSER_EOA")${NC}"
read -rp "$(echo -e "${YELLOW}$(t "Enter TELEGRAM_BOT_TOKEN: " "Введите TELEGRAM_BOT_TOKEN: ")${NC}")" TELEGRAM_BOT_TOKEN
read -rp "$(echo -e "${YELLOW}$(t "Enter TELEGRAM_USER_ID: " "Введите TELEGRAM_USER_ID: ")${NC}")" TELEGRAM_USER_ID
read -rp "$(echo -e "${YELLOW}$(t "Enter number of parallel transactions (1-5): " "Введите количество параллельных транзакций (1-5): ")${NC}")" TX_COUNT

echo -e "${GREEN}✓ $(t "Data received" "Данные получены")${NC}"

# Настройки путей
SCRIPT_DIR="$HOME/aztec-validator-script"
SCRIPT_PATH="$SCRIPT_DIR/aztec_validator.sh"
LOG_DIR="$SCRIPT_DIR/log"
LOG_FILE="$LOG_DIR/aztec_validator.log"
ENV_PATH="$SCRIPT_DIR/.env"

# Параметры газа (EIP-1559)
SLEEP_SECONDS=2
STAKING_ASSET_HANDLER="0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2"
MAX_EXECUTION_TIME=20

echo -e "${YELLOW}--- $(t "Step 2: Gas settings" "Шаг 2: Настройка параметров газа") ---${NC}"
echo -e "${YELLOW}$(t "Select gas configuration method:" "Выберите способ настройки газа:")${NC}"
echo -e "1) $(t "Manual input" "Ручной ввод параметров")"
echo -e "2) $(t "Automatic calculation (based on current network +20% for priority)" "Автоматический расчет (на основе текущей сети +20% для приоритета)")"
read -rp "$(echo -e "${YELLOW}$(t "Enter option number (1 or 2): " "Введите номер варианта (1 или 2): ")${NC}")" GAS_MODE

if [ "$GAS_MODE" = "2" ]; then
    echo -e "${GREEN}✓ $(t "Using automatic gas calculation" "Используется автоматический расчет газа")${NC}"
    # Эти значения будут переопределены в скрипте на основе текущих данных сети
    BASE_GAS_PRICE="600000000000"
    PRIORITY_FEE="300000000000"
    GAS_LIMIT="300000"
else
    # Ручной ввод
    read -rp "$(echo -e "${YELLOW}$(t "Enter BASE_GAS_PRICE (e.g. 5000000000000 for 5000 Gwei): " "Введите BASE_GAS_PRICE (например 5000000000000 для 5000 Gwei): ")${NC}")" BASE_GAS_PRICE
    read -rp "$(echo -e "${YELLOW}$(t "Enter PRIORITY_FEE (e.g. 5000000000 for 5 Gwei): " "Введите PRIORITY_FEE (например 5000000000 для 5 Gwei): ")${NC}")" PRIORITY_FEE
    read -rp "$(echo -e "${YELLOW}$(t "Enter GAS_LIMIT (recommended 3500000): " "Введите GAS_LIMIT (рекомендуется 3500000): ")${NC}")" GAS_LIMIT
    echo -e "${GREEN}✓ $(t "Using manual gas settings" "Используются ручные настройки газа")${NC}"
fi

echo -e "${YELLOW}--- $(t "Step 3: Create directories" "Шаг 3: Создание директорий") ---${NC}"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

# Функция логирования
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Сохраняем конфигурацию
cat > "$ENV_PATH" <<EOF
RPC_URL=$RPC_URL
VALIDATOR_PRIVATE_KEY=$VALIDATOR_PRIVATE_KEY
ATTESTER=$ATTESTER
PROPOSER_EOA=$PROPOSER_EOA
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN
TELEGRAM_USER_ID=$TELEGRAM_USER_ID
LOG_FILE=$LOG_FILE
SLEEP_SECONDS=$SLEEP_SECONDS
STAKING_ASSET_HANDLER=$STAKING_ASSET_HANDLER
BASE_GAS_PRICE=$BASE_GAS_PRICE
PRIORITY_FEE=$PRIORITY_FEE
GAS_LIMIT=$GAS_LIMIT
MAX_EXECUTION_TIME=$MAX_EXECUTION_TIME
TX_COUNT=$TX_COUNT
GAS_MODE=$GAS_MODE
LANGUAGE=$LANGUAGE
EOF

echo -e "${GREEN}✓ $(t "Configuration saved to $ENV_PATH" "Конфигурация сохранена в $ENV_PATH")${NC}"

echo -e "${YELLOW}--- $(t "Step 4: Create validator script" "Шаг 4: Создание скрипта валидатора") ---${NC}"

cat > "$SCRIPT_PATH" <<'EOF'
#!/bin/bash
export PATH="$PATH:/root/.foundry/bin"

# Загрузка конфигурации
ENV_PATH="$(dirname "$0")/.env"
if [ -f "$ENV_PATH" ]; then
  set -o allexport
  source "$ENV_PATH"
  set +o allexport
else
  echo "$(t "Error: Configuration file not found" "Ошибка: Файл конфигурации не найден")"
  exit 1
fi

# Функция перевода
t() {
    local en="$1"
    local ru="$2"

    if [ "$LANGUAGE" = "ru" ]; then
        echo "$ru"
    else
        echo "$en"
    fi
}

# Проверка наличия cast
if ! command -v cast &> /dev/null; then
  echo "$(t "Error: cast utility not installed" "Ошибка: Утилита cast не установлена")"
  echo -e "$(t "Install with:" "Установите выполнив:")"
  echo -e "curl -L https://foundry.paradigm.xyz | bash"
  echo -e "source $HOME/.bash_profile"
  echo -e "foundryup"
  exit 1
fi

# Функции
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Улучшенная функция получения цен газа
get_current_gas_prices() {
  # Значения по умолчанию (600 Gwei base, 300 Gwei priority)
  local DEFAULT_BASE=600000000000
  local DEFAULT_PRIORITY=300000000000

  # Получаем base fee
  local CURRENT_BASE_FEE=$(cast base-fee --rpc-url $RPC_URL 2>/dev/null || echo "$DEFAULT_BASE")

  # Получаем priority fee (75-й перцентиль)
  local CURRENT_PRIORITY_FEE=$(cast rpc eth_maxPriorityFeePerGas --rpc-url $RPC_URL 2>/dev/null | \
    tr -d '"' | grep -E '^[0-9]+$' || echo "$DEFAULT_PRIORITY")

  # Добавляем 20% буст к priority fee
  local PRIORITY_BOOST=$(echo "$CURRENT_PRIORITY_FEE * 1.2 / 1" | bc)

  # Base price = base fee + priority fee с бустом
  local SUGGESTED_BASE_PRICE=$(echo "$CURRENT_BASE_FEE + $PRIORITY_BOOST" | bc)

  # Ограничения минимальных значений
  [ "$SUGGESTED_BASE_PRICE" -lt 600000000000 ] && SUGGESTED_BASE_PRICE=600000000000  # Не менее 600 Gwei
  [ "$PRIORITY_BOOST" -lt 300000000000 ] && PRIORITY_BOOST=300000000000               # Не менее 300 Gwei

  echo "$SUGGESTED_BASE_PRICE $PRIORITY_BOOST"
}

send_telegram() {
  local MESSAGE="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d chat_id="$TELEGRAM_USER_ID" \
    -d text="$MESSAGE" > /dev/null
}

check_tx_status() {
  local HASH="$1"
  local ATTEMPT=1
  local START_TIME=$(date +%s)
  local TIMEOUT=$((MAX_EXECUTION_TIME - ($(date +%s) - MAIN_START_TIME)))

  log "$(t "Checking tx status $HASH (max $TIMEOUT sec)" "Проверка статуса tx $HASH (макс $TIMEOUT сек)")"

  while true; do
    local CURRENT_TIME=$(date +%s)
    local ELAPSED=$((CURRENT_TIME - START_TIME))
    local REMAINING=$((TIMEOUT - ELAPSED))

    if [ $REMAINING -le 0 ]; then
      log "$(t "Check time exceeded" "Превышено время проверки")"
      return 1
    fi

    log "$(t "Attempt #$ATTEMPT ($REMAINING sec left)..." "Попытка #$ATTEMPT (осталось $REMAINING сек)...")"
    local STATUS=$(cast receipt --rpc-url "$RPC_URL" "$HASH" 2>&1)

    if [[ "$STATUS" == *"Transaction not found"* ]]; then
      log "$(t "Transaction not yet confirmed" "Транзакция еще не подтверждена")"
    elif [[ "$STATUS" == *"status"* ]]; then
      local TX_STATUS=$(echo "$STATUS" | grep -o '"status":"0x[01]"' | cut -d'"' -f4)
      if [[ "$TX_STATUS" == "0x1" ]]; then
        log "$(t "✓ Transaction successful" "✓ Транзакция успешна")"
        send_telegram "✅ AZTEC: $(t "SUCCESS" "УСПЕХ")%0A$(t "Attempt:" "Попытка:") #$MAIN_ATTEMPT%0A$(t "Time:" "Время:") $((CURRENT_TIME - MAIN_START_TIME)) $(t "sec" "сек")%0ATx: https://sepolia.etherscan.io/tx/$HASH"
        return 0
      else
        log "$(t "✗ Transaction failed" "✗ Транзакция failed")"
        send_telegram "❌ AZTEC: $(t "ERROR" "ОШИБКА")%0A$(t "Attempt:" "Попытка:") #$MAIN_ATTEMPT%0A$(t "Status:" "Статус:") $TX_STATUS%0ATx: https://sepolia.etherscan.io/tx/$HASH"
        return 1
      fi
    fi

    ((ATTEMPT++))
    sleep $SLEEP_SECONDS
  done

  log "$(t "Failed to confirm tx in allotted time" "Не удалось подтвердить tx за отведенное время")"
  return 1
}

main() {
  MAIN_START_TIME=$(date +%s)
  local MAIN_ATTEMPT=1
  local SUCCESS=false

  # Автоматический расчет газа
  if [ "$GAS_MODE" = "2" ]; then
    log "$(t "Calculating optimal gas prices..." "Расчет оптимальных цен газа...")"
    GAS_PRICES=$(get_current_gas_prices)
    BASE_GAS_PRICE=$(echo $GAS_PRICES | awk '{print $1}')
    PRIORITY_FEE=$(echo $GAS_PRICES | awk '{print $2}')

    # Проверка минимальных значений
    [ -z "$BASE_GAS_PRICE" ] && BASE_GAS_PRICE=100000000000
    [ -z "$PRIORITY_FEE" ] && PRIORITY_FEE=2000000000
  fi

  # Конвертация в Gwei для логов
  BASE_GAS_PRICE_GWEI=$(echo "scale=2; $BASE_GAS_PRICE / 1000000000" | bc)
  PRIORITY_FEE_GWEI=$(echo "scale=2; $PRIORITY_FEE / 1000000000" | bc)

  log "=== $(t "Execution parameters" "Параметры выполнения") ==="
  log "$(t "Base Gas:" "Base Gas:") $BASE_GAS_PRICE_GWEI Gwei"
  log "$(t "Priority:" "Priority:") $PRIORITY_FEE_GWEI Gwei"
  log "$(t "Gas Limit:" "Gas Limit:") $GAS_LIMIT"
  log "$(t "Max time:" "Макс. время:") $MAX_EXECUTION_TIME $(t "sec" "сек")"
  log "$(t "Parallel tx:" "Параллельные tx:") $TX_COUNT"
  log "$(t "Gas mode:" "Режим газа:") $([ "$GAS_MODE" = "2" ] && echo "$(t "AUTO" "АВТО")" || echo "$(t "MANUAL" "РУЧНОЙ")")"

  # Получаем текущий nonce
  VALIDATOR_ADDRESS=$(cast wallet address 0x$VALIDATOR_PRIVATE_KEY)
  CURRENT_NONCE=$(cast nonce --rpc-url $RPC_URL $VALIDATOR_ADDRESS)
  log "$(t "Initial nonce:" "Начальный nonce:") $CURRENT_NONCE"

  while true; do
    local CURRENT_TIME=$(date +%s)
    local ELAPSED=$((CURRENT_TIME - MAIN_START_TIME))
    local REMAINING=$((MAX_EXECUTION_TIME - ELAPSED))

    if [ $REMAINING -le 0 ]; then
      log "$(t "Execution time exceeded" "Превышено время выполнения")"
      send_telegram "⏱️ AZTEC: $(t "TIMEOUT" "ТАЙМ-АУТ")%0A$(t "Attempts:" "Попыток:") $((MAIN_ATTEMPT-1))"
      return 1
    fi

    log "$(t "Attempt #$MAIN_ATTEMPT ($ELAPSED sec passed, $REMAINING sec left)" "Попытка #$MAIN_ATTEMPT (прошло $ELAPSED сек, осталось $REMAINING сек)")"

    # Массивы для асинхронной обработки
    declare -a PIDS=()
    declare -A TX_HASHES=()

    # Асинхронная отправка транзакций
    for ((i=1; i<=$TX_COUNT; i++)); do
      (
        local TX_NONCE=$((CURRENT_NONCE + i - 1))
        log "$(t "Sending tx #$i (nonce $TX_NONCE)..." "Отправка tx #$i (nonce $TX_NONCE)...")"

        OUTPUT=$(cast send --rpc-url $RPC_URL \
          --private-key 0x$VALIDATOR_PRIVATE_KEY \
          --nonce $TX_NONCE \
          --gas-limit $GAS_LIMIT \
          --gas-price $BASE_GAS_PRICE \
          --priority-gas-price $PRIORITY_FEE \
          $STAKING_ASSET_HANDLER \
          'addValidator(address,address)' \
          $ATTESTER $PROPOSER_EOA 2>&1)

        TX_HASH=$(echo "$OUTPUT" | grep -oE 'transactionHash[[:space:]]+0x[a-fA-F0-9]{64}' | awk '{print $2}')
        [ -z "$TX_HASH" ] && TX_HASH=$(echo "$OUTPUT" | grep -oE '0x[a-fA-F0-9]{64}' | head -n 1)

        if [ -z "$TX_HASH" ]; then
          log "$(t "Error sending tx #$i" "Ошибка отправки tx #$i")"
          log "$(t "Output:" "Вывод:") $OUTPUT"
          send_telegram "❌ AZTEC: $(t "ERROR" "ОШИБКА") #$i%0A$(t "Attempt:" "Попытка:") #$MAIN_ATTEMPT%0A$(t "Nonce:" "Nonce:") $TX_NONCE"
        else
          log "$(t "Tx #$i sent:" "Tx #$i отправлена:") $TX_HASH"
          send_telegram "📤 AZTEC: $(t "SENDING" "ОТПРАВКА") #$i%0A$(t "Attempt:" "Попытка:") #$MAIN_ATTEMPT%0A$(t "Nonce:" "Nonce:") $TX_NONCE%0A$(t "Hash:" "Hash:") $TX_HASH"
          TX_HASHES["$i"]=$TX_HASH
        fi
      ) &
      PIDS+=($!)
    done

    # Ожидаем завершения всех процессов
    for PID in "${PIDS[@]}"; do
      wait $PID
    done

    # Проверяем статусы отправленных транзакций
    local TX_SUCCESS_COUNT=${#TX_HASHES[@]}
    if [ $TX_SUCCESS_COUNT -gt 0 ]; then
      for i in "${!TX_HASHES[@]}"; do
        if check_tx_status "${TX_HASHES[$i]}"; then
          SUCCESS=true
        fi
      done
    else
      log "$(t "All transactions in attempt #$MAIN_ATTEMPT failed" "Все транзакции в попытке #$MAIN_ATTEMPT завершились ошибкой")"
      send_telegram "⚠️ AZTEC: $(t "ALL TX ERRORS" "ВСЕ TX ОШИБКИ")%0A$(t "Attempt:" "Попытка:") #$MAIN_ATTEMPT"
    fi

    # Обновляем nonce для следующей попытки
    CURRENT_NONCE=$((CURRENT_NONCE + TX_COUNT))

    if $SUCCESS; then
      break
    fi

    ((MAIN_ATTEMPT++))
    sleep $SLEEP_SECONDS
  done

  $SUCCESS && return 0 || return 1
}

main
EOF

# Делаем скрипт исполняемым
chmod +x "$SCRIPT_PATH"
chmod +x "$LOG_FILE"

echo -e "${GREEN}✓ $(t "Script created: $SCRIPT_PATH" "Скрипт создан: $SCRIPT_PATH")${NC}"

echo -e "${YELLOW}--- $(t "Step 5: Cron setup" "Шаг 5: Настройка cron") ---${NC}"
CRON_JOB="48 23 * * * sleep 51 && $SCRIPT_PATH >> $LOG_FILE 2>&1"
(crontab -l 2>/dev/null | grep -v "$SCRIPT_PATH"; echo "$CRON_JOB") | crontab -
echo -e "${GREEN}✓ $(t "Cron job added:" "Cron задача добавлена:")${NC}"
echo -e "    $CRON_JOB"

echo -e "${YELLOW}--- $(t "Step 6: Dependency check" "Шаг 6: Проверка зависимостей") ---${NC}"
if ! command -v cast &> /dev/null; then
  echo -e "${RED}✗ $(t "Foundry not installed" "Foundry не установлен")${NC}"
  echo -e "$(t "Install with:" "Установите выполнив:")"
  echo -e "curl -L https://foundry.paradigm.xyz | bash"
  echo -e "source $HOME/.bash_profile"
  echo -e "foundryup"
else
  echo -e "${GREEN}✓ $(t "Foundry installed" "Foundry установлен")${NC}"
fi

if ! command -v bc &> /dev/null; then
  echo -e "${RED}✗ $(t "bc utility not installed" "Утилита bc не установлена")${NC}"
  echo -e "$(t "Install with:" "Установите выполнив:")"
  echo -e "sudo apt-get install bc  # $(t "For Ubuntu/Debian" "Для Ubuntu/Debian")"
else
  echo -e "${GREEN}✓ $(t "bc utility installed" "Утилита bc установлена")${NC}"
fi

echo -e "${YELLOW}--- $(t "Step 7: Test run" "Шаг 7: Тестовый запуск") ---${NC}"
echo -e "$(t "Starting in 15 seconds..." "Запуск через 15 секунд...")"
echo -e "$(t "To stop the script press ${RED}Ctrl + C${NC}" "Чтобы остановить скрипт нажмите ${RED}Ctrl + C${NC}")"
sleep 15
"$SCRIPT_PATH"
