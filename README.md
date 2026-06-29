# Humor do Ecossistema RS

Painel público que monitora manchetes de portais gaúchos sobre gestão pública, classifica sentimento com DeepSeek e exibe Top 3, cards por keyword e gráfico de 7 dias.

## Stack

- Ruby 4 + Rails 8.1
- PostgreSQL
- Redis + Sidekiq + sidekiq-cron
- Tailwind CSS + Chartkick
- DeepSeek API (`ruby-openai`)

## Setup local

```bash
mise install
cp .env.example .env
# configure DEEPSEEK_API_KEY no .env

createdb analisehumornoticias_development
createdb analisehumornoticias_test
bundle install
bin/rails db:prepare
bin/rails db:seed
```

Redis (necessário para Sidekiq):

```bash
sudo apt install redis-server redis-tools
redis-cli ping
```

## Desenvolvimento

```bash
bin/dev
```

Abra `http://localhost:3000`.

Rodar pipeline manualmente:

```bash
bin/rails runner "NewsPipelineJob.perform_now('manha')"
```

## Testes

```bash
bundle exec rspec
```

## Deploy (Render)

Dois processos:

- `web`: `bundle exec puma -C config/puma.rb`
- `worker`: `bundle exec sidekiq -C config/sidekiq.yml`

Variáveis de ambiente:

- `DATABASE_URL`
- `REDIS_URL`
- `DEEPSEEK_API_KEY`
- `DEEPSEEK_MODEL` (default: `deepseek-chat`)
- `RAILS_MASTER_KEY`

Agendamento automático via `config/schedule.yml`:

- 07:00 BRT (`manha`)
- 18:00 BRT (`tarde`)

## Fontes monitoradas

G1 RS, Zero Hora, Correio do Povo, Gaúcha ZH, ANP, Sul21, Agência Brasil (filtro RS).

## Licença

Projeto pessoal — dados abertos.
