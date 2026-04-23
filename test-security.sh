#!/bin/bash
# Script de tests de sécurité pour valider le déploiement
# Exécute des attaques de test et vérifie que les détections fonctionnent

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
TARGET="http://localhost"
LOGS_DIR="/opt/secure-app"
FALCO_LOG="$LOGS_DIR/falco/falco.log"
SURICATA_LOG="$LOGS_DIR/suricata/eve.json"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Tests de Détection de Sécurité                           ║${NC}"
echo -e "${BLUE}║   Application 3-Tiers Sécurisée                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Vérification des prérequis
echo -e "${YELLOW}[PRÉ-TEST] Vérification des prérequis...${NC}"

if ! command -v curl &> /dev/null; then
    echo -e "${RED}✗ curl non trouvé${NC}"
    exit 1
fi

if ! curl -s "$TARGET/" > /dev/null; then
    echo -e "${RED}✗ Application inaccessible sur $TARGET${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Application accessible${NC}"

# Fonction pour exécuter un test
run_test() {
    local test_name=$1
    local test_command=$2
    local expected_pattern=$3
    local log_file=$4
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}[TEST] $test_name${NC}"
    echo -e "${YELLOW}Commande: $test_command${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Enregistrer le timestamp avant le test
    local before_size=0
    if [ -f "$log_file" ]; then
        before_size=$(wc -l < "$log_file")
    fi
    
    # Exécuter le test
    echo "Exécution du test..."
    eval "$test_command" 2>/dev/null || true
    
    # Attendre un peu pour les logs
    sleep 2
    
    # Vérifier les logs
    if [ -f "$log_file" ]; then
        local after_content=$(tail -20 "$log_file")
        
        if echo "$after_content" | grep -qi "$expected_pattern"; then
            echo -e "${GREEN}✓ DÉTECTION RÉUSSIE${NC}"
            echo "Pattern détecté: $expected_pattern"
            return 0
        else
            echo -e "${RED}✗ AUCUNE DÉTECTION${NC}"
            echo "Pattern attendu: $expected_pattern"
            echo "Contenu des logs:"
            echo "$after_content" | head -5
            return 1
        fi
    else
        echo -e "${RED}✗ Log file not found: $log_file${NC}"
        return 1
    fi
}

# ============================================================================
# TESTS
# ============================================================================

TEST_PASSED=0
TEST_FAILED=0

# Test 1: Injection SQL
echo -e "${BLUE}\n[SERIE 1] Détection d'Injections SQL${NC}"

test_sql_payloads=(
    "1' OR '1'='1"
    "1; DROP TABLE users--"
    "' UNION SELECT * FROM admin--"
    "1' AND SLEEP(5)--"
)

for payload in "${test_sql_payloads[@]}"; do
    if run_test \
        "SQL Injection: $payload" \
        "curl -s \"$TARGET/api/users?id=$(urlencode \"$payload\")\"" \
        "SQL|injection|alert" \
        "$SURICATA_LOG"; then
        ((TEST_PASSED++))
    else
        ((TEST_FAILED++))
    fi
done

# Test 2: Remote Code Execution
echo -e "${BLUE}\n[SERIE 2] Détection d'Injection de Commande (RCE)${NC}"

test_rce_payloads=(
    "; cat /etc/passwd"
    "| ls -la"
    "& whoami"
    "\$(id)"
    "\`whoami\`"
)

for payload in "${test_rce_payloads[@]}"; do
    if run_test \
        "RCE: $payload" \
        "curl -s \"$TARGET/api/execute?cmd=$(urlencode \"$payload\")\"" \
        "command|injection|RCE" \
        "$SURICATA_LOG"; then
        ((TEST_PASSED++))
    else
        ((TEST_FAILED++))
    fi
done

# Test 3: Path Traversal
echo -e "${BLUE}\n[SERIE 3] Détection de Path Traversal${NC}"

test_traversal_payloads=(
    "../../etc/passwd"
    "..%2f..%2fetc%2fpasswd"
    "....//....//etc/passwd"
    "../../../../../../../etc/shadow"
)

for payload in "${test_traversal_payloads[@]}"; do
    if run_test \
        "Path Traversal: $payload" \
        "curl -s \"$TARGET/api/file?path=$(urlencode \"$payload\")\"" \
        "traversal|path|\\.\\." \
        "$SURICATA_LOG"; then
        ((TEST_PASSED++))
    else
        ((TEST_FAILED++))
    fi
done

# Test 4: Cross-Site Scripting (XSS)
echo -e "${BLUE}\n[SERIE 4] Détection de XSS${NC}"

test_xss_payloads=(
    "<script>alert('XSS')</script>"
    "<img src=x onerror=alert('xss')>"
    "<svg/onload=alert('xss')>"
    "javascript:alert('xss')"
)

for payload in "${test_xss_payloads[@]}"; do
    if run_test \
        "XSS: $payload" \
        "curl -s \"$TARGET/api/comment?text=$(urlencode \"$payload\")\"" \
        "xss|script|javascript" \
        "$SURICATA_LOG"; then
        ((TEST_PASSED++))
    else
        ((TEST_FAILED++))
    fi
done

# Test 5: Détection d'outils de scanning
echo -e "${BLUE}\n[SERIE 5] Détection d'Outils de Scan${NC}"

if run_test \
    "Scanner: SQLmap User-Agent" \
    "curl -s -A 'sqlmap/1.0' $TARGET/api/" \
    "sqlmap|scanner|automated" \
    "$SURICATA_LOG"; then
    ((TEST_PASSED++))
else
    ((TEST_FAILED++))
fi

# Test 6: Shell Execution Detection (Falco)
echo -e "${BLUE}\n[SERIE 6] Détection d'Exécution de Shell (Falco)${NC}"

echo "Tentative d'accès shell au conteneur..."
if docker exec -it backend /bin/sh -c "echo test" 2>/dev/null; then
    sleep 2
    if [ -f "$FALCO_LOG" ] && grep -qi "shell" "$FALCO_LOG"; then
        echo -e "${GREEN}✓ Shell execution détecté par Falco${NC}"
        ((TEST_PASSED++))
    else
        echo -e "${YELLOW}⚠ Pas de détection Falco (peut être normal si le conteneur refuse)${NC}"
        ((TEST_FAILED++))
    fi
else
    echo -e "${YELLOW}⚠ Accès shell refusé (attendu) - Falco devrait avoir alerté${NC}"
fi

# ============================================================================
# RAPPORT FINAL
# ============================================================================

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   RAPPORT DE TEST                                          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Tests réussis:  ${GREEN}$TEST_PASSED${NC}"
echo -e "Tests échoués:  ${RED}$TEST_FAILED${NC}"
echo ""

if [ $TEST_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ TOUS LES TESTS SONT PASSÉS${NC}"
    echo "Votre infrastructure de sécurité fonctionne correctement!"
    exit 0
else
    echo -e "${YELLOW}⚠ CERTAINS TESTS ONT ÉCHOUÉ${NC}"
    echo "Vérifiez:"
    echo "1. Les services de sécurité sont-ils actifs?"
    echo "   docker-compose -f docker-compose.security.yml ps"
    echo "2. Les règles sont-elles chargées?"
    echo "   docker exec suricata suricatasc -c 'ruleset-show'"
    echo "3. Vérifiez les logs:"
    echo "   docker-compose -f docker-compose.security.yml logs -f falco"
    echo "   docker-compose -f docker-compose.security.yml logs -f suricata"
    exit 1
fi

# Fonction helper pour urlencoder
urlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""
    local pos c o

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * ) printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}
