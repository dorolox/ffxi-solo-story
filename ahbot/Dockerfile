# Bot d'hôtel des ventes : ffxiahbot (https://github.com/AdamGagorik/ffxiahbot, MIT)
# Source clonée dans ../../ffxiahbot (contexte additionnel "src").
FROM python:3.13-slim
COPY --from=src . /src
# Versions exactes du uv.lock du projet (pip seul prend des typer/click trop récents -> TypeError click_type)
RUN pip install --no-cache-dir uv \
 && cd /src && uv export --frozen --no-dev --no-hashes --no-emit-project -o /tmp/requirements.txt \
 && pip install --no-cache-dir -r /tmp/requirements.txt \
 && pip install --no-cache-dir --no-deps /src \
 && useradd -u 1000 -m ahbot
COPY --chmod=0755 entrypoint.sh /entrypoint.sh
USER ahbot
WORKDIR /work
ENTRYPOINT ["/entrypoint.sh"]
CMD ["broker", "--restock-immediately"]
