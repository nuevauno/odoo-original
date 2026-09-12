# Odoo 19 Community construido desde el repositorio oficial (github.com/odoo/odoo, rama 19.0).
# Referencia de comparación para NUEVAUNO: base sola, sin apps, sin datos de demo.
FROM python:3.12-slim-bookworm
ARG ODOO_BRANCH=19.0
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    git build-essential ca-certificates curl \
    libpq-dev libldap2-dev libsasl2-dev libssl-dev \
    libxml2-dev libxslt1-dev libjpeg-dev zlib1g-dev libffi-dev \
    fonts-dejavu-core fonts-liberation node-less npm \
 && rm -rf /var/lib/apt/lists/*
# Fijado al MISMO commit que usa el port (submódulo upstream/motor-19 de motor-cloudflare): la
# referencia y el port se comparan siempre al mismo commit; cuando el pin suba, sube este ARG.
ARG ODOO_COMMIT=4291b65978287b737a2e094d3122c20ed8564852
RUN git init -q /opt/odoo \
 && git -C /opt/odoo remote add origin https://github.com/odoo/odoo.git \
 && git -C /opt/odoo fetch --depth 1 origin ${ODOO_COMMIT} \
 && git -C /opt/odoo checkout -q FETCH_HEAD \
 && git -C /opt/odoo rev-parse HEAD > /opt/odoo/COMMIT \
 && echo "odoo/odoo@$(cat /opt/odoo/COMMIT) (rama ${ODOO_BRANCH}, commit fijado)"
RUN pip install --no-cache-dir -r /opt/odoo/requirements.txt psycopg2-binary \
 && npm install -g rtlcss
RUN useradd -m -d /var/lib/odoo -U -r -s /bin/false odoo && mkdir -p /var/lib/odoo && chown -R odoo:odoo /var/lib/odoo /opt/odoo
USER odoo
EXPOSE 8069 8072
# Primera arranque: crea la base "odoo" e instala SOLO el módulo base, sin demo. Reinicios posteriores: no-op.
CMD ["sh","-c","echo \"Odoo oficial: odoo/odoo@$(cat /opt/odoo/COMMIT)\"; exec python3 /opt/odoo/odoo-bin --db_host=${DB_HOST:-db} --db_port=5432 --db_user=${DB_USER:-odoo} --db_password=${DB_PASSWORD:-odoo} --data-dir=/var/lib/odoo --proxy-mode --db-filter=^odoo$ -d odoo -i base --without-demo=all --load-language=es_CL"]
