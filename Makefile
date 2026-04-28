# Caminhos do MySQL
MYSQL_DIR=/usr/local/mysql
MYSQLD=$(MYSQL_DIR)/bin/mysqld
MYSQL_SAFE=$(MYSQL_DIR)/bin/mysqld_safe
MYSQL_CLI=$(MYSQL_DIR)/bin/mysql

.PHONY: start stop status probes shell help

help:
	@echo "Comandos disponíveis:"
	@echo "  make start   - Inicia o servidor MySQL em background"
	@echo "  make probes  - Lista todas as probes USDT (DTrace) disponíveis"
	@echo "  make shell   - Abre o terminal interativo do MySQL (pede senha)"
	@echo "  make status  - Verifica se o processo mysqld está rodando"
	@echo "  make stop    - Encerra o servidor MySQL"

# 1. Inicia o servidor MySQL
start:
	@echo "Iniciando MySQL..."
	sudo $(MYSQL_SAFE) --user=mysql &

# 2. Lista as probes USDT/SystemTap
probes:
	@echo "Listando Probes USDT..."
	sudo stap -l 'process("$(MYSQLD)").mark("*")'

# 3. Entra no console do MySQL
shell:
	$(MYSQL_CLI) -u root -p

# 4. Verifica se está rodando
status:
	ps aux | grep mysqld | grep -v grep

# 5. Para o servidor
stop:
	@echo "Encerrando MySQL..."
	sudo $(MYSQL_DIR)/bin/mysqladmin -u root -p shutdown

monitor:
	@echo "Monitorando queries em tempo real (pressione Ctrl+C para parar)..."
	sudo stap -e 'probe process("$(MYSQLD)").mark("query__start") { printf("SQL: %s\n", user_string($$arg1)) }'

# Comandos BCC-Tools
# Nota: Usamos $(shell pgrep -n mysqld) para capturar o processo atual

# 1. Monitora todas as queries em tempo real (estilo log)
query-live:
	@echo "Iniciando monitoramento de queries (BCC)..."
	sudo /usr/share/doc/bpfcc-tools/examples/tracing/mysqld_query.py $(shell pgrep -n mysqld)

# 2. Mostra apenas queries lentas (limite de 10ms por padrão)
# Use 'make slower MS=50' para mudar o limite
MS ?= 10
slower:
	@echo "Monitorando queries mais lentas que $(MS)ms..."
	sudo dbslower-bpfcc mysql -p $(shell pgrep -n mysqld) -m $(MS)

# 3. Mostra estatísticas e histograma de performance
stats:
	@echo "Coletando estatísticas de latência (Ctrl+C para ver o gráfico)..."
	sudo dbstat-bpfcc mysql -p $(shell pgrep -n mysqld)

