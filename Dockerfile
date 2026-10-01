ARG PYTHON_VERSION=3.14

FROM oven/bun:1 AS dashboard-builder

WORKDIR /code/dashboard
COPY dashboard/package.json dashboard/bun.lock ./
RUN bun install --frozen-lockfile
COPY dashboard/ ./
COPY build_dashboard.sh /code/build_dashboard.sh
RUN sh /code/build_dashboard.sh && test -s /code/dashboard/build/index.html

FROM ghcr.io/astral-sh/uv:python$PYTHON_VERSION-bookworm-slim AS builder
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    python3-dev \
    libc6-dev \
    && rm -rf /var/lib/apt/lists/*

ENV UV_PYTHON_DOWNLOADS=0

WORKDIR /build
COPY uv.lock pyproject.toml /build/
RUN uv sync --frozen --no-install-project --no-dev

COPY . /build
RUN uv sync --frozen --no-dev


FROM python:$PYTHON_VERSION-slim-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    unzip \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/code/.venv/bin:$PATH"

COPY --from=builder /build /code
COPY --from=dashboard-builder /code/dashboard/build /code/dashboard/build
WORKDIR /code

COPY cli_wrapper.sh /usr/bin/pasarguard-cli
RUN chmod +x /usr/bin/pasarguard-cli

COPY tui_wrapper.sh /usr/bin/pasarguard-tui
RUN chmod +x /usr/bin/pasarguard-tui

COPY healthcheck.sh /code/healthcheck.sh
RUN chmod +x /code/healthcheck.sh

RUN chmod +x /code/start.sh

ENTRYPOINT ["/code/start.sh"]
